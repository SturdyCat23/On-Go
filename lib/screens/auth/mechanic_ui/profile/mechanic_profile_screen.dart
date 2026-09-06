import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../data/app_session.dart';
import '../../../../data/mechanic_account_store.dart';
import '../../../../data/moderator_data.dart';
import '../../../../data/quote_store.dart';
import '../../../../data/review_store.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/common_widgets.dart';

enum _ReviewFilter { all, rating, mostRelevant }

class MechanicProfileScreen extends StatefulWidget {
  /// True when pushed as its own route (drawer, leaderboard tap) — wraps
  /// the content in a Scaffold with the standard red app bar. False when
  /// used as a bottom-nav tab body inside MechanicHomeScreen, which already
  /// supplies its own Scaffold/app bar — wrapping again there would nest
  /// Scaffolds and duplicate the app bar.
  final bool standalone;
  const MechanicProfileScreen({super.key, this.standalone = true});

  @override
  State<MechanicProfileScreen> createState() => _MechanicProfileScreenState();
}

class _MechanicProfileScreenState extends State<MechanicProfileScreen> {
  final _reviews = ReviewStore.instance;
  final _account = MechanicAccountStore.instance;
  _ReviewFilter _filter = _ReviewFilter.all;

  @override
  void initState() {
    super.initState();
    _reviews.addListener(_onChange);
    _account.addListener(_onChange);
  }

  @override
  void dispose() {
    _reviews.removeListener(_onChange);
    _account.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  String get _approvalNote {
    if (_account.isDemo) return 'Demo Mode';
    if (!_account.isRegistered) return '';
    switch (_account.status) {
      case ApprovalStatus.pending:
        return 'Pending Approval';
      case ApprovalStatus.rejected:
        return 'Account Rejected';
      case ApprovalStatus.approved:
      default:
        return '';
    }
  }

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
        break;
    }
    return list;
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

  @override
  Widget build(BuildContext context) {
    final myName = _account.name.isEmpty ? 'Mechanic' : _account.name;
    final reviews = _applyFilter(_reviews.reviewsFor(myName));
    final average = _reviews.averageRatingFor(myName);
    final viewerId = AppSession.instance.currentViewerName;
    final approvalNote = _approvalNote;
    final photo = _account.photoPath;

    final content = ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.background,
                        backgroundImage: photo == null
                            ? null
                            : (_account.photoIsNetwork ? NetworkImage(photo) : FileImage(File(photo))) as ImageProvider?,
                        child: photo == null ? Icon(Icons.person, color: AppColors.textdark.withValues(alpha: 0.55), size: 44) : null,
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(myName,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            if (approvalNote.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (approvalNote == 'Account Rejected' ? AppColors.primary : AppColors.warning).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(approvalNote,
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: approvalNote == 'Account Rejected' ? AppColors.primary : AppColors.warning)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: AppColors.textdark.withValues(alpha: 0.55)),
                            const SizedBox(width: 2),
                            Text('Puerto Princesa City', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textdark.withValues(alpha: 0.55))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatBox(value: '${QuoteNotificationStore.instance.completedJobsFor(myName).length}', label: 'Jobs Done'),
                  _StatBox(value: reviews.isEmpty ? '—' : average.toStringAsFixed(1), label: 'Ratings'),
                  // Todo: no experience-tracking data source yet — left as
                  // a static placeholder, not wired up.
                  const _StatBox(value: '9yr', label: 'Experience'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Certifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _CertificationRow(label: 'NC II', onView: () => _viewCertificate('NC II')),
              const SizedBox(height: 6),
              _CertificationRow(label: 'Related Certificates', onView: () => _viewCertificate('Related Certificates')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Reviews', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  if (reviews.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: AppColors.warning),
                        const SizedBox(width: 2),
                        Text(average.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text(' (${reviews.length})', style: TextStyle(fontSize: 12, color: AppColors.textdark.withValues(alpha: 0.55))),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),
              // Mechanics can only ever land here to VIEW and (optionally)
              // mark a review helpful — there is no write/edit path on this
              // screen, and ReviewStore.submitReview would throw at runtime
              // even if something tried to call it from this tree.
              if (reviews.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No reviews yet.', style: TextStyle(color: AppColors.textdark.withValues(alpha: 0.55), fontSize: 13)),
                )
              else
                ...reviews.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ReviewCard(
                        name: r.clientName,
                        timeAgo: _timeAgo(r.date),
                        rating: r.rating,
                        comment: r.comment.isEmpty ? '(No comment left)' : r.comment,
                        helpfulCount: r.helpfulCount,
                        likedByMe: r.likedByViewer(viewerId),
                        onToggleLike: () => _reviews.toggleHelpful(r.id),
                      ),
                    )),
            ],
          ),
        ),
            ],
    );

    if (!widget.standalone) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textmedium,
        title: const Text('Mechanic Profile'),
      ),
      body: content,
    );
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
          border: Border.all(color: AppColors.textdark.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: AppColors.textdark)),
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
          child: Text('View', style: TextStyle(color: AppColors.info, fontSize: 12, fontWeight: FontWeight.w600)),
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
  final String name;
  final String timeAgo;
  final int rating;
  final String comment;
  final int helpfulCount;
  final bool likedByMe;
  final VoidCallback onToggleLike;

  const _ReviewCard({
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
    return Column(
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
    );
  }
}