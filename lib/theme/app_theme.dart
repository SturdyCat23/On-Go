import 'package:flutter/material.dart';
import 'package:on_go_design/on_go_design.dart';

/// The design system itself — the palettes, the theme registry, the tokens and
/// [ThemeController] — lives in `package:on_go_design`, shared with the admin
/// console website so both front ends are the same theme system rather than
/// two that resemble each other.
///
/// Re-exported here so every screen keeps importing one file, exactly as
/// before.
export 'package:on_go_design/on_go_design.dart';

export 'auth_background_controller.dart';

/// The responsive layout model — `context.layout`, [ResponsiveBody] and the
/// rest. Exported here so a screen that already imports this file gets it
/// without another import.
export 'app_layout.dart';

/// The mobile app's [ThemeData].
///
/// This is the half the app owns: the colours are shared, the density is not.
/// A phone gets full-width pill buttons and 48-point targets because it is
/// tapped at arm's length; the console builds its own [ThemeData] from the
/// same palettes for a mouse. See `on_go_console/lib/src/theme/console_theme.dart`.
class AppTheme {
  /// The tint to multiply the whole app by for a Warm Filter level.
  ///
  /// Kept here as the app's entry point into the shared implementation, which
  /// the console uses too — the filter has to behave identically on both.
  static Color? warmFilterTint(double level) => AppWarmFilter.tintFor(level);

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
        fontFamily: AppTextStyles.fontFamily,
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
            borderRadius: AppOutlinedContainers.field.borderRadius,
            borderSide: BorderSide(color: c.textmedium.withValues(alpha: 0.3), width: AppBorders.thin),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppOutlinedContainers.field.borderRadius,
            borderSide: BorderSide(color: c.textmedium.withValues(alpha: 0.3), width: AppBorders.thin),
          ),
          // A focused field steps up to the 2px regular border weight.
          focusedBorder: OutlineInputBorder(
            borderRadius: AppOutlinedContainers.field.borderRadius,
            borderSide: BorderSide(color: c.textdark, width: AppBorders.regular),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppOutlinedContainers.field.borderRadius,
            borderSide: BorderSide(color: c.error, width: AppBorders.thin),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppOutlinedContainers.field.borderRadius,
            borderSide: BorderSide(color: c.error, width: AppBorders.regular),
          ),
          hintStyle: TextStyle(
            color: c.textmedium,
            fontSize: 14,
          ),
        ),
        // Sizes, weights and typeface come from the UI Style system; the two
        // colours come from the palette. Anything already reading
        // `Theme.of(context).textTheme` therefore follows a change made in
        // `ui_text_styles.dart` without being touched.
        //
        // The scale is fixed at 1 here: a phone is the size these numbers
        // were written for. A screen that wants live scaling across a tablet
        // uses `AppText.body(context)` directly.
        textTheme: AppText.textTheme(
          color: c.textdark,
          mutedColor: c.textmedium,
        ),
        // Shapes below come from the UI Style system; every colour still
        // comes from the palette. Changing a radius in
        // `ui_container_styles.dart` reaches all of these.
        cardTheme: CardThemeData(
          elevation: AppElevation.raised,
          color: c.background,
          shape: AppFilledContainers.surface.shape(),
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
          shape: AppFilledContainers.dialog.shape(),
          elevation: AppElevation.modal,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          shape: RoundedRectangleBorder(borderRadius: AppFilledContainers.sheetTopRadius),
          elevation: AppElevation.modal,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: AppFilledContainers.overlay.shape(),
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
        // Every Switch in the app, in every shell: an outlined pill with a
        // solid circle inside — textmedium when off, primary when on. Set
        // here rather than screen by screen so a toggle anywhere (settings,
        // forms, dialogs, management screens) looks identical without
        // repeating the colors, and any new one is styled by default.
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return c.textmedium.withValues(alpha: 0.3);
            }
            if (states.contains(WidgetState.selected)) return c.primary;
            return c.textmedium.withValues(alpha: 0.55);
          }),
          // No fill in either state — the pill reads as an outline over
          // whatever it sits on, so it looks right on cards and dialogs as
          // well as on the page background.
          trackColor: const WidgetStatePropertyAll(Colors.transparent),
          trackOutlineColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return c.textmedium.withValues(alpha: 0.3);
            }
            if (states.contains(WidgetState.selected)) return c.primary;
            return c.textmedium;
          }),
          // Material 3 drops the outline once a switch is on, because its
          // track is normally filled. Ours never is, so the outline has to be
          // held at the same weight in both states.
          trackOutlineWidth: const WidgetStatePropertyAll(AppBorders.regular),
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
