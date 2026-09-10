import 'package:flutter/material.dart';
import '../../../../data/points_offers.dart';
import '../../../../data/points_wallet_store.dart';
import '../../../../data/quote_store.dart';
import '../../../../services/backend/mobile_backend.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';
import '../rank/mechanic_leaderboard_screen.dart';
import 'points_offers_screen.dart';

class EarningScreen extends StatefulWidget {
  const EarningScreen({super.key, this.onViewAll});

  final VoidCallback? onViewAll;

  @override
  State<EarningScreen> createState() => _EarningScreenState();
}

class _EarningScreenState extends State<EarningScreen> {
  bool _showBalance = true;
  final _store = QuoteNotificationStore.instance;
  final _wallet = PointsWalletStore.instance;

  String get _mechanicName => QuoteNotificationStore.currentMechanicName;

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
    // Earnings plus anything converted from points — the wallet records the
    // conversion, so the balance follows it without earnings history moving.
    final balance = _store.totalEarningsFor(_mechanicName) +
        PointsOffers.convertedBalanceFor(_mechanicName);
    // Spendable, not lifetime: converting draws this down.
    final points = _wallet.balanceFor(_mechanicName);
    final paidJobs = _store.completedJobsFor(_mechanicName)
      ..sort((a, b) => (b.paymentCompletedAt ?? b.createdAt).compareTo(a.paymentCompletedAt ?? a.createdAt));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.primarydark, borderRadius: BorderRadius.circular(16)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Available Balance',
                            style: TextStyle(color: AppColors.textlight, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: _toggleBalance,
                          child: Icon(_showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.textlight, size: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showBalance ? '₱${balance.toStringAsFixed(2)}' : '••••',
                      style: TextStyle(color: AppColors.textlight, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 48, color: AppColors.surface.withValues(alpha: 0.3)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.card_giftcard, color: AppColors.textlight, size: 16),
                        SizedBox(width: 4),
                        Text('Points', style: TextStyle(color: AppColors.textlight, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showBalance ? formatPoints(points) : '••••',
                      style: TextStyle(color: AppColors.textlight, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const _ViewOfferButton(),
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
              onPressed: widget.onViewAll ?? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MechanicLeaderboardScreen()),
                  ),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              child: Text('View All',
                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          // Todo: there's no multi-mechanic backend yet, so this is always
          // just the current mechanic — same single-entry source as
          // MechanicLeaderboardScreen. Capped at 5 for when that changes.
          child: Row(
            children: [_mechanicName]
                .take(5)
                .map((name) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.surface,
                        child: Icon(Icons.person, color: AppColors.textdark.withValues(alpha: 0.55)),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Service History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        if (paidJobs.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Completed and paid jobs will show up here.', style: TextStyle(color: AppColors.textdark.withValues(alpha: 0.55), fontSize: 12)),
            ),
          )
        else
          ...paidJobs.map((job) {
            final quote = _store.acceptedQuoteFor(job.id);
            // What the mechanic was actually paid. Emergency jobs carry a
            // placeholder price on their accept record — the real figure is
            // the amount agreed in person — so this goes through the same
            // rule the balance above is summed from, never quote.price.
            final amount = effectivePaymentAmount(job, quote);
            final problem = _splitProblem(job.problem);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.clientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(problem.issue, style: TextStyle(fontSize: 12, color: AppColors.textdark)),
                        const SizedBox(height: 2),
                        Text(_formatDate(job.paymentCompletedAt), style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55))),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                          child: Text('Paid', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(amount == null ? '—' : '₱${amount.toStringAsFixed(0)}',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.success)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.card_giftcard, size: 14, color: AppColors.warning),
                          const SizedBox(width: 2),
                          Text('+${job.pointsAwarded ?? 0}', style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w700)),
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
/// Opens the offers a mechanic can spend points on.
///
/// Its own widget so the earnings header stays a layout, and so the button
/// reads the same wherever it is put next.
class _ViewOfferButton extends StatelessWidget {
  const _ViewOfferButton();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PointsOffersScreen()),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          minimumSize: const Size(0, 0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: AppColors.textlight.withValues(alpha: 0.18),
        ),
        icon: Icon(Icons.local_offer_outlined, size: 14, color: AppColors.textlight),
        label: Text(
          'View Offer',
          style: TextStyle(
            color: AppColors.textlight,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
