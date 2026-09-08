import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the background photo an admin published for the Sign In and Welcome
/// screens, and remembers it across restarts.
///
/// The photo is chosen in the On Go admin console, a separate web application
/// — this app only paints it. [setPhoto] and [removePhoto] are therefore the
/// *inbound* side of that: the sink a fetched background is written to, called
/// by whatever implements `PlatformAppearanceApi` once the backend exists
/// (today that is `LocalAppearanceService`, which has nothing to fetch). No
/// mobile screen calls them, and none should — a phone setting the platform's
/// branding is exactly what moving Admin out was meant to stop.
///
/// Same singleton-[ChangeNotifier] shape as [ThemeController]: screens read
/// `AuthBackgroundController.instance` and listen to it when they need to
/// repaint. While [photoPath] is null both screens paint the theme's
/// background color, so removing the photo reverts them on its own.
///
/// The picked file is copied into the app's documents directory — the path
/// `image_picker` hands back points at a cache the OS is free to clear. Only
/// the file *name* is stored in shared_preferences (under [_prefsKey]) because
/// the documents directory itself can move between installs.
class AuthBackgroundController extends ChangeNotifier {
  AuthBackgroundController._internal();
  static final AuthBackgroundController instance = AuthBackgroundController._internal();

  static const String _prefsKey = 'auth_background_photo';
  static const String _filePrefix = 'auth_background_';

  String? _photoPath;

  /// Absolute path of the uploaded background, or null when none is set.
  String? get photoPath => _photoPath;

  /// Whether the Sign In and Welcome screens show a photo instead of a color.
  bool get hasPhoto => _photoPath != null;

  /// Restores the saved background. Safe to call before `runApp`; a storage
  /// failure just leaves the default background color in place rather than
  /// blocking startup.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_prefsKey);
      if (name == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}${Platform.pathSeparator}$name';
      if (await File(path).exists()) {
        _photoPath = path;
        notifyListeners();
      } else {
        // The file is gone (cleared storage, reinstall). Forget it so the
        // screens fall back to the background color.
        await prefs.remove(_prefsKey);
      }
    } catch (_) {
      // No stored background available — keep the default background color.
    }
  }

  /// Copies the photo at [sourcePath] in as the new background.
  /// Returns false when the file could not be stored, leaving the current
  /// background untouched.
  Future<bool> setPhoto(String sourcePath) async {
    final String target;
    final String name;
    try {
      final dir = await getApplicationDocumentsDirectory();
      // A fresh name every upload: Flutter caches decoded images by file path,
      // so reusing one name would keep painting the previous photo.
      name = '$_filePrefix${DateTime.now().millisecondsSinceEpoch}${_extensionOf(sourcePath)}';
      target = '${dir.path}${Platform.pathSeparator}$name';
      await File(sourcePath).copy(target);
    } catch (_) {
      return false;
    }

    final previous = _photoPath;
    _photoPath = target;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, name);
    } catch (_) {
      // The photo still applies for this session even if it can't be saved.
    }
    await _deleteQuietly(previous);
    return true;
  }

  /// Drops the uploaded photo, so both screens go back to the theme's
  /// background color.
  Future<void> removePhoto() async {
    if (_photoPath == null) return;

    final previous = _photoPath;
    _photoPath = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {
      // Removal still applies for this session even if it can't be saved.
    }
    await _deleteQuietly(previous);
  }

  /// The file extension of [path] (including the dot), or `.jpg` when it has
  /// none — the copy keeps the original format so decoding still works.
  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    final slash = path.lastIndexOf(Platform.pathSeparator);
    if (dot <= slash + 1 || dot == path.length - 1) return '.jpg';
    return path.substring(dot);
  }

  Future<void> _deleteQuietly(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A leftover file is harmless; nothing reads it once it's forgotten.
    }
  }
}
