import 'package:flutter/foundation.dart';
import 'app_session.dart';
import 'client_account_store.dart';

class MechanicReview {
  final String id;
  final String clientName;
  final String mechanicName;
  int rating;
  String comment;
  DateTime date;
  final Set<String> likedBy;

  MechanicReview({
    required this.id,
    required this.clientName,
    required this.mechanicName,
    required this.rating,
    required this.comment,
    required this.date,
    Set<String>? likedBy,
  }) : likedBy = likedBy ?? <String>{};

  int get helpfulCount => likedBy.length;
  bool likedByViewer(String? viewerId) => viewerId != null && likedBy.contains(viewerId);
}

/// Singleton in-memory store for mechanic reviews left by clients.
///
/// WRITING is CLIENT-ONLY, enforced at runtime: [submitReview] checks
/// [AppSession.instance.currentRole] and throws if called while anything
/// other than the Client UI is the active shell — not just "no write-review
/// button in the Mechanic UI." Mechanics (and clients) can freely READ via
/// [reviewsFor] / [averageRatingFor] / [ratingDistributionFor], and both can
/// mark a review helpful via [toggleHelpful] — liking isn't authorship, so
/// it isn't role-gated.
///
/// Enforces one review per client per mechanic — submitting again edits
/// the existing review instead of creating a duplicate.
class ReviewStore extends ChangeNotifier {
  ReviewStore._internal() {
    _seed();
  }
  static final ReviewStore instance = ReviewStore._internal();

  /// The single source of truth for "who is the client" when writing/owning
  /// a review — pulled live from ClientAccountStore so demo/registered
  /// clients are attributed correctly instead of a hardcoded placeholder
  /// name that never matched who was actually signed in.
  static String get currentClientName {
    final name = ClientAccountStore.instance.name;
    return name.isEmpty ? 'Client' : name;
  }

  final List<MechanicReview> _reviews = [];

  List<MechanicReview> reviewsFor(String mechanicName) =>
      _reviews.where((r) => r.mechanicName == mechanicName).toList().reversed.toList();

  MechanicReview? reviewByCurrentClientFor(String mechanicName) {
    final match = _reviews.where((r) => r.mechanicName == mechanicName && r.clientName == currentClientName);
    return match.isEmpty ? null : match.first;
  }

  MechanicReview? reviewById(String reviewId) {
    final match = _reviews.where((r) => r.id == reviewId);
    return match.isEmpty ? null : match.first;
  }

  double averageRatingFor(String mechanicName) {
    final list = reviewsFor(mechanicName);
    if (list.isEmpty) return 0;
    return list.map((r) => r.rating).reduce((a, b) => a + b) / list.length;
  }

  Map<int, double> ratingDistributionFor(String mechanicName) {
    final list = reviewsFor(mechanicName);
    if (list.isEmpty) return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    final counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in list) {
      counts[r.rating] = (counts[r.rating] ?? 0) + 1;
    }
    return counts.map((star, count) => MapEntry(star, count / list.length));
  }

  /// CLIENT-ONLY. Throws [StateError] if the active shell isn't the Client
  /// UI. Mechanics have no path to this method at all in their screens —
  /// this is the backstop in case anything ever tries to call it anyway.
  void submitReview({
    required String mechanicName,
    required int rating,
    required String comment,
  }) {
    if (AppSession.instance.currentRole != AppRole.client) {
      throw StateError('Only the Client UI can submit reviews. Mechanics can view reviews only.');
    }

    final existing = reviewByCurrentClientFor(mechanicName);
    if (existing != null) {
      existing.rating = rating;
      existing.comment = comment;
      existing.date = DateTime.now();
    } else {
      _reviews.add(MechanicReview(
        id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
        clientName: currentClientName,
        mechanicName: mechanicName,
        rating: rating,
        comment: comment,
        date: DateTime.now(),
      ));
    }
    notifyListeners();
  }

  /// Toggles "helpful" on a review for the current viewer (client OR
  /// mechanic — liking is a read-side interaction, not authorship, so it's
  /// not role-gated the way [submitReview] is). No-op if there's no active
  /// viewer identity yet.
  void toggleHelpful(String reviewId) {
    final viewerId = AppSession.instance.currentViewerName;
    if (viewerId == null) return;
    final review = reviewById(reviewId);
    if (review == null) return;

    if (review.likedBy.contains(viewerId)) {
      review.likedBy.remove(viewerId);
    } else {
      review.likedBy.add(viewerId);
    }
    notifyListeners();
  }

    void _seed() {
    // Intentionally empty — reviews only ever come from real clients via
    // submitReview now. A hardcoded seed review here was showing up as a
    // false "already reviewed" state whenever viewed from a fresh session.
  }
}