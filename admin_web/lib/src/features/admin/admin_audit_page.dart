import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/console_shell.dart';
import '../../backend/console_backend.dart';
import '../../theme/console_theme.dart';
import '../../widgets/console_formats.dart';
import '../../widgets/console_widgets.dart';

/// Everything done in the console, in order: roster changes by an admin and
/// queue decisions by a moderator, in one list.
///
/// An audit log is only worth having if it cannot be edited from the screen
/// that shows it, so there is nothing here but reading and filtering. Entries
/// are written by the services as a side effect of the change itself.
class AdminAuditPage extends StatefulWidget {
  const AdminAuditPage({super.key});

  @override
  State<AdminAuditPage> createState() => _AdminAuditPageState();
}

/// Which accounts' activity the list is showing.
enum _ActorFilter {
  all('All'),
  moderators('Moderators'),
  admin('Admin');

  const _ActorFilter(this.label);

  final String label;

  bool matches(AuditEntry entry) => switch (this) {
    _ActorFilter.all => true,
    _ActorFilter.admin => entry.isAdminActivity,
    _ActorFilter.moderators => !entry.isAdminActivity,
  };
}

class _AdminAuditPageState extends State<AdminAuditPage> {
  _ActorFilter _filter = _ActorFilter.all;

  /// The log is subscribed to here rather than through a `StreamBuilder` in
  /// [build], and that is deliberate.
  ///
  /// `watchAuditLog()` hands back a single-subscription stream, and a
  /// `StreamBuilder` in this page's build would be created holding one
  /// particular stream. When the window crosses a breakpoint, [ConsoleShell]
  /// swaps between two different arrangements, so the page body is torn out of
  /// one element tree and re-inflated into the other — while this page itself,
  /// sitting above the shell, is never rebuilt and so never makes a fresh
  /// stream. The re-inflated builder then listens to the stream the outgoing
  /// one is still holding, because deactivated elements are not disposed of
  /// until the end of the frame, and the second listen throws
  /// "Stream has already been listened to" — the red box over the page.
  ///
  /// This state outlives every one of those rearrangements, so subscribing
  /// here means exactly one listen for the life of the page, no matter how the
  /// window is resized. It also stops the log being re-subscribed every time a
  /// filter chip is tapped.
  StreamSubscription<List<AuditEntry>>? _subscription;

  List<AuditEntry> _entries = const <AuditEntry>[];

  @override
  void initState() {
    super.initState();
    _subscription = ConsoleBackend.instance.moderators.watchAuditLog().listen((entries) {
      if (!mounted) return;
      setState(() => _entries = entries);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = _entries;
    final entries = all.where(_filter.matches).toList(growable: false);

    return ConsoleShell(
      // Everything below reads the window through `context.layout`, which
      // depends on the shell's layout scope, so the padding and spacing
      // recalculate on their own whenever the window changes.
      child: Builder(
        builder: (context) {
          return ListView(
            padding: consolePagePadding(context),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final filter in _ActorFilter.values)
                    ConsoleFilterChip(
                      label: filter.label,
                      selected: _filter == filter,
                      onTap: () => setState(() => _filter = filter),
                    ),
                ],
              ),
              SizedBox(height: context.layout.sectionSpacing),
              ConsoleCard(
                title: entries.length == 1 ? '1 entry' : '${entries.length} entries',
                subtitle: 'Newest first',
                padding: entries.isEmpty
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(vertical: 6),
                child: entries.isEmpty
                    ? ConsoleEmptyState(
                        icon: Icons.history,
                        title: all.isEmpty ? 'Nothing logged yet' : 'Nothing matches',
                        message: all.isEmpty
                            ? 'Roster changes and queue decisions are written here, '
                                  'with who did it, from where, and why.'
                            : 'No activity from those accounts. Try a different filter.',
                      )
                    : Column(
                        children: [for (final entry in entries) _AuditRow(entry: entry)],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = colorForAuditAction(entry.action);

    return InkWell(
      onTap: () => showAuditEntryDetails(context, entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconForAuditAction(entry.action), size: 15, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.moderatorName,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall,
                        ),
                      ),
                      ConsoleBadge(label: entry.action.label, color: color),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.role} · by ${entry.actorName} · '
                    '${formatConsoleDateTime(entry.occurredAt)}',
                    style: text.bodySmall,
                  ),
                  if (entry.reason != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      entry.reason!,
                      style: text.bodySmall?.copyWith(
                        color: ConsoleColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Activity Detail view for one audit entry.
///
/// Everything the log holds about an action, including the address it was
/// performed from — which the list has no room for and which is the point of
/// opening an entry in the first place.
Future<void> showAuditEntryDetails(BuildContext context, AuditEntry entry) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final color = colorForAuditAction(entry.action);
      final actorRole = UserRole.fromWire(entry.actorRole);

      return AlertDialog(
        insetPadding: consoleDialogInsets(ctx),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconForAuditAction(entry.action), size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(entry.moderatorName)),
            ConsoleBadge(label: entry.action.label, color: color),
          ],
        ),
        content: ConsoleDialogBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailField(label: 'Action', value: entry.action.label),
              _DetailField(label: 'Subject', value: entry.moderatorName),
              _DetailField(label: 'Subject role', value: entry.role),
              const Divider(height: 24),
              _DetailField(label: 'Performed by', value: entry.actorName),
              _DetailField(label: 'Account role', value: actorRole.label),
              _DetailField(
                label: 'IP address',
                // Never invented: an entry written before addresses were
                // recorded says so rather than showing a plausible-looking
                // number nobody actually connected from.
                value: entry.ipAddress ?? 'Not recorded',
                muted: entry.ipAddress == null,
              ),
              _DetailField(label: 'When', value: formatConsoleDateTime(entry.occurredAt)),
              if (entry.reason != null) ...[
                const Divider(height: 24),
                _DetailField(label: 'Reason', value: entry.reason!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      );
    },
  );
}

/// One labelled line in the detail view.
class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value, this.muted = false});

  final String label;
  final String value;

  /// Dims the value where there is nothing recorded to show.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 118, child: Text(label, style: text.bodySmall)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: text.bodyMedium?.copyWith(
                fontWeight: muted ? FontWeight.w400 : FontWeight.w600,
                color: muted ? ConsoleColors.textMuted : ConsoleColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
