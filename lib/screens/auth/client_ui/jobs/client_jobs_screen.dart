import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../../data/quote_store.dart';
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

  void _cancelJob(HelpRequest request) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this request?'),
        content: Text('This will let your mechanic know you no longer need this service.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Job')),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            // Todo: wire up a real cancel-after-match method on QuoteNotificationStore.
            child: const Text('Cancel Job', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = _store.myActiveJobs;
    final pending = all.where((r) => !r.isEmergency && !r.enRoute).toList();
    final active = all.where((r) => r.isEmergency || r.enRoute).toList()
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
              _JobList(
                requests: pending,
                emptyMessage: 'No pending jobs — accepted Normal or Urgent requests will show up here before your mechanic starts heading over.',
                statusLabel: 'Pending',
                statusEnabled: false,
                onOpen: _openJob,
                onCancel: _cancelJob,
              ),
              _JobList(
                requests: active,
                emptyMessage: 'No active jobs right now.',
                statusLabel: 'Navigate',
                statusEnabled: true,
                onOpen: _openJob,
                onCancel: _cancelJob,
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

class _JobList extends StatelessWidget {
  final List<HelpRequest> requests;
  final String emptyMessage;
  final String statusLabel;
  final bool statusEnabled;
  final void Function(HelpRequest) onOpen;
  final void Function(HelpRequest) onCancel;

  const _JobList({
    required this.requests,
    required this.emptyMessage,
    required this.statusLabel,
    required this.statusEnabled,
    required this.onOpen,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGrey)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: requests
          .map((r) => _JobCard(
                request: r,
                store: QuoteNotificationStore.instance,
                statusLabel: statusLabel,
                statusEnabled: statusEnabled,
                onOpen: () => onOpen(r),
                onCancel: () => onCancel(r),
              ))
          .toList(),
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

class _JobCard extends StatelessWidget {
  final HelpRequest request;
  final QuoteNotificationStore store;
  final String statusLabel;
  final bool statusEnabled;
  final VoidCallback onOpen;
  final VoidCallback onCancel;

  const _JobCard({
    required this.request,
    required this.store,
    required this.statusLabel,
    required this.statusEnabled,
    required this.onOpen,
    required this.onCancel,
  });

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
                  decoration: BoxDecoration(
                      color: request.isEmergency ? AppColors.primary : AppColors.green, shape: BoxShape.circle),
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
                Expanded(
                  child: Text(quote?.mechanicName ?? 'Mechanic', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ),
                _CircleIconButton(icon: Icons.call, color: AppColors.green, onTap: () {}),
                const SizedBox(width: 8),
                _CircleIconButton(icon: Icons.chat_bubble_outline, color: AppColors.blue, onTap: () {}),
              ],
            ),
            const SizedBox(height: 8),
            Text(problem.issue, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            Text(problem.description, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
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
                      Text(request.location, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Payment', style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                    const SizedBox(height: 2),
                    Text(quote?.price ?? '₱200',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.green)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: statusEnabled
                      ? ElevatedButton(
                          onPressed: onOpen,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: AppColors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(statusLabel),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(30)),
                          child: Text(statusLabel, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 14)),
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