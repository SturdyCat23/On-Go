import '../models/platform_appearance.dart';

/// The mobile app's Sign In / Welcome background, set from the console.
///
/// Console → mobile, and the clearest example of why these two apps need an
/// API between them: an admin uploads a photo on a website and a phone that
/// has never met that website has to start painting it.
abstract interface class PlatformAppearanceApi {
  /// What the mobile app should be painting right now.
  Future<PlatformAppearance> fetch();

  /// A live view, so the mobile app repaints when the console publishes.
  Stream<PlatformAppearance> watch();

  /// Publishes a new background. Console only, and only for an admin or a
  /// moderator holding `canChangeBackground`.
  ///
  /// [bytes] is the image itself and [fileName] names its format; the
  /// implementation decides where the bytes end up and returns the appearance
  /// that resulted, with [PlatformAppearance.authBackgroundUrl] pointing at
  /// wherever that is.
  Future<PlatformAppearance> publishBackground({
    required List<int> bytes,
    required String fileName,
  });

  /// Clears the background, sending both screens back to the theme's
  /// background color.
  Future<PlatformAppearance> clearBackground();
}
