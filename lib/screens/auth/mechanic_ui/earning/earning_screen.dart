import 'package:flutter/material.dart';
import '../../../../data/quote_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';
import '../rank/mechanic_leaderboard_screen.dart';

class EarningScreen extends StatefulWidget {
  const EarningScreen({super.key});

  @override
  State<EarningScreen> createState() => _EarningScreenState();
}

class _EarningScreenState extends State<EarningScreen> {
  bool _showBalance = true;
  final _store = QuoteNotificationStore.instance;

  static const _mechanicName = QuoteNotificationStore.currentMechanicName;
  static const _topMechanics = ['Pedro Santos', 'Juan Dela Cruz', 'Maria Garcia'];

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

  void _toggleBalance() => setState(() => _showBalance = !_showBalance);

  _ProblemText _splitProblem(String problem) {
    final idx = problem.indexOf(':');
    if (idx == -1 || idx > 40) return _ProblemText('Reported Issue', problem);
    final rest = problem.substring(idx + 1).trim();
    return _ProblemText(problem.substring(0, idx).trim(), rest.isEmpty ? problem : rest);
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    return '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final balance = _store.totalEarningsFor(_mechanicName);
    final points = _store.totalPointsFor(_mechanicName);
    final paidJobs = _store.completedJobsFor(_mechanicName)
      ..sort((a, b) => (b.paymentCompletedAt ?? b.createdAt).compareTo(a.paymentCompletedAt ?? a.createdAt));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Available Balance',
                            style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: _toggleBalance,
                          child: Icon(_showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.white, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showBalance ? '₱${balance.toStringAsFixed(2)}' : '••••',
                      style: const TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 48, color: AppColors.white.withValues(alpha: 0.3)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.card_giftcard, color: AppColors.white, size: 16),
                        SizedBox(width: 4),
                        Text('Points', style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showBalance ? '$points' : '••••',
                      style: const TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Top Mechanics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MechanicLeaderboardScreen())),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              child: const Text('View All', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: _topMechanics
                .map((name) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.background,
                        child: const Icon(Icons.person, color: AppColors.textGrey),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Service History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (paidJobs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Completed and paid jobs will show up here.', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
            ),
          )
        else
          ...paidJobs.map((job) {
            final quote = _store.acceptedQuoteFor(job.id);
            final problem = _splitProblem(job.problem);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: AppColors.borderGrey), borderRadius: BorderRadius.circular(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.clientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(problem.issue, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
                        const SizedBox(height: 2),
                        Text(_formatDate(job.paymentCompletedAt), style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                          child: const Text('Paid', style: TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(quote?.price ?? '—', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.green)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.card_giftcard, size: 14, color: AppColors.primary),
                          const SizedBox(width: 2),
                          Text('+${job.pointsAwarded ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _ProblemText {
  final String issue;
  final String description;
  const _ProblemText(this.issue, this.description);
}