import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/app_widgets.dart';
import '../../../../widgets/common_widgets.dart';

class MechanicProfileScreen extends StatelessWidget {
  const MechanicProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Juan Dela Cruz', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGrey),
                      const SizedBox(width: 2),
                      Text('Puerto Princesa City', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textGrey)),
                    ],
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Edit'),
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
        const RatingSummaryBars(
          average: 4.8,
          distribution: {5: 0.8, 4: 0.15, 3: 0.05, 2: 0, 1: 0},
          reviewCount: 1,
        ),
        const SizedBox(height: 24),
        const Text('Reviews', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        const Row(
          children: [
            _FilterChip(label: 'All', selected: true),
            SizedBox(width: 6),
            _FilterChip(label: 'Rating', selected: false),
            SizedBox(width: 6),
            _FilterChip(label: 'Most Relevant', selected: false),
          ],
        ),
        const SizedBox(height: 12),
        const _ReviewCard(
          name: 'Uncle Bob',
          timeAgo: '3 years ago',
          rating: 4,
          comment:
              'High quality products and personnel are very accommodating! A fashion store for all male and female moto drivers.',
          helpful: 100,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {},
            child: const Text('See all reviews',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
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
      child: AppCard(
        color: AppColors.background,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, color: AppColors.textGrey)),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _FilterChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.white,
        border: Border.all(color: selected ? AppColors.primary : AppColors.borderGrey),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.primary : AppColors.textGrey,
        ),
      ),
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
    return AppCard(
      padding: const EdgeInsets.all(14),
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
              Text('$helpful', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}