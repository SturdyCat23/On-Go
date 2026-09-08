import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'theme_controller.dart';

/// The colours every screen in the product draws with, on either front end.
///
/// These forward to whichever palette is currently in force (see
/// [ThemeController]). They are getters rather than constants so a theme change
/// reaches every screen; that also means they cannot be used inside `const`
/// expressions.
///
/// The names are semantic, not literal — in a dark palette [textdark] is a
/// *light* colour, because its job is "high-emphasis text drawn on
/// [background] / [surface]", not "a dark colour".
class AppColors {
  AppColors._();

  /// Brand colour: app bars, the console sidebar, primary buttons, accents.
  static Color get primary => _palette.primary;

  /// A deeper shade of [primary] for pressed states, gradients and headers.
  static Color get primarydark => _palette.primarydark;

  /// The scaffold background behind cards and lists.
  static Color get background => _palette.background;

  /// Cards, sheets and other raised surfaces sitting on [background].
  static Color get surface => _palette.surface;

  /// High-emphasis text/icons on [background] and [surface].
  static Color get textdark => _palette.textdark;

  /// Secondary text, hints, dividers and disabled states.
  static Color get textmedium => _palette.textmedium;

  /// Text/icons drawn on top of [primary].
  static Color get textlight => _palette.textlight;

  /// Informational accents.
  static Color get info => _palette.info;

  /// Positive/approved accents.
  static Color get success => _palette.success;

  /// Caution/pending accents.
  static Color get warning => _palette.warning;

  /// Failure/rejected accents.
  static Color get error => _palette.error;

  /// The palette in force right now.
  static AppPalette get palette => _palette;

  /// Whether a dark palette is in force, for the handful of places that need
  /// to know rather than just reading a colour.
  static bool get isDark => ThemeController.instance.selected.isDark;

  static AppPalette get _palette => ThemeController.instance.palette;
}

/// Timings shared by both front ends.
class AppDurations {
  AppDurations._();

  /// How long a toast stays up.
  static const Duration snackBar = Duration(seconds: 1);
}

/// The Warm Filter's tint.
///
/// Applied by each app at the very top of its widget tree, so one compositing
/// pass warms everything below it — routes, sheets and dialogs alike.
class AppWarmFilter {
  AppWarmFilter._();

  /// The warmest tint applied, at the top of the range.
  static const Color _warmest = Color(0xFFFFC080);

  /// The tint to multiply the whole UI by for a Warm Filter [level] —
  /// any value in 0..[ThemeController.maxWarmFilter], not just whole ones —
  /// or null at 0 where the filter is
  /// off and the extra compositing layer is not worth paying for.
  ///
  /// Multiplying rather than overlaying is what makes this safe on every
  /// theme: white goes warm, black stays black, so a dark palette gets warmer
  /// without its blacks washing out to orange.
  static Color? tintFor(double level) {
    if (level <= 0) return null;
    final t = (level / ThemeController.maxWarmFilter).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFFFFFFFF), _warmest, t);
  }

  /// Wraps [child] in the current Warm Filter, or returns it untouched when
  /// the filter is off. Both apps call this from their root builder.
  static Widget wrap(double level, Widget child) {
    final tint = tintFor(level);
    if (tint == null) return child;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
      child: child,
    );
  }
}
