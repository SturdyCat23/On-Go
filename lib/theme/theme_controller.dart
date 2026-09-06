import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_palette.dart';

/// Holds the theme the user picked and persists it across restarts.
///
/// Follows the same singleton-[ChangeNotifier] pattern as the stores in
/// `lib/data/`: screens read `ThemeController.instance` directly and listen to
/// it when they need to rebuild. `AppColors` reads its colors from here, so
/// every screen picks up a new theme without changing how it reads colors.
///
/// The selection is stored in shared_preferences (already a dependency, see
/// `pubspec.yaml`) under [_prefsKey].
class ThemeController extends ChangeNotifier {
  ThemeController._internal();
  static final ThemeController instance = ThemeController._internal();

  static const String _prefsKey = 'app_theme_id';

  AppThemeOption _selected = AppThemes.byId(AppThemes.defaultId);

  /// The active theme option (Default until [load] finds a saved one).
  AppThemeOption get selected => _selected;

  /// Id of the active theme — what the Themes screen ticks.
  String get selectedId => _selected.id;

  /// The colors every screen draws with, via `AppColors`.
  AppPalette get palette => _selected.palette;

  /// Reads the saved theme. Safe to call before `runApp`; a storage failure
  /// just leaves the Default theme in place rather than blocking startup.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apply(AppThemes.byId(prefs.getString(_prefsKey)));
    } catch (_) {
      // No stored preference available — keep the Default theme.
    }
  }

  /// Switches to the theme registered under [id] and remembers the choice.
  /// An unknown id falls back to the Default theme.
  Future<void> select(String id) async {
    final option = AppThemes.byId(id);
    if (option.id == _selected.id) return;
    _apply(option);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, option.id);
    } catch (_) {
      // Selection still applies for this session even if it can't be saved.
    }
  }

  void _apply(AppThemeOption option) {
    if (option.id == _selected.id) return;
    _selected = option;
    notifyListeners();
  }
}
