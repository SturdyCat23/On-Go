import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/backend/mobile_backend.dart';

/// The points rules, cached on this device.
///
/// [PointsPolicyApi] is asynchronous, as everything crossing to the console
/// must be. Awarding points is not: it happens inside
/// `QuoteNotificationStore.clientConfirmPayment`, which settles a payment in
/// one synchronous step. This store bridges the two — it subscribes once and
/// keeps the latest rules where any screen or calculation can read them
/// straight away.
///
/// It is the ONLY place the mobile app should read rates from. Nothing else
/// carries its own numbers, so an admin changing a rate in the console changes
/// every calculation at once, and does not need each caller updated.
class PointsPolicyStore extends ChangeNotifier {
  PointsPolicyStore._internal();
  static final PointsPolicyStore instance = PointsPolicyStore._internal();

  PointsPolicy _current = PointsPolicy.defaults;
  StreamSubscription<PointsPolicy>? _watch;

  /// The rules in force. [PointsPolicy.defaults] until the first update
  /// arrives — never null, so a payment can always be settled.
  PointsPolicy get current => _current;

  /// Starts following the rules. Safe to call before `runApp`; a failure
  /// leaves the defaults in place rather than blocking startup.
  Future<void> load() async {
    try {
      _apply(await MobileBackend.instance.pointsPolicy.fetch());
      _watch?.cancel();
      _watch = MobileBackend.instance.pointsPolicy.watch().listen(
            _apply,
            onError: (_) {
              // Keep the rules we already have; a dropped stream is not a
              // reason to start awarding different numbers.
            },
          );
    } catch (_) {
      // Defaults stand.
    }
  }

  void _apply(PointsPolicy policy) {
    if (policy == _current) return;
    _current = policy;
    notifyListeners();
  }

  /// Test hook — swaps the rules in without a backend.
  @visibleForTesting
  void debugSet(PointsPolicy policy) => _apply(policy);

  @override
  void dispose() {
    _watch?.cancel();
    super.dispose();
  }
}
