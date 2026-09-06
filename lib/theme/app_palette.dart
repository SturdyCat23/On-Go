import 'package:flutter/material.dart';

/// One complete set of app colors.
///
/// Every theme in [AppThemes.all] supplies the exact same properties, so any
/// screen that reads `AppColors.<name>` keeps working no matter which theme is
/// active. The names are semantic, not literal — in a dark palette [textdark]
/// is a *light* color, because its job is "high-emphasis text drawn on
/// [background] / [surface]", not "a dark color".
@immutable
class AppPalette {
  /// Brand color: app bars, primary buttons, drawer headers, accents.
  final Color primary;

  /// A deeper shade of [primary] for pressed states, gradients and headers.
  final Color primarydark;

  /// The scaffold background behind cards and lists.
  final Color background;

  /// Cards, sheets and other raised surfaces sitting on [background].
  final Color surface;

  /// High-emphasis text/icons on [background] and [surface].
  final Color textdark;

  /// Secondary text, hints, dividers and disabled states.
  final Color textmedium;

  /// Text/icons drawn on top of [primary] (app bar titles, drawer header).
  final Color textlight;

  /// Informational accents.
  final Color info;

  /// Positive/approved accents.
  final Color success;

  /// Caution/pending accents.
  final Color warning;

  /// Failure/rejected accents.
  final Color error;

  const AppPalette({
    required this.primary,
    required this.primarydark,
    required this.background,
    required this.surface,
    required this.textdark,
    required this.textmedium,
    required this.textlight,
    required this.info,
    required this.success,
    required this.warning,
    required this.error,
  });
}

/// A theme the user can pick from the Themes screen.
@immutable
class AppThemeOption {
  /// Stable key persisted to storage — never rename an existing one.
  final String id;

  /// Label shown in the Themes list.
  final String label;

  /// One-line description shown under [label].
  final String description;

  /// The colors this theme applies.
  final AppPalette palette;

  /// Whether [background]/[surface] are dark, so Material picks matching
  /// defaults for things we don't style ourselves (ripples, scrollbars…).
  final bool isDark;

  const AppThemeOption({
    required this.id,
    required this.label,
    required this.description,
    required this.palette,
    this.isDark = false,
  });
}

/// The theme registry.
///
/// To add a theme later: append one [AppThemeOption] to [all] with a new [id]
/// and a full [AppPalette]. Nothing else in the app needs to change — the
/// Themes screen builds itself from this list.
class AppThemes {
  AppThemes._();

  /// Fallback used before storage is read and whenever a saved id is unknown.
  static const String defaultId = 'default';

  static const AppThemeOption _default = AppThemeOption(
    id: defaultId,
    label: 'Default',
    description: 'The original On Go red on a light background.',
    palette: AppPalette(
      primary: Color.fromRGBO(209, 29, 40, 1),
      primarydark: Color.fromARGB(255, 168, 0, 17),
      background: Color.fromARGB(255, 247, 242, 236),
      surface: Color.fromARGB(255, 245, 244, 240),
      textdark: Color.fromARGB(255, 13, 14, 15),
      textmedium: Color.fromARGB(255, 104, 109, 122),
      textlight: Color.fromARGB(255, 255, 251, 248),
      info: Color.fromARGB(255, 102, 155, 188),
      success: Color.fromARGB(255, 118, 151, 77),
      warning: Color.fromARGB(255, 254, 174, 1),
      error: Color.fromRGBO(209, 29, 40, 1),
    ),
  );

  static const AppThemeOption _dark = AppThemeOption(
    id: 'dark',
    label: 'Dark',
    description: 'Low-light palette for night driving and roadside work.',
    isDark: true,
    palette: AppPalette(
      primary: Color.fromARGB(255, 206, 26, 26),
      primarydark: Color.fromARGB(255, 158, 22, 22),
      background: Color.fromARGB(255, 18, 19, 22),
      surface: Color.fromARGB(255, 31, 34, 40),
      textdark: Color.fromARGB(255, 240, 241, 243),
      textmedium: Color.fromARGB(255, 158, 163, 174),
      textlight: Color.fromARGB(255, 248, 249, 250),
      info: Color.fromARGB(255, 96, 165, 250),
      success: Color.fromARGB(255, 52, 199, 89),
      warning: Color.fromARGB(255, 251, 191, 36),
      error: Color.fromARGB(255, 248, 113, 113),
    ),
  );

  static const AppThemeOption _blue = AppThemeOption(
    id: 'blue',
    label: 'Blue',
    description: 'Calm blue accents on a cool light background.',
    palette: AppPalette(
      primary: Color.fromARGB(255, 21, 101, 192),
      primarydark: Color.fromARGB(255, 13, 71, 161),
      background: Color.fromARGB(255, 240, 244, 250),
      surface: Color.fromARGB(255, 255, 255, 255),
      textdark: Color.fromARGB(255, 15, 23, 42),
      textmedium: Color.fromARGB(255, 100, 116, 139),
      textlight: Color.fromARGB(255, 248, 250, 252),
      info: Color.fromARGB(255, 2, 132, 199),
      success: Color.fromARGB(255, 0, 148, 68),
      warning: Color.fromARGB(255, 234, 158, 0),
      error: Color.fromARGB(255, 208, 32, 47),
    ),
  );

  static const AppThemeOption _red = AppThemeOption(
    id: 'red',
    label: 'Red',
    description: 'Deeper crimson with a warm-tinted background.',
    palette: AppPalette(
      primary: Color.fromARGB(255, 155, 17, 30),
      primarydark: Color.fromARGB(255, 109, 9, 19),
      background: Color.fromARGB(255, 250, 243, 243),
      surface: Color.fromARGB(255, 255, 251, 251),
      textdark: Color.fromARGB(255, 32, 16, 18),
      textmedium: Color.fromARGB(255, 122, 100, 103),
      textlight: Color.fromARGB(255, 253, 245, 245),
      info: Color.fromARGB(255, 21, 118, 186),
      success: Color.fromARGB(255, 0, 138, 43),
      warning: Color.fromARGB(255, 219, 145, 0),
      error: Color.fromARGB(255, 198, 24, 24),
    ),
  );

  static const AppThemeOption _ember = AppThemeOption(
    id: 'ember',
    label: 'Ember',
    description: 'Vivid orange on near-black, with warm off-white text.',
    isDark: true,
    palette: AppPalette(
      primary: Color.fromARGB(255, 240, 78, 20),
      primarydark: Color.fromARGB(255, 186, 52, 8),
      background: Color.fromARGB(255, 13, 13, 14),
      surface: Color.fromARGB(255, 28, 28, 31),
      textdark: Color.fromARGB(255, 245, 244, 242),
      textmedium: Color.fromARGB(255, 154, 152, 148),
      textlight: Color.fromARGB(255, 255, 250, 247),
      info: Color.fromARGB(255, 90, 169, 255),
      success: Color.fromARGB(255, 46, 196, 110),
      warning: Color.fromARGB(255, 250, 176, 5),
      error: Color.fromARGB(255, 255, 92, 82),
    ),
  );

  /// Every selectable theme, in the order the Themes screen lists them.
  static const List<AppThemeOption> all = [_default, _dark, _blue, _red, _ember];

  /// The theme registered under [id], or the Default theme if there is none.
  static AppThemeOption byId(String? id) {
    for (final option in all) {
      if (option.id == id) return option;
    }
    return _default;
  }
}
