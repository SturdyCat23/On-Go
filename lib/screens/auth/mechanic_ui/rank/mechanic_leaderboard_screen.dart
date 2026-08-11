import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/app_widgets.dart';
import '../../../../widgets/common_widgets.dart';

class MechanicLeaderboardScreen extends StatelessWidget {
  const MechanicLeaderboardScreen({super.key});

  static const _leaders = [
    {'name': 'Pedro Santos', 'tier': 'Platinum', 'rating': 5.0},
    {'name': 'Juan Dela Cruz', 'tier': 'Gold', 'rating': 4.8},
    {'name': 'Maria Garcia', 'tier': 'Silver', 'rating': 4.3},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Leaderboards', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ...List.generate(_leaders.length, (i) {
          final leader = _leaders[i];
          final isYou = leader['name'] == 'Juan Dela Cruz';
          return AppCard(
            color: isYou ? AppColors.primary.withValues(alpha: 0.06) : null,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.background,
                  child: Icon(Icons.person, color: AppColors.textGrey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(leader['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      if (isYou) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('You',
                              style: TextStyle(fontSize: 10, color: AppColors.white, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                ),
                TierBadge(tier: leader['tier'] as String),
                const SizedBox(width: 10),
                RatingStars(rating: leader['rating'] as double),
              ],
            ),
          );
        }),
      ],
    );
  }
}