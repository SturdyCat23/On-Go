import 'package:flutter/material.dart';
import '../../../../data/review_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/app_widgets.dart';

class MechanicProfileViewScreen extends StatefulWidget {
  final String name;
  const MechanicProfileViewScreen({super.key, required this.name});

  @override
  State<MechanicProfileViewScreen> createState() => _MechanicProfileViewScreenState();
}

class _MechanicProfileViewScreenState extends State<MechanicProfileViewScreen> {
  final _store = ReviewStore.instance;

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

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 365) {
      final years = (diff.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
    if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    return 'today';
  }

  Future<void> _openReviewDialog() async {
    final existing = _store.reviewByCurrentClientFor(widget.name);
    int selected = existing?.rating ?? 0;
    final controller = TextEditingController(text: existing?.comment ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Write a review' : 'Edit your review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(i < selected ? Icons.star : Icons.star_border, color: AppColors.yellow),
                    onPressed: () => setDialogState(() => selected = i + 1),
                  );
                }),
              ),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Share your experience...'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selected == 0
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _store.submitReview(mechanicName: widget.name, rating: selected, comment: controller.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _store.reviewsFor(widget.name);
    final average = _store.averageRatingFor(widget.name);
    final distribution = _store.ratingDistributionFor(widget.name);
    final alreadyReviewed = _store.reviewByCurrentClientFor(widget.name) != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        title: const Text('Mechanic Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.background,
                child: Icon(Icons.person, color: AppColors.textGrey, size: 36),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  const Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGrey),
                      SizedBox(width: 2),
                      Text('Puerto Princesa City', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              _StatBox(value: '536', label: 'Jobs Done'),
              _StatBox(value: '4.8', label: 'Ratings'),
              _StatBox(value: '9yr', label: 'Experience'),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Certifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const _CertificationRow(label: 'NC II'),
          const SizedBox(height: 6),
          const _CertificationRow(label: 'Related Certificates'),
          const SizedBox(height: 20),
          const Text('Review Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          RatingSummaryBars(
            average: reviews.isEmpty ? 4.8 : average,
            distribution: reviews.isEmpty ? const {5: 0.8, 4: 0.15, 3: 0.05, 2: 0, 1: 0} : distribution,
            reviewCount: reviews.isEmpty ? 1 : reviews.length,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openReviewDialog,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(alreadyReviewed ? 'Edit your review' : 'Write a review'),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Reviews', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            const _ReviewCard(
              name: 'Uncle Bob',
              timeAgo: '3 years ago',
              rating: 4,
              comment:
                  'High quality products and personnel are very accommodating! A fashion store for all male and female moto drivers.',
              helpful: 100,
            )
          else
            ...reviews.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReviewCard(
                    name: r.clientName,
                    timeAgo: _timeAgo(r.date),
                    rating: r.rating,
                    comment: r.comment.isEmpty ? '(No comment left)' : r.comment,
                    helpful: r.helpful,
                  ),
                )),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

class _CertificationRow extends StatelessWidget {
  final String label;
  const _CertificationRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: AppColors.green, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
          child: const Text('View', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String timeAgo;
  final int rating;
  final String comment;
  final int helpful;

  const _ReviewCard({
    required this.name,
    required this.timeAgo,
    required this.rating,
    required this.comment,
    required this.helpful,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderGrey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                  radius: 16, backgroundColor: AppColors.background, child: Icon(Icons.person, size: 18, color: AppColors.textGrey)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(timeAgo, style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (i) => Icon(i < rating ? Icons.star : Icons.star_border, color: AppColors.yellow, size: 14),
            ),
          ),
          const SizedBox(height: 8),
          Text(comment, style: const TextStyle(fontSize: 12, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Text('$helpful', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
            ],
          ),
        ],
      ),
    );
  }
}