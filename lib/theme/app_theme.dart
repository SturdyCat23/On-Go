import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'theme_controller.dart';

export 'app_palette.dart';
export 'theme_controller.dart';

class AppColors {

  // Theme palette colors — use these for all surfaces, borders, dividers and text.
  //
  // These forward to whichever palette the user picked in Settings > Themes
  // (see [ThemeController]). They are getters rather than constants so a theme
  // change reaches every screen; that also means they can't be used inside
  // `const` expressions.

  // Primary and secondary colors
  static Color get primary => _palette.primary;
  static Color get primarydark => _palette.primarydark;

  // Background and surface colors
  static Color get background => _palette.background;
  static Color get surface => _palette.surface;

  // Text colors
  static Color get textdark => _palette.textdark;
  static Color get textmedium => _palette.textmedium;
  static Color get textlight => _palette.textlight;

  // Utility colors for specific use cases
  static Color get info => _palette.info;
  static Color get success => _palette.success;
  static Color get warning => _palette.warning;
  static Color get error => _palette.error;

  static AppPalette get _palette => ThemeController.instance.palette;
}

class AppDurations {
  static const Duration snackBar = Duration(seconds: 1);
}

class AppTheme {
  /// The [ThemeData] for the currently selected theme.
  static ThemeData get theme => themeFor(ThemeController.instance.selected);

  /// Builds the [ThemeData] for [option]. Every theme goes through here, so a
  /// new entry in [AppThemes.all] is styled without any extra work.
  static ThemeData themeFor(AppThemeOption option) {
    final c = option.palette;
    final colorScheme = option.isDark
        ? ColorScheme.dark(
            primary: c.textdark,
            secondary: c.primary,
            surface: c.background,
          )
        : ColorScheme.light(
            primary: c.textdark,
            secondary: c.primary,
            surface: c.background,
          );

    return ThemeData(
        brightness: option.isDark ? Brightness.dark : Brightness.light,
        primaryColor: c.primary,
        scaffoldBackgroundColor: c.background,
        fontFamily: 'Roboto',
        colorScheme: colorScheme,
        appBarTheme: AppBarTheme(
          backgroundColor: c.primary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            // textlight is the 'on primary' color, so app bar text stays readable
            // on dark palettes too.
            color: c.textlight,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: c.textlight),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: c.background,
          selectedItemColor: c.primary,
          unselectedItemColor: c.textmedium,
          selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: c.textlight,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.25,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: c.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: c.textmedium.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: c.textmedium.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: c.textdark, width: 1.5),
          ),
          hintStyle: TextStyle(
            color: c.textmedium,
            fontSize: 14,
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.textdark),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textdark),
          bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textdark),
          bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: c.textmedium),
          bodySmall: TextStyle(fontSize: 12, color: c.textmedium),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          color: c.background,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: EdgeInsets.zero,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: c.primary,
          foregroundColor: c.textlight,
        ),
        dividerTheme: DividerThemeData(color: c.textmedium.withValues(alpha: 0.3), thickness: 1),
      );
  }
}
