import 'dart:async';

import 'package:on_go_shared/on_go_shared.dart';

import '../../theme/auth_background_controller.dart';

/// The mobile app's read-only end of the Sign In / Welcome background.
///
/// The photo is chosen in the admin console; this app only paints it. What
/// [fetch] and [watch] report is whatever [AuthBackgroundController] has
/// cached on this device — nothing, until the backend exists to deliver one.
///
/// [publishBackground] and [clearBackground] refuse, because setting the
/// branding is a console action. When the backend lands, the HTTP
/// implementation replaces this one and the fetched photo is handed to
/// [AuthBackgroundController.setPhoto], which is already written to cache a
/// downloaded file and survive restarts.
class LocalAppearanceService implements PlatformAppearanceApi {
  LocalAppearanceService({AuthBackgroundController? controller})
      : _controller = controller ?? AuthBackgroundController.instance;

  final AuthBackgroundController _controller;

  PlatformAppearance get _current =>
      PlatformAppearance(authBackgroundUrl: _controller.photoPath);

  @override
  Future<PlatformAppearance> fetch() async => _current;

  @override
  Stream<PlatformAppearance> watch() {
    late StreamController<PlatformAppearance> controller;
    void emit() => controller.add(_current);

    controller = StreamController<PlatformAppearance>.broadcast(
      onListen: () {
        emit();
        _controller.addListener(emit);
      },
      onCancel: () => _controller.removeListener(emit),
    );
    return controller.stream;
  }

  @override
  Future<PlatformAppearance> publishBackground({
    required List<int> bytes,
    required String fileName,
  }) {
    throw const ApiException(
      ApiErrorKind.forbidden,
      'The Sign In background is published from the On Go admin console.',
    );
  }

  @override
  Future<PlatformAppearance> clearBackground() {
    throw const ApiException(
      ApiErrorKind.forbidden,
      'The Sign In background is published from the On Go admin console.',
    );
  }
}
