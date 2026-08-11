import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/app_widgets.dart';
import '../profile/mechanic_profile_view_screen.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

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
          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MechanicProfileViewScreen(name: leader['name'] as String)),
            ),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderGrey),
                borderRadius: BorderRadius.circular(10),
              ),
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
                    child: Text(leader['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  TierBadge(tier: leader['tier'] as String),
                  const SizedBox(width: 10),
                  RatingStars(rating: leader['rating'] as double),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}