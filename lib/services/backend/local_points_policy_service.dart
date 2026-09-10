import 'dart:async';

import 'package:on_go_shared/on_go_shared.dart';

/// The mobile app's read-only end of the points rules.
///
/// The rates are set in the admin console's Points Modifier; this app only
/// obeys them. Until the backend exists there is nothing to deliver them, so
/// [fetch] and [watch] report [PointsPolicy.defaults] — the same honest gap
/// [LocalAppearanceService] has, and it closes the same way: the HTTP
/// implementation replaces this one and every calculation picks up the
/// admin's numbers without a screen changing.
///
/// [update] refuses. Configuring the rules is a console action, and a phone
/// deciding what its own points are worth would defeat the point of having
/// them configured centrally.
class LocalPointsPolicyService implements PointsPolicyApi {
  LocalPointsPolicyService({PointsPolicy? policy})
      : _policy = policy ?? PointsPolicy.defaults;

  final PointsPolicy _policy;

  @override
  Future<PointsPolicy> fetch() async => _policy;

  @override
  Stream<PointsPolicy> watch() {
    late StreamController<PointsPolicy> controller;
    controller = StreamController<PointsPolicy>.broadcast(
      onListen: () => controller.add(_policy),
    );
    return controller.stream;
  }

  @override
  Future<PointsPolicy> update(PointsPolicy policy) {
    throw const ApiException(
      ApiErrorKind.forbidden,
      'Points rules are configured in the On Go admin console.',
    );
  }
}
