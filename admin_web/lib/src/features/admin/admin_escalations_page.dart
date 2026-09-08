import 'package:flutter/material.dart';

import '../../app/console_shell.dart';
import '../../backend/console_backend.dart';
import '../../theme/console_theme.dart';
import '../../widgets/console_formats.dart';
import '../../widgets/console_widgets.dart';
import '../shared/request_review_dialog.dart';

/// What the moderators have been doing, and what they have handed back.
///
/// This is the admin panel's Notifications screen, given the name it always
/// deserved. Two things live here: the activity feed, and — the reason an
/// admin opens it — the requests a moderator escalated and is waiting on.
class AdminEscalationsPage extends StatefulWidget {
  const AdminEscalationsPage({super.key});

  @override
  State<AdminEscalationsPage> createState() => _AdminEscalationsPageState();
}

class _AdminEscalationsPageState extends State<AdminEscalationsPage> {
  @override
  void initState() {
    super.initState();
    // Opening the page is what marks the feed read, which is what the bell in
    // the rail counts against.
    ConsoleBackend.instance.localVerification?.markActivitySeen();
  }

  @override
  Widget build(BuildContext context) {
    final backend = ConsoleBackend.instance;
    final local = backend.localVerification;

    return ConsoleShell(
      child: StreamBuilder<List<AccountVerificationRequest>>(
        stream: backend.verification.watchRequests(),
        builder: (context, requestSnapshot) {
          final requests =
              requestSnapshot.data ?? const <AccountVerificationRequest>[];
          final escalated = requests
              .where((r) => r.escalated && r.isPending)
              .toList(growable: false);

          return StreamBuilder<List<ModerationActivity>>(
            stream: local?.watchActivity() ?? const Stream.empty(),
            initialData: const <ModerationActivity>[],
            builder: (context, activitySnapshot) {
              final activity =
                  activitySnapshot.data ?? const <ModerationActivity>[];

              return ListView(
                padding: consolePagePadding(context),
                children: [
                  ConsoleCard(
                    title: 'Waiting on you',
                    subtitle: escalated.isEmpty
                        ? 'Requests a moderator flagged for an admin decision'
                        : '${escalated.length} escalated ${escalated.length == 1 ? 'request' : 'requests'}',
                    padding: escalated.isEmpty
                        ? EdgeInsets.zero
                        : EdgeInsets.all(context.layout.cardPadding),
                    child: escalated.isEmpty
                        ? const ConsoleEmptyState(
                            icon: Icons.flag_outlined,
                            title: 'Nothing escalated',
                            message:
                                'A moderator who is unsure about a registration can '
                                'flag it here for you to settle.',
                          )
                        : Column(
                            children: [
                              for (final request in escalated)
                                _EscalatedRow(request: request),
                            ],
                          ),
                  ),
                  SizedBox(height: context.layout.sectionSpacing),
                  ConsoleCard(
                    title: 'Moderator activity',
                    subtitle: 'Every approval, rejection and escalation',
                    padding: activity.isEmpty
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: activity.isEmpty
                        ? const ConsoleEmptyState(
                            icon: Icons.notifications_none,
                            title: 'No activity yet',
                            message:
                                'Decisions made on the queue are recorded here, with '
                                'who made them and when.',
                          )
                        : Column(
                            children: [
                              for (final entry in activity)
                                _ActivityRow(
                                  entry: entry,
                                  request: _findRequest(requests, entry.requestId),
                                ),
                            ],
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  AccountVerificationRequest? _findRequest(
    List<AccountVerificationRequest> requests,
    String id,
  ) {
    for (final request in requests) {
      if (request.id == id) return request;
    }
    return null;
  }
}

class _EscalatedRow extends StatelessWidget {
  const _EscalatedRow({required this.request});

  final AccountVerificationRequest request;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final layout = context.layout;

    final identity = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: ConsoleColors.warning.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.flag_outlined, size: 17, color: ConsoleColors.warning),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(request.name, style: text.titleSmall),
              Text(
                '${request.role.label} · ${request.userNumber} · '
                'submitted ${formatConsoleDate(request.submittedAt)}',
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );

    final review = ElevatedButton(
      onPressed: () => showRequestReviewDialog(context, request),
      child: const Text('Review'),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ConsoleColors.warning.withValues(alpha: 0.07),
        borderRadius: ConsoleMetrics.borderRadius,
        border: Border.all(color: ConsoleColors.warning.withValues(alpha: 0.35)),
      ),
      // On a phone the Review button goes under the name rather than
      // squeezing it — a truncated name is worse than an extra row.
      child: layout.isPhone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 14),
                review,
              ],
            )
          : Row(
              children: [
                Expanded(child: identity),
                const SizedBox(width: 12),
                review,
              ],
            ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry, required this.request});

  final ModerationActivity entry;
  final AccountVerificationRequest? request;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = colorForModerationAction(entry.action);
    final resolved = entry.action == ModerationAction.escalated &&
        request != null &&
        !request!.isPending;

    return InkWell(
      onTap: request == null ? null : () => showRequestReviewDialog(context, request!),
      borderRadius: ConsoleMetrics.borderRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconForModerationAction(entry.action), size: 14, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.accountName,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall,
                        ),
                      ),
                      ConsoleBadge(label: entry.action.label, color: color),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.role.label} · by ${entry.moderatorName} · '
                    '${formatConsoleDateTime(entry.occurredAt)}',
                    style: text.bodySmall,
                  ),
                  if (entry.reason != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      entry.reason!,
                      style: text.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (resolved) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Resolved · ${request!.status.label.toLowerCase()} by '
                      '${request!.reviewerName ?? '—'}',
                      style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
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
