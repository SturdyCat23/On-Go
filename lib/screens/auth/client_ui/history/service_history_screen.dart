import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../profile/mechanic_profile_view_screen.dart';

class ServiceHistoryScreen extends StatelessWidget {
  const ServiceHistoryScreen({super.key});

  static const _history = [
    {'name': 'Juan Dela Cruz', 'location': 'Puerto Princesa City', 'date': 'May 24, 2026', 'price': '₱200', 'rating': 4},
    {'name': 'Pedro Santos', 'location': 'Puerto Princesa City', 'date': 'Apr 02, 2026', 'price': '₱350', 'rating': 5},
    {'name': 'Maria Garcia', 'location': 'Puerto Princesa City', 'date': 'Feb 18, 2026', 'price': '₱150', 'rating': 4},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Service History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ..._history.map((item) => _HistoryCard(item: item)),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MechanicProfileViewScreen(name: item['name'] as String)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderGrey),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(item['location'] as String, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(item['date'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Completed',
                        style: TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item['price'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.green)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.yellow),
                    const SizedBox(width: 2),
                    Text('${item['rating']}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}