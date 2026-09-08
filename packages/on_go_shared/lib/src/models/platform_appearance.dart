import 'json.dart';

/// Branding the console sets and the mobile app renders.
///
/// One direction only: written from the Admin / Moderator console, read by the
/// mobile app's Sign In and Welcome screens. Until the backend exists each
/// side keeps its own copy — the console stages an upload, the mobile app
/// paints whatever it last cached — and neither pretends the other has seen it.
class PlatformAppearance {
  /// Where the Sign In / Welcome background photo lives, or null when both
  /// screens should fall back to the theme's background color. Opaque: a local
  /// file path today, an https URL once uploads are hosted.
  final String? authBackgroundUrl;

  /// When the console last changed it. Lets the mobile app skip a re-download
  /// it already has, and lets the console show "applied 3 days ago".
  final DateTime? updatedAt;

  const PlatformAppearance({this.authBackgroundUrl, this.updatedAt});

  /// No photo set: both screens use the theme's background color.
  static const PlatformAppearance none = PlatformAppearance();

  bool get hasBackground => authBackgroundUrl != null;

  Map<String, dynamic> toJson() => {
        'authBackgroundUrl': authBackgroundUrl,
        'updatedAt': writeDateOrNull(updatedAt),
      };

  factory PlatformAppearance.fromJson(Map<String, dynamic> json) => PlatformAppearance(
        authBackgroundUrl: readStringOrNull(json['authBackgroundUrl']),
        updatedAt: readDateOrNull(json['updatedAt']),
      );
}
