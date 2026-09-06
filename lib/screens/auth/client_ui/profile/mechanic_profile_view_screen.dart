import 'package:flutter/material.dart';
import '../../../../data/app_session.dart';
import '../../../../data/review_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/app_widgets.dart';
import '../../../../data/quote_store.dart';

enum _ReviewFilter { all, rating, mostRelevant }

class MechanicProfileViewScreen extends StatefulWidget {
  final String name;
  const MechanicProfileViewScreen({super.key, required this.name});

  @override
  State<MechanicProfileViewScreen> createState() => _MechanicProfileViewScreenState();
}

class _MechanicProfileViewScreenState extends State<MechanicProfileViewScreen> {
  final _store = ReviewStore.instance;
  _ReviewFilter _filter = _ReviewFilter.all;

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

  List<MechanicReview> _applyFilter(List<MechanicReview> reviews) {
    final list = [...reviews];
    switch (_filter) {
      case _ReviewFilter.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case _ReviewFilter.mostRelevant:
        list.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
        break;
      case _ReviewFilter.all:
        break; // reviewsFor already returns most-recent-first
    }
    return list;
  }

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

  void _viewCertificate(String label) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_outlined, size: 48, color: AppColors.textdark.withValues(alpha: 0.55)),
                SizedBox(height: 8),
                Text('Certificate preview', style: TextStyle(color: AppColors.textdark.withValues(alpha: 0.55), fontSize: 12)),
              ],
            ),
          ),
        ), // Todo: wire up real certificate image/file preview once documents are hosted
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  /// CLIENT-ONLY write path — the dialog itself is only reachable from this
  /// client-side screen, and ReviewStore.submitReview backstops that at
  /// runtime by throwing if the active shell isn't the Client UI (see its
  /// doc comment). If that ever fires, we surface it instead of crashing.
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return IconButton(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      constraints: const BoxConstraints(),
                      icon: Icon(i < selected ? Icons.star : Icons.star_border, color: AppColors.warning, size: 30),
                      onPressed: () => setDialogState(() => selected = i + 1),
                    );
                  }),
                ),
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
              onPressed: selected == 0 ? null : () => Navigator.pop(ctx, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        _store.submitReview(mechanicName: widget.name, rating: selected, comment: controller.text.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review saved'), duration: AppDurations.snackBar));
      } on StateError catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), duration: AppDurations.snackBar));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _applyFilter(_store.reviewsFor(widget.name));
    final average = _store.averageRatingFor(widget.name);
    final distribution = _store.ratingDistributionFor(widget.name);
    final alreadyReviewed = _store.reviewByCurrentClientFor(widget.name) != null;
    final viewerId = AppSession.instance.currentViewerName;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textmedium,
        title: const Text('Mechanic Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.background,
                child: Icon(Icons.person, color: AppColors.textdark.withValues(alpha: 0.55), size: 36),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: AppColors.textdark.withValues(alpha: 0.55)),
                      SizedBox(width: 2),
                      Text('Puerto Princesa City', style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55))),
                    ],
                  ),
                ],
              ),
            ],
          ),
                        const SizedBox(height: 16),
              Row(
                children: [
                  _StatBox(value: '${QuoteNotificationStore.instance.completedJobsFor(widget.name).length}', label: 'Jobs Done'),
                  _StatBox(value: reviews.isEmpty ? '—' : average.toStringAsFixed(1), label: 'Ratings'),
                  // Todo: no experience-tracking data source yet — left as
                  // a static placeholder, not wired up.
                  const _StatBox(value: '9yr', label: 'Experience'),
                ],
              ),
          const SizedBox(height: 20),
          const Text('Certifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _CertificationRow(label: 'NC II', onView: () => _viewCertificate('NC II')),
          const SizedBox(height: 6),
          _CertificationRow(label: 'Related Certificates', onView: () => _viewCertificate('Related Certificates')),
          const SizedBox(height: 20),
          const Text('Review Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          RatingSummaryBars(
            average: average,
            distribution: distribution,
            reviewCount: reviews.length,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Reviews', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _FilterChip(label: 'All', selected: _filter == _ReviewFilter.all, onTap: () => setState(() => _filter = _ReviewFilter.all)),
              const SizedBox(width: 6),
              _FilterChip(label: 'Rating', selected: _filter == _ReviewFilter.rating, onTap: () => setState(() => _filter = _ReviewFilter.rating)),
              const SizedBox(width: 6),
              _FilterChip(
                  label: 'Most Relevant',
                  selected: _filter == _ReviewFilter.mostRelevant,
                  onTap: () => setState(() => _filter = _ReviewFilter.mostRelevant)),
            ],
          ),
          const SizedBox(height: 12),
                    if (reviews.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No reviews yet.', style: TextStyle(color: AppColors.textdark.withValues(alpha: 0.55), fontSize: 13)),
            )
          else
            ...reviews.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReviewCard(
                    reviewId: r.id,
                    name: r.clientName,
                    timeAgo: _timeAgo(r.date),
                    rating: r.rating,
                    comment: r.comment.isEmpty ? '(No comment left)' : r.comment,
                    helpfulCount: r.helpfulCount,
                    likedByMe: r.likedByViewer(viewerId),
                    onToggleLike: () => _store.toggleHelpful(r.id),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55))),
          ],
        ),
      ),
    );
  }
}

class _CertificationRow extends StatelessWidget {
  final String label;
  final VoidCallback onView;
  const _CertificationRow({required this.label, required this.onView});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: AppColors.success, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        TextButton(
          onPressed: onView,
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
          child: Text('View', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          border: Border.all(color: selected ? AppColors.primary : AppColors.textdark.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.primary : AppColors.textdark.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String reviewId;
  final String name;
  final String timeAgo;
  final int rating;
  final String comment;
  final int helpfulCount;
  final bool likedByMe;
  final VoidCallback? onToggleLike;

  const _ReviewCard({
    required this.reviewId,
    required this.name,
    required this.timeAgo,
    required this.rating,
    required this.comment,
    required this.helpfulCount,
    required this.likedByMe,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.textdark.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                  radius: 16, backgroundColor: AppColors.background, child: Icon(Icons.person, size: 18, color: AppColors.textdark.withValues(alpha: 0.55))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(timeAgo, style: TextStyle(fontSize: 11, color: AppColors.textdark.withValues(alpha: 0.55))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (i) => Icon(i < rating ? Icons.star : Icons.star_border, color: AppColors.warning, size: 14),
            ),
          ),
          const SizedBox(height: 8),
          Text(comment, style: TextStyle(fontSize: 12, color: AppColors.textdark)),
          const SizedBox(height: 8),
          InkWell(
            onTap: onToggleLike,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(likedByMe ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                      size: 14, color: likedByMe ? AppColors.primary : AppColors.textdark.withValues(alpha: 0.55)),
                  const SizedBox(width: 4),
                  Text('$helpfulCount',
                      style: TextStyle(
                          fontSize: 11,
                          color: likedByMe ? AppColors.primary : AppColors.textdark.withValues(alpha: 0.55),
                          fontWeight: likedByMe ? FontWeight.w700 : FontWeight.normal)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}