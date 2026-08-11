import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
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

  static const _topMechanics = ['Pedro Santos', 'Juan Dela Cruz', 'Maria Garcia'];

  List<Map<String, dynamic>> _history = [];

  void _toggleBalance() => setState(() => _showBalance = !_showBalance);

  void _markCompleted(int index) {
    setState(() {
      final item = _history[index];
      if (!(item['completed'] as bool)) {
        item['completed'] = true;
        _balance += (item['earned'] as int);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Available Balance',
                      style: TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _toggleBalance,
                    icon: Icon(_showBalance ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.white, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _showBalance ? '₱${_balance.toString()}' : '••••',
                style: const TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.w800),
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
        Row(
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
        const SizedBox(height: 24),
        const Text('Service History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...List.generate(_history.length, (idx) {
          final item = _history[idx];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderGrey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['date'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                const SizedBox(height: 4),
                Text(item['issue'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(item['description'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Earned ₱${item['earned']}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary)),
                    Row(
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < (item['rating'] as int) ? Icons.star : Icons.star_border,
                              color: AppColors.yellow,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (!(item['completed'] as bool))
                      ElevatedButton(
                        onPressed: () => _markCompleted(idx),
                        child: const Text('Mark Completed'),
                      ),
                    if ((item['completed'] as bool) && (item['clientActive'] as bool)) ...[
                      TextButton(onPressed: () => _showRatingDialog(idx), child: const Text('Awaiting Client Rating')),
                      const SizedBox(width: 8),
                      TextButton(onPressed: () => _simulateClientRating(idx), child: const Text('Simulate Client Rating')),
                    ],
                    if ((item['completed'] as bool) && !(item['clientActive'] as bool) && (item['rating'] as int) == 0)
                      TextButton(onPressed: () => _showRatingDialog(idx), child: const Text('Rate')),
                    if ((item['completed'] as bool))
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          (item['clientActive'] as bool)
                              ? 'Client can rate'
                              : ((item['rating'] as int) > 0 ? 'Rated: ${item['rating']}' : 'Completed'),
                          style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                        ),
                      ),
                  ],
                )
              ],
            ),
          );
        }),
      ],
    );
  }
}