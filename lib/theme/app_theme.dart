import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'design_tokens.dart';
import 'theme_controller.dart';

export 'app_palette.dart';
export 'design_tokens.dart';
export 'auth_background_controller.dart';
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
  /// The warmest tint the Warm Filter applies, at the top of its range.
  static const Color _warmestTint = Color(0xFFFFC080);

  /// The tint to multiply the whole app by for a Warm Filter [level]
  /// (0..[ThemeController.maxWarmFilter]), or null at 0 where the filter is
  /// off and the extra compositing layer isn't worth paying for.
  ///
  /// Multiplying rather than overlaying is what makes this safe on every
  /// theme: white goes warm, black stays black, so a dark palette gets warmer
  /// without its blacks washing out to orange.
  static Color? warmFilterTint(int level) {
    if (level <= 0) return null;
    final t = (level / ThemeController.maxWarmFilter).clamp(0.0, 1.0);
    return Color.lerp(const Color(0xFFFFFFFF), _warmestTint, t);
  }

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
        // Buttons are pills — the primary-action shape in the design reference.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: c.textlight,
            minimumSize: const Size(double.infinity, 48),
            shape: AppRadii.pill,
            elevation: AppElevation.flat,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.25,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(shape: AppRadii.pill),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(shape: AppRadii.pill),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: c.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: AppRadii.borderMd,
            borderSide: BorderSide(color: c.textmedium.withValues(alpha: 0.3), width: AppBorders.thin),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderMd,
            borderSide: BorderSide(color: c.textmedium.withValues(alpha: 0.3), width: AppBorders.thin),
          ),
          // A focused field steps up to the 2px regular border weight.
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderMd,
            borderSide: BorderSide(color: c.textdark, width: AppBorders.regular),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderMd,
            borderSide: BorderSide(color: c.error, width: AppBorders.thin),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadii.borderMd,
            borderSide: BorderSide(color: c.error, width: AppBorders.regular),
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
          elevation: AppElevation.raised,
          color: c.background,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.borderLg),
          margin: EdgeInsets.zero,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: c.primary,
          foregroundColor: c.textlight,
        ),
        dividerTheme: DividerThemeData(
          color: c.textmedium.withValues(alpha: 0.3),
          thickness: AppBorders.thin,
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: AppRadii.borderXl),
          elevation: AppElevation.modal,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          shape: RoundedRectangleBorder(borderRadius: AppRadii.sheetTop),
          elevation: AppElevation.modal,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.borderMd),
          elevation: AppElevation.popover,
        ),
        // Badges and filter chips read as pills.
        chipTheme: const ChipThemeData(shape: AppRadii.pill),
        tabBarTheme: TabBarThemeData(
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: c.primary, width: AppBorders.regular),
          ),
          labelColor: c.textdark,
          unselectedLabelColor: c.textmedium,
          dividerColor: c.textmedium.withValues(alpha: 0.2),
        ),
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(borderRadius: AppRadii.borderXs),
        ),
        // Rounded caps on every progress bar, as in the reference.
        progressIndicatorTheme: ProgressIndicatorThemeData(
          borderRadius: AppRadii.borderXs,
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: c.textdark,
            borderRadius: AppRadii.borderSm,
          ),
          textStyle: TextStyle(color: c.surface, fontSize: 12),
        ),
      );
  }
}
