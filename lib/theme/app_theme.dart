import 'package:flutter/material.dart';

/// The whole palette: four base colors and four status colors, and nothing
/// else. Every surface, border, divider and piece of text in the app is one
/// of the four base colors (at whatever opacity the spot calls for) — there
/// are deliberately no separate white / surface / text / border shades to
/// drift apart from each other.
class AppColors {
  /// The brand red: primary actions, accents, and anything that reads as
  /// "ONGO" or "urgent".
  static const Color primary = Color.fromARGB(255, 209, 0, 0);

  /// The app background, and every light surface sitting on it — cards,
  /// sheets, inputs, and text or icons placed on a dark or colored fill.
  static const Color background = Color(0xFFF7F0F0);

  /// Secondary text, borders, dividers, disabled controls and other muted UI.
  static const Color grey = Color.fromARGB(255, 145, 145, 150);

  /// Primary text and dark UI elements.
  static const Color dark = Color(0xFF1E1E1F);

  // Status colors — use these only where that status is what's being said.
  static const Color blue = Color.fromARGB(255, 42, 33, 218);
  static const Color green = Color(0xFF11B848);
  static const Color yellow = Color(0xFFF2B530);
  static const Color purple = Color(0xFFAC22D6);
}

class AppDurations {
  static const Duration snackBar = Duration(seconds: 1);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.primary,
          surface: AppColors.background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.background,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: AppColors.background),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.grey,
          selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.background,
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
          fillColor: AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.grey.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintStyle: const TextStyle(
            color: AppColors.grey,
            fontSize: 14,
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.dark),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.dark),
          bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.dark),
          bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.grey),
          bodySmall: TextStyle(fontSize: 12, color: AppColors.grey),
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          color: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: EdgeInsets.zero,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
        ),
        dividerTheme: DividerThemeData(color: AppColors.grey.withValues(alpha: 0.3), thickness: 1),
      );
}
