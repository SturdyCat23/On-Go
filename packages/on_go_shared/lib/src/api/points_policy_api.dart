import '../models/points_policy.dart';

/// The points rules: set in the console, obeyed by the mobile app.
///
/// The same console-owns-it, phone-reads-it shape as [PlatformAppearanceApi].
/// An admin changes what a job is worth on a website, and a phone that has
/// never met that website has to award the new amount on its next payment.
///
/// Nothing in the transaction logic may carry its own rates: a client's
/// points and a mechanic's are both worked out from whatever [fetch] and
/// [watch] report, so changing a number here changes every calculation.
abstract interface class PointsPolicyApi {
  /// The rules in force right now.
  Future<PointsPolicy> fetch();

  /// A live view, so a phone with the app open picks up a change the admin
  /// makes without being restarted.
  Stream<PointsPolicy> watch();

  /// Replaces the rules. Console only, and only for an admin — the mobile
  /// implementation refuses.
  Future<PointsPolicy> update(PointsPolicy policy);
}
