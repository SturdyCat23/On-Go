import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/app_widgets.dart';
import '../profile/mechanic_profile_view_screen.dart';

enum _RankFilter { rank, ratings, reviews }

class _Leader {
  final String name;
  final String tier;
  final double rating;
  final int reviewCount;
  const _Leader({required this.name, required this.tier, required this.rating, required this.reviewCount});

  int get tierValue => switch (tier) {
        'Platinum' => 3,
        'Gold' => 2,
        _ => 1,
      };
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const _leaders = [
    _Leader(name: 'Pedro Santos', tier: 'Platinum', rating: 5.0, reviewCount: 8000),
    _Leader(name: 'Juan Dela Cruz', tier: 'Gold', rating: 4.8, reviewCount: 6000),
    _Leader(name: 'Maria Garcia', tier: 'Silver', rating: 4.3, reviewCount: 10000),
  ];

  _RankFilter _filter = _RankFilter.rank;
  bool _ascending = false;
  bool _filterOpen = false;
  String _query = '';

  List<_Leader> get _sorted {
    final list = _leaders.where((l) => l.name.toLowerCase().contains(_query.toLowerCase())).toList();
    list.sort((a, b) {
      final cmp = switch (_filter) {
        _RankFilter.rank => a.tierValue.compareTo(b.tierValue),
        _RankFilter.ratings => a.rating.compareTo(b.rating),
        _RankFilter.reviews => a.reviewCount.compareTo(b.reviewCount),
      };
      return _ascending ? cmp : -cmp;
    });
    return list;
  }

  String _reviewLabel(int count) => count >= 1000 ? '${(count / 1000).toStringAsFixed(0)}k reviews' : '$count reviews';

  Widget _trailingFor(_Leader leader) {
    switch (_filter) {
      case _RankFilter.rank:
        return Text(leader.tier, style: const TextStyle(fontSize: 14, color: AppColors.textDark));
      case _RankFilter.ratings:
        return RatingStars(rating: leader.rating);
      case _RankFilter.reviews:
        return Text(_reviewLabel(leader.reviewCount), style: const TextStyle(fontSize: 14, color: AppColors.textDark));
    }
  }

  Widget _filterPill(String label, _RankFilter value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() {
        _filter = value;
        _filterOpen = false;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? AppColors.white : AppColors.textDark)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(24)),
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: const InputDecoration(
                        hintText: 'Search mechanics...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.search), onPressed: () {}),
                IconButton(
                  icon: const Icon(Icons.swap_vert),
                  onPressed: () => setState(() => _ascending = !_ascending),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => setState(() => _filterOpen = !_filterOpen),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._sorted.map((leader) => InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MechanicProfileViewScreen(name: leader.name)),
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
                          child: Text('${_sorted.indexOf(leader) + 1}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                        const SizedBox(width: 8),
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.background,
                          child: Icon(Icons.person, color: AppColors.textGrey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(leader.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                        _trailingFor(leader),
                      ],
                    ),
                  ),
                )),
          ],
        ),
        if (_filterOpen) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _filterOpen = false),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: 58,
            right: 20,
            width: 150,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('Filter', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  _filterPill('Rank', _RankFilter.rank),
                  _filterPill('Ratings', _RankFilter.ratings),
                  _filterPill('Reviews', _RankFilter.reviews),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}