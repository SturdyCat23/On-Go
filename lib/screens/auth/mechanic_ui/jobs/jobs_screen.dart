import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';
// Todo: adjust this path to wherever quote_store.dart lives in your project
import '../../../../data/quote_store.dart';
import 'send_quote_sheet.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  int _tabIndex = 0;

  // Todo: replace with the logged-in mechanic's real name/id once auth exists.
  static const _mechanicName = 'You';

  // Requests this mechanic has already sent a quote for, so the button
  // becomes "Quote Sent" instead of letting them send a second one.
  final Set<String> _myQuotedRequestIds = {};

  Future<void> _sendQuote(HelpRequest request) async {
    final input = await showModalBottomSheet<QuoteInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SendQuoteSheet(request: request),
    );
    if (input == null) return;

    QuoteNotificationStore.instance.mechanicSendQuote(
      request.id,
      mechanicName: _mechanicName,
      price: '₱${input.total.toStringAsFixed(0)}',
      eta: input.estimatedTime,
      // Todo: pull this mechanic's real rating from their profile.
      rating: 4.8,
    );
    setState(() => _myQuotedRequestIds.add(request.id));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote sent — the client will compare offers and choose.')),
    );
  }

  void _acceptEmergency(HelpRequest request) {
    final won = QuoteNotificationStore.instance.mechanicAcceptEmergency(
      request.id,
      mechanicName: _mechanicName,
      // Todo: pull a real emergency callout rate from the mechanic's profile.
      price: '₱200',
      eta: '15 mins',
      rating: 4.8,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(won
            ? 'Job accepted! Head to the client now.'
            : 'Too late — another mechanic already took this emergency.'),
      ),
    );
  }

  void _completeJob(HelpRequest request) {
    QuoteNotificationStore.instance.mechanicCompleteJob(request.id);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: QuoteNotificationStore.instance,
      builder: (context, _) {
        final store = QuoteNotificationStore.instance;
        final available = store.availableJobs;
        final accepted = store.matchedJobsFor(_mechanicName);
        final completed = store.completedJobsFor(_mechanicName);

        return Column(
          children: [
            _JobTabBar(
              currentIndex: _tabIndex,
              onChanged: (i) => setState(() => _tabIndex = i),
              counts: [available.length, accepted.length, completed.length],
            ),
            Expanded(
              child: IndexedStack(
                index: _tabIndex,
                children: [
                  _AvailableTab(
                    requests: available,
                    quotedIds: _myQuotedRequestIds,
                    onAccept: _acceptEmergency,
                    onSendQuote: _sendQuote,
                  ),
                  _AcceptedTab(
                    requests: accepted,
                    store: store,
                    onComplete: _completeJob,
                  ),
                  _CompletedTab(requests: completed, store: store),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------
// Small display helpers
// ---------------------------------------------------------------------

Color _urgencyColor(String urgency) {
  switch (urgency) {
    case 'Emergency':
      return AppColors.primary;
    case 'Urgent':
      return AppColors.yellow;
    default:
      return AppColors.green;
  }
}

String _timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
  if (diff.inHours < 24) return '${diff.inHours} hr${diff.inHours == 1 ? '' : 's'} ago';
  return '${time.month.toString().padLeft(2, '0')}/${time.day.toString().padLeft(2, '0')}/${time.year}';
}

class _ProblemText {
  final String issue;
  final String description;
  const _ProblemText(this.issue, this.description);
}

/// NeedHelpScreen prefixes free text with "Issue Label: " when the client
/// tapped a common-issue chip. Split that back out for display; fall back to
/// a generic label for freeform text.
_ProblemText _splitProblem(String problem) {
  final idx = problem.indexOf(':');
  if (idx == -1 || idx > 40) {
    return _ProblemText('Reported Issue', problem);
  }
  final rest = problem.substring(idx + 1).trim();
  return _ProblemText(problem.substring(0, idx).trim(), rest.isEmpty ? problem : rest);
}

// ---------------------------------------------------------------------
// Tab bar
// ---------------------------------------------------------------------

class _JobTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<int> counts;

  const _JobTabBar({required this.currentIndex, required this.onChanged, required this.counts});

  static const _labels = ['Available', 'Accepted', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: List.generate(3, (i) {
          final selected = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(_labels[i],
                        style: TextStyle(fontSize: 12, color: selected ? AppColors.white : AppColors.textDark)),
                    Text('${counts[i]}',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: selected ? AppColors.white : AppColors.textDark)),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Available tab
// ---------------------------------------------------------------------

class _AvailableTab extends StatelessWidget {
  final List<HelpRequest> requests;
  final Set<String> quotedIds;
  final void Function(HelpRequest) onAccept;
  final void Function(HelpRequest) onSendQuote;

  const _AvailableTab({
    required this.requests,
    required this.quotedIds,
    required this.onAccept,
    required this.onSendQuote,
  });

  @override
  Widget build(BuildContext context) {
        return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        AppCard(
          color: const Color(0xFFE3F2FD),
          padding: const EdgeInsets.all(12),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Tip: ', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.blue)),
                TextSpan(
                  text:
                      'Send competitive quotes to win Normal/Urgent jobs. Emergencies are first come, '
                      'first served — tap Accept fast, there\'s no quote comparison.',
                  style: TextStyle(color: AppColors.blue),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 16),
        if (requests.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('No available jobs right now', style: TextStyle(color: AppColors.textGrey)),
            ),
          ),
        ...requests.map((request) {
          final alreadyQuoted = quotedIds.contains(request.id);
          return _JobCard(
            request: request,
            actionLabel: request.isEmergency
                ? 'Accept'
                : (alreadyQuoted ? 'Quote Sent' : 'Send Quote'),
            actionEnabled: request.isEmergency || !alreadyQuoted,
            onAction: request.isEmergency ? () => onAccept(request) : () => onSendQuote(request),
          );
        }),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final HelpRequest request;
  final String actionLabel;
  final bool actionEnabled;
  final VoidCallback onAction;

  const _JobCard({
    required this.request,
    required this.actionLabel,
    required this.onAction,
    this.actionEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final problem = _splitProblem(request.problem);
    final urgencyColor = _urgencyColor(request.urgency);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.clientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(_timeAgo(request.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(20)),
                child: Text(request.urgency,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: urgencyColor)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(problem.issue, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(problem.description, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          if (request.photoPaths.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('${request.photoPaths.length} photo${request.photoPaths.length == 1 ? '' : 's'} attached',
                style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Expanded(child: Text(request.location, style: const TextStyle(fontSize: 12))),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: actionEnabled ? onAction : null,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Accepted tab
// ---------------------------------------------------------------------

class _AcceptedTab extends StatelessWidget {
  final List<HelpRequest> requests;
  final QuoteNotificationStore store;
  final void Function(HelpRequest) onComplete;

  const _AcceptedTab({required this.requests, required this.store, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(child: Text('No active jobs', style: TextStyle(color: AppColors.textGrey)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: requests
          .map((r) => _ActiveJobCard(
                request: r,
                quote: store.acceptedQuoteFor(r.id),
                onComplete: () => onComplete(r),
              ))
          .toList(),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  final HelpRequest request;
  final MechanicQuote? quote;
  final VoidCallback onComplete;

  const _ActiveJobCard({required this.request, required this.quote, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final problem = _splitProblem(request.problem);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(request.isEmergency ? 'EMERGENCY JOB' : 'ACTIVE JOB',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(request.clientName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          Text(problem.issue, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          Text(problem.description, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Expanded(child: Text(request.location, style: const TextStyle(fontSize: 12))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Payment', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                  Text(quote?.price ?? '₱200',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.navigation_outlined, size: 18),
              label: const Text('Navigate to Location'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: AppColors.white),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.call, size: 18),
              label: const Text('Call Client'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.white),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onComplete,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textDark,
                side: const BorderSide(color: AppColors.borderGrey),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Mark as Completed'),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Completed tab
// ---------------------------------------------------------------------

class _CompletedTab extends StatelessWidget {
  final List<HelpRequest> requests;
  final QuoteNotificationStore store;

  const _CompletedTab({required this.requests, required this.store});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(child: Text('No completed jobs yet', style: TextStyle(color: AppColors.textGrey)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: requests
          .map((r) => _CompletedJobCard(request: r, quote: store.acceptedQuoteFor(r.id)))
          .toList(),
    );
  }
}

class _CompletedJobCard extends StatelessWidget {
  final HelpRequest request;
  final MechanicQuote? quote;

  const _CompletedJobCard({required this.request, required this.quote});

  @override
  Widget build(BuildContext context) {
    final problem = _splitProblem(request.problem);
    final date = request.completedAt;
    final dateText =
        date == null ? '' : '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.clientName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(dateText, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: AppColors.green),
            ],
          ),
          const SizedBox(height: 8),
          Text(problem.issue, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          Text(problem.description, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Expanded(child: Text(request.location, style: const TextStyle(fontSize: 12))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Payment', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                  Text(quote?.price ?? '₱200',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}