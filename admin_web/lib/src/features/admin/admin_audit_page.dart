import 'package:flutter/material.dart';

import '../../app/console_shell.dart';
import '../../backend/console_backend.dart';
import '../../theme/console_theme.dart';
import '../../widgets/console_formats.dart';
import '../../widgets/console_widgets.dart';

/// Every change to the moderator roster, in order.
///
/// An audit log is only worth having if it cannot be edited from the screen
/// that shows it, so there is nothing here but reading and filtering. Entries
/// are written by the directory service as a side effect of the change itself.
class AdminAuditPage extends StatefulWidget {
  const AdminAuditPage({super.key});

  @override
  State<AdminAuditPage> createState() => _AdminAuditPageState();
}

class _AdminAuditPageState extends State<AdminAuditPage> {
  AuditAction? _filter;

  @override
  Widget build(BuildContext context) {
    return ConsoleShell(
      child: StreamBuilder<List<AuditEntry>>(
        stream: ConsoleBackend.instance.moderators.watchAuditLog(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <AuditEntry>[];
          final entries = _filter == null
              ? all
              : all.where((e) => e.action == _filter).toList(growable: false);

          return ListView(
            padding: consolePagePadding(context),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ConsoleFilterChip(
                    label: 'All',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  ConsoleFilterChip(
                    label: 'Added',
                    selected: _filter == AuditAction.added,
                    onTap: () => setState(() => _filter = AuditAction.added),
                  ),
                  ConsoleFilterChip(
                    label: 'Removed',
                    selected: _filter == AuditAction.removed,
                    onTap: () => setState(() => _filter = AuditAction.removed),
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
                            ? 'Adding or removing a moderator writes an entry here, '
                                'with who did it and why.'
                            : 'No entries of that kind. Try a different filter.',
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

    return Padding(
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
    );
  }
}
