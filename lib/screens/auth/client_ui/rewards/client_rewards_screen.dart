import 'package:flutter/material.dart';

import '../../../../data/client_account_store.dart';
import '../../../../data/points_policy_store.dart';
import '../../../../data/points_wallet_store.dart';
import '../../../../services/backend/mobile_backend.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../../widgets/points_widgets.dart';

/// The client's points: what they hold, how they earned it, what it is for.
///
/// Every figure here is read rather than computed locally — the balance from
/// [PointsWalletStore], the earning rates from [PointsPolicyStore] — so this
/// screen shows what a payment would actually award, not a description of it
/// that can fall out of step with the admin's settings.
class ClientRewardsScreen extends StatefulWidget {
  const ClientRewardsScreen({super.key});

  @override
  State<ClientRewardsScreen> createState() => _ClientRewardsScreenState();
}

class _ClientRewardsScreenState extends State<ClientRewardsScreen> {
  final _wallet = PointsWalletStore.instance;
  final _policy = PointsPolicyStore.instance;
  final _account = ClientAccountStore.instance;

  @override
  void initState() {
    super.initState();
    _wallet.addListener(_onChange);
    _policy.addListener(_onChange);
    _account.addListener(_onChange);
  }

  @override
  void dispose() {
    _wallet.removeListener(_onChange);
    _policy.removeListener(_onChange);
    _account.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  String get _owner => _account.name;

  @override
  Widget build(BuildContext context) {
    final balance = _wallet.balanceFor(_owner);
    final entries = _wallet.entriesFor(_owner);
    final policy = _policy.current;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textlight,
        title: const Text('Rewards & Points'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PointsBalanceCard(
            points: balance,
            caption: 'Worth ${formatPesos(pesosForPoints(balance))} towards '
                'priority fees',
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How you earn',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Points are added once you complete the payment for a job.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55)),
                ),
                const SizedBox(height: 12),
                for (final urgency in PointsPolicy.urgencies)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('$urgency job',
                              style: const TextStyle(fontSize: 13)),
                        ),
                        Text(
                          formatPointsLabel(policy.clientPointsFor(urgency)),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How you spend',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'At checkout on an Urgent or Emergency job you can put your '
                  'points towards the priority fee, at 1 pt = ₱1. The option '
                  'appears when your balance covers the whole fee.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('History',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  Text(
                    'Nothing yet. Complete a job to earn your first points.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55)),
                  )
                else
                  ...entries.map((e) => PointsEntryRow(entry: e)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
