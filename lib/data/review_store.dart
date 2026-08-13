import 'package:flutter/foundation.dart';

class MechanicReview {
  final String id;
  final String clientName;
  final String mechanicName;
  int rating;
  String comment;
  DateTime date;
  int helpful;

  MechanicReview({
    required this.id,
    required this.clientName,
    required this.mechanicName,
    required this.rating,
    required this.comment,
    required this.date,
    this.helpful = 0,
  });
}

/// Singleton in-memory store for mechanic reviews left by clients.
/// Enforces one review per client per mechanic — submitting again edits
/// the existing review instead of creating a duplicate.
class ReviewStore extends ChangeNotifier {
  ReviewStore._internal() {
    _seed();
  }
  static final ReviewStore instance = ReviewStore._internal();

  // Todo: replace with the logged-in client's real name/id once auth exists.
  static const currentClientName = 'Uncle Bob';

  final List<MechanicReview> _reviews = [];

  List<MechanicReview> reviewsFor(String mechanicName) =>
      _reviews.where((r) => r.mechanicName == mechanicName).toList().reversed.toList();

  MechanicReview? reviewByCurrentClientFor(String mechanicName) {
    final match = _reviews.where((r) => r.mechanicName == mechanicName && r.clientName == currentClientName);
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

  /// Adds a new review, or updates the current client's existing review for
  /// this mechanic if one already exists (one review per client, enforced).
  void submitReview({
    required String mechanicName,
    required int rating,
    required String comment,
  }) {
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

  void _seed() {
    _reviews.add(MechanicReview(
      id: 'rev_seed_001',
      clientName: 'Uncle Bob',
      mechanicName: 'Juan Dela Cruz',
      rating: 4,
      comment:
          'High quality products and personnel are very accommodating! A fashion store for all male and female moto drivers.',
      date: DateTime.now().subtract(const Duration(days: 365 * 3)),
      helpful: 100,
    ));
  }
}