import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/chat_icon_button.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../../data/quote_store.dart';
import '../../../shared/job_chat_screen.dart';
import '../active/active_request_screen.dart';

class ClientJobsScreen extends StatefulWidget {
  const ClientJobsScreen({super.key});

  @override
  State<ClientJobsScreen> createState() => _ClientJobsScreenState();
}

class _ClientJobsScreenState extends State<ClientJobsScreen> {
  final _store = QuoteNotificationStore.instance;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChange);
  }

  @override
  void dispose() {
    _store.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  void _openJob(HelpRequest request) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ActiveRequestScreen(requestId: request.id)),
    );
  }

  Future<void> _cancelJob(HelpRequest request) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this request?'),
        content: const Text('You can put this back in the queue for another mechanic, or remove it completely.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Job')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'revert'),
            child: const Text('Revert to Pending'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'delete'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
    if (!mounted) return;

    if (choice == 'revert') {
      final ok = _store.clientRevertToPending(request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Request reverted to Pending — open to mechanics again.' : 'Could not revert this request.')),
      );
    } else if (choice == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete permanently?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (confirmed == true) {
        final ok = _store.clientDeleteRequest(request.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Request deleted.' : 'Could not delete this request.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _store.myActiveJobs;
    final pending = all.where((r) => !r.isEmergency && !r.navigating).toList();
    final active = all.where((r) => r.isEmergency || r.navigating).toList()
      ..sort((a, b) {
        if (a.isEmergency != b.isEmergency) return a.isEmergency ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });

    return Column(
      children: [
        _JobTabBar(
          currentIndex: _tabIndex,
          onChanged: (i) => setState(() => _tabIndex = i),
          counts: [pending.length, active.length],
        ),
        Expanded(
          child: IndexedStack(
            index: _tabIndex,
            children: [
              _PendingJobList(
                requests: pending,
                store: _store,
                onOpen: _openJob,
                onCancel: _cancelJob,
              ),
              _ActiveJobList(
                requests: active,
                store: _store,
                onOpen: _openJob,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JobTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<int> counts;

  const _JobTabBar({required this.currentIndex, required this.onChanged, required this.counts});

  static const _labels = ['Pending', 'Active'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: List.generate(2, (i) {
          final selected = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                margin: EdgeInsets.only(right: i < 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.background,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text('${_labels[i]} ${counts[i]}',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.white : AppColors.textDark)),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ProblemText {
  final String issue;
  final String description;
  const _ProblemText(this.issue, this.description);
}

_ProblemText _splitProblem(String problem) {
  final idx = problem.indexOf(':');
  if (idx == -1 || idx > 40) return _ProblemText('Reported Issue', problem);
  final rest = problem.substring(idx + 1).trim();
  return _ProblemText(problem.substring(0, idx).trim(), rest.isEmpty ? problem : rest);
}

Widget _locationBlock(String location) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGrey),
          const SizedBox(width: 4),
          const Text('Location', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
        ],
      ),
      const SizedBox(height: 2),
      Text(location, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
    ],
  );
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _PendingJobList extends StatelessWidget {
  final List<HelpRequest> requests;
  final QuoteNotificationStore store;
  final void Function(HelpRequest) onOpen;
  final void Function(HelpRequest) onCancel;

  const _PendingJobList({required this.requests, required this.store, required this.onOpen, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No pending jobs — accepted Normal or Urgent requests will show up here before your mechanic starts heading over.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: requests.map((r) => _PendingJobCard(request: r, store: store, onOpen: () => onOpen(r), onCancel: () => onCancel(r))).toList(),
    );
  }
}

class _PendingJobCard extends StatelessWidget {
  final HelpRequest request;
  final QuoteNotificationStore store;
  final VoidCallback onOpen;
  final VoidCallback onCancel;

  const _PendingJobCard({required this.request, required this.store, required this.onOpen, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final quote = store.acceptedQuoteFor(request.id);
    final problem = _splitProblem(request.problem);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('PENDING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green, letterSpacing: 0.5)),
              ],
            ),
            if (request.lastCancelReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '${request.lastCancelledBy ?? 'Mechanic'} cancelled: ${request.lastCancelReason}',
                  style: const TextStyle(fontSize: 11, color: AppColors.primary),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text(quote?.mechanicName ?? 'Mechanic', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
                _CircleIconButton(icon: Icons.call, color: AppColors.green, onTap: () {}),
                const SizedBox(width: 8),
                ChatIconButton(
                  requestId: request.id,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => JobChatScreen(requestId: request.id, otherPartyName: quote?.mechanicName ?? 'Mechanic')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(problem.issue, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(problem.description, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _locationBlock(request.location)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Payment', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                    const SizedBox(height: 2),
                    Text(quote?.price ?? '₱200', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(30)),
                    child: const Text('Pending', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveJobList extends StatelessWidget {
  final List<HelpRequest> requests;
  final QuoteNotificationStore store;
  final void Function(HelpRequest) onOpen;

  const _ActiveJobList({required this.requests, required this.store, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(child: Text('No active jobs right now.', style: TextStyle(color: AppColors.textGrey)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: requests.map((r) => _ActiveJobCard(request: r, store: store, onOpen: () => onOpen(r))).toList(),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  final HelpRequest request;
  final QuoteNotificationStore store;
  final VoidCallback onOpen;

  const _ActiveJobCard({required this.request, required this.store, required this.onOpen});

  String get _statusLabel {
    if (!request.arrived) return 'Navigate';
    if (!request.workStarted) return 'Mechanic Arrived';
    if (!request.serviceCompleted) return 'Work in Progress';
    return 'Send Payment';
  }

  Color get _statusColor => _statusLabel == 'Send Payment' ? AppColors.primary : AppColors.green;

  @override
  Widget build(BuildContext context) {
    final quote = store.acceptedQuoteFor(request.id);
    final problem = _splitProblem(request.problem);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: request.isEmergency ? AppColors.primary : AppColors.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(request.isEmergency ? 'ACTIVE · EMERGENCY' : 'ACTIVE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: request.isEmergency ? AppColors.primary : AppColors.green,
                        letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text(quote?.mechanicName ?? 'Mechanic', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
                _CircleIconButton(icon: Icons.call, color: AppColors.green, onTap: () {}),
                const SizedBox(width: 8),
                ChatIconButton(
                  requestId: request.id,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => JobChatScreen(requestId: request.id, otherPartyName: quote?.mechanicName ?? 'Mechanic')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(problem.issue, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(problem.description, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _locationBlock(request.location)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Payment', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                    const SizedBox(height: 2),
                    Text(quote?.price ?? '₱200', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onOpen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _statusColor,
                  foregroundColor: AppColors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(_statusLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}