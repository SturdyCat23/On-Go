import 'package:flutter/material.dart';

import '../../../../data/points_offers.dart';
import '../../../../data/points_wallet_store.dart';
import '../../../../data/quote_store.dart';
import '../../../../services/backend/mobile_backend.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../../widgets/points_widgets.dart';

/// What a mechanic can do with their points.
///
/// The screen renders [PointsOffers.forMechanic] and knows nothing about any
/// particular offer: it asks each one for its title, its cost and whether it
/// can be taken, and hands redemption back to it. A second offer is a new
/// [PointsOffer] in `points_offers.dart` and no change here.
class PointsOffersScreen extends StatefulWidget {
  const PointsOffersScreen({super.key});

  @override
  State<PointsOffersScreen> createState() => _PointsOffersScreenState();
}

class _PointsOffersScreenState extends State<PointsOffersScreen> {
  final _wallet = PointsWalletStore.instance;

  @override
  void initState() {
    super.initState();
    _wallet.addListener(_onChange);
  }

  @override
  void dispose() {
    _wallet.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  String get _mechanicName => QuoteNotificationStore.currentMechanicName;

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: AppDurations.snackBar),
    );
  }

  Future<void> _take(PointsOffer offer) async {
    final name = _mechanicName;

    double? amount;
    if (offer.takesAmount) {
      amount = await _askAmount(offer);
      if (amount == null) return;
    } else {
      final confirmed = await _confirm(offer);
      if (confirmed != true) return;
    }

    final error = offer.redeem(name, points: amount);
    _notify(error ?? '${offer.title} done');
  }

  Future<bool?> _confirm(PointsOffer offer) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(offer.title),
          content: Text(offer.description),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Confirm')),
          ],
        ),
      );

  /// For an offer the mechanic sizes themselves.
  Future<double?> _askAmount(PointsOffer offer) async {
    final balance = _wallet.balanceFor(_mechanicName);
    final controller =
        TextEditingController(text: formatPoints(balance));
    String? error;

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(offer.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(offer.description,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textdark.withValues(alpha: 0.55))),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Points to convert',
                  helperText: 'You have ${formatPointsLabel(balance)}',
                  errorText: error,
                ),
                onChanged: (_) {
                  if (error != null) setDialogState(() => error = null);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(controller.text.trim());
                if (value == null || value <= 0) {
                  setDialogState(() => error = 'Enter a number of points.');
                  return;
                }
                if (!_wallet.canAfford(_mechanicName, value)) {
                  setDialogState(() =>
                      error = 'You only have ${formatPointsLabel(balance)}.');
                  return;
                }
                Navigator.pop(ctx, value);
              },
              child: const Text('Convert'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final name = _mechanicName;
    final offers = PointsOffers.forMechanic(name);
    final balance = _wallet.balanceFor(name);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textlight,
        title: const Text('View Offer'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PointsBalanceCard(
            points: balance,
            caption: 'Worth ${formatPesos(pesosForPoints(balance))}',
          ),
          const SizedBox(height: 16),
          Text(
            offers.length == 1
                ? 'One way to use your points'
                : '${offers.length} ways to use your points',
            style: TextStyle(
                fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 10),
          for (final offer in offers) ...[
            _OfferCard(
              offer: offer,
              mechanicName: name,
              onTake: () => _take(offer),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.mechanicName,
    required this.onTake,
  });

  final PointsOffer offer;
  final String mechanicName;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    final available = offer.availableFor(mechanicName);

    return AppCard(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.savings_outlined,
                    size: 20, color: AppColors.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(offer.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            offer.description,
            style: TextStyle(
                fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55)),
          ),
          const SizedBox(height: 8),
          Text(
            available
                ? offer.rewardFor(mechanicName)
                : offer.unavailableReason(mechanicName),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: available
                  ? AppColors.success
                  : AppColors.textdark.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: available ? onTake : null,
              child: Text(available ? 'Use points' : 'Not enough points'),
            ),
          ),
        ],
      ),
    );
  }
}
