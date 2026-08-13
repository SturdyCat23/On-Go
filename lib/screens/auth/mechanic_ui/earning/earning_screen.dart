import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';
import '../rank/mechanic_leaderboard_screen.dart';
import 'package:on_go/services/local_data.dart';

class EarningScreen extends StatefulWidget {
  const EarningScreen({super.key});

  @override
  State<EarningScreen> createState() => _EarningScreenState();
}

class _EarningScreenState extends State<EarningScreen> {
  bool _showBalance = true;
  int _balance = 0;
  double _points = 0;

  static const _topMechanics = ['Pedro Santos', 'Juan Dela Cruz', 'Maria Garcia'];

  List<Map<String, dynamic>> _history = [];

  void _toggleBalance() => setState(() => _showBalance = !_showBalance);

  void _markCompleted(int index) {
    setState(() {
      final item = _history[index];
      if (!(item['completed'] as bool)) {
        item['completed'] = true;
        final earned = item['earned'] as int;
        _balance += earned;
        _points += earned * 0.1; // Todo: replace with real points/rewards rules once defined.
        item['clientActive'] = true; // client can now rate
        LocalData.saveHistory(_history);
        LocalData.saveBalance(_balance);
      }
    });
  }

  Future<void> _showRatingDialog(int index) async {
    int selected = (_history[index]['rating'] as int?) ?? 0;
    final result = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rate this job'),
        content: StatefulBuilder(builder: (context, setState) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return IconButton(
                icon: Icon(i < selected ? Icons.star : Icons.star_border, color: AppColors.yellow),
                onPressed: () => setState(() => selected = i + 1),
              );
            }),
          );
        }),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, selected), child: const Text('Submit')),
        ],
      ),
    );

    if (result != null && result > 0) {
      setState(() {
        _history[index]['rating'] = result;
        _history[index]['clientActive'] = false;
        LocalData.saveHistory(_history);
      });
    }
  }

  void _simulateClientRating(int index) {
    final rnd = Random();
    final simulated = 3 + rnd.nextInt(3); // 3..5
    setState(() {
      _history[index]['rating'] = simulated;
      _history[index]['clientActive'] = false;
      LocalData.saveHistory(_history);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Client rated $simulated ⭐ (simulated)')),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPersistent();
  }

  Future<void> _loadPersistent() async {
    final hist = await LocalData.loadHistory();
    final bal = await LocalData.loadBalance();
    setState(() {
      _history = hist;
      _balance = bal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(14),
          ),
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
                      _showBalance ? '₱${_balance.toString()}' : '••••',
                      style: const TextStyle(color: AppColors.white, fontSize: 30, fontWeight: FontWeight.w800),
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
                      _showBalance ? _points.toStringAsFixed(2) : '••••',
                      style: const TextStyle(color: AppColors.white, fontSize: 30, fontWeight: FontWeight.w800),
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
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MechanicLeaderboardScreen())),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              child: const Text('View All',
                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
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
        ...List.generate(_history.length, (idx) {
          final item = _history[idx];
          final completed = item['completed'] as bool;
          final rating = item['rating'] as int;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderGrey),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['issue'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(item['description'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                          const SizedBox(height: 2),
                          Text(item['date'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₱${item['earned']}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.green)),
                        if (rating > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: AppColors.yellow),
                              const SizedBox(width: 2),
                              Text('$rating', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (!completed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _markCompleted(idx),
                      style: ElevatedButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 10)),
                      child: const Text('Mark Completed'),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                        child: const Text('Completed', style: TextStyle(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      if (item['clientActive'] as bool) ...[
                        TextButton(onPressed: () => _showRatingDialog(idx), child: const Text('Awaiting Client Rating', style: TextStyle(fontSize: 12))),
                        TextButton(onPressed: () => _simulateClientRating(idx), child: const Text('Simulate Client Rating', style: TextStyle(fontSize: 12))),
                      ] else if (rating == 0)
                        TextButton(onPressed: () => _showRatingDialog(idx), child: const Text('Rate', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}