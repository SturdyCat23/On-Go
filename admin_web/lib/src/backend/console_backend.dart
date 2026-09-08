import 'package:on_go_shared/on_go_shared.dart';

import 'local/local_appearance_service.dart';
import 'local/local_console_auth_service.dart';
import 'local/local_moderator_directory_service.dart';
import 'local/local_revenue_service.dart';
import 'local/local_verification_service.dart';

export 'package:on_go_shared/on_go_shared.dart';

export 'local/local_appearance_service.dart';
export 'local/local_moderator_directory_service.dart';
export 'local/local_verification_service.dart';

/// Every call this console makes that will one day leave the browser.
///
/// The mirror of `lib/services/backend/mobile_backend.dart` in the mobile app.
/// The two applications are separate front ends over one system, and this is
/// where the console reaches the parts of that system the phone owns — a
/// mechanic's registration, a payment that completed — and where it writes the
/// parts the phone reads back.
///
/// Today the interfaces are backed by local, in-browser implementations, so
/// every screen is real and every rule is enforced; what they have no way to do
/// is talk to the other application. When the backend exists, [configure]
/// swaps in HTTP-backed implementations at startup and not one screen changes:
/// they already await Futures and build from Streams.
class ConsoleBackend {
  ConsoleBackend._({
    required this.auth,
    required this.verification,
    required this.moderators,
    required this.revenue,
    required this.appearance,
  });

  /// Builds the default, local-only backend. Everything shares one directory
  /// instance, because deciding a request has to be able to credit the
  /// moderator who decided it.
  factory ConsoleBackend._local() {
    final directory = LocalModeratorDirectoryService();
    return ConsoleBackend._(
      auth: LocalConsoleAuthService(directory),
      verification: LocalVerificationService(directory),
      moderators: directory,
      revenue: LocalRevenueService(),
      appearance: LocalAppearanceService(),
    );
  }

  static ConsoleBackend _instance = ConsoleBackend._local();

  static ConsoleBackend get instance => _instance;

  /// Who is signed in to the console.
  final AuthApi auth;

  /// The moderation queue — filed by the mobile app, decided here.
  final AccountVerificationApi verification;

  /// The moderator roster and its audit trail.
  final ModeratorDirectoryApi moderators;

  /// Platform revenue — reported by the mobile app, read here.
  final PlatformRevenueApi revenue;

  /// Branding this console publishes for the mobile app.
  final PlatformAppearanceApi appearance;

  /// The local moderation service, when that is what is installed.
  ///
  /// A handful of console screens need things that are genuinely not API
  /// operations — the unread count behind the notification bell, the bytes of
  /// a photo that has nowhere to be uploaded to. Reaching them through a
  /// nullable accessor keeps those screens honest: they degrade to the plain
  /// API rather than assuming the local implementation is there.
  LocalVerificationService? get localVerification =>
      verification is LocalVerificationService ? verification as LocalVerificationService : null;

  LocalModeratorDirectoryService? get localModerators => moderators is LocalModeratorDirectoryService
      ? moderators as LocalModeratorDirectoryService
      : null;

  LocalAppearanceService? get localAppearance =>
      appearance is LocalAppearanceService ? appearance as LocalAppearanceService : null;

  /// Replaces some or all of the implementations. Call it once, before
  /// `runApp`, when the API client arrives; each argument left null keeps the
  /// local implementation it already had.
  static void configure({
    AuthApi? auth,
    AccountVerificationApi? verification,
    ModeratorDirectoryApi? moderators,
    PlatformRevenueApi? revenue,
    PlatformAppearanceApi? appearance,
  }) {
    _instance = ConsoleBackend._(
      auth: auth ?? _instance.auth,
      verification: verification ?? _instance.verification,
      moderators: moderators ?? _instance.moderators,
      revenue: revenue ?? _instance.revenue,
      appearance: appearance ?? _instance.appearance,
    );
  }
}
