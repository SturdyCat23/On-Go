import 'package:flutter/material.dart';
import '../../../../data/quote_store.dart';
import '../../../../data/review_store.dart';
import '../../../../theme/app_theme.dart';
import '../profile/mechanic_profile_view_screen.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  final _store = QuoteNotificationStore.instance;
  final _reviews = ReviewStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChange);
    _reviews.addListener(_onChange);
  }

  @override
  void dispose() {
    _store.removeListener(_onChange);
    _reviews.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final completed = _store.myCompletedJobs;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Service History', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        if (completed.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Completed jobs will show up here once you\'ve paid a mechanic.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textdark.withValues(alpha: 0.55), fontSize: 13),
              ),
            ),
          )
        else
          ...completed.map((request) {
            final quote = _store.acceptedQuoteFor(request.id);
            final mechanicName = quote?.mechanicName ?? 'Mechanic';
            final myReview = _reviews.reviewByCurrentClientFor(mechanicName);
            return _HistoryCard(
              mechanicName: mechanicName,
              location: request.location,
              date: _formatDate(request.paymentCompletedAt ?? request.completedAt),
              price: quote?.price ?? '—',
              rating: myReview?.rating,
            );
          }),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String mechanicName;
  final String location;
  final String date;
  final String price;
  final int? rating;

  const _HistoryCard({
    required this.mechanicName,
    required this.location,
    required this.date,
    required this.price,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MechanicProfileViewScreen(name: mechanicName)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textdark.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mechanicName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(location, style: TextStyle(fontSize: 13, color: AppColors.textdark)),
                  const SizedBox(height: 2),
                  Text(date, style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Completed',
                        style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.success)),
                const SizedBox(height: 6),
                if (rating != null)
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: AppColors.warning),
                      const SizedBox(width: 2),
                      Text('$rating', style: const TextStyle(fontSize: 13)),
                    ],
                  )
                else
                  Text('Rate this service', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}