import 'package:flutter/material.dart';

class AppColors {
  
  // Theme palette colors — use these for all surfaces, borders, dividers and text.
  
  // Primary and secondary colors
  static const Color primary = Color.fromARGB(255, 230, 0, 0);
  static const Color primarydark = Color.fromARGB(255, 183, 0, 0);

  // Background and surface colors
  static const Color background = Color.fromARGB(255, 243, 241, 241);
  static const Color surface = Color.fromARGB(255, 255, 255, 255);

  // Text colors
  static const Color textdark = Color.fromARGB(255, 13, 14, 15);
  static const Color textmedium = Color.fromARGB(255, 104, 109, 122);
  static const Color textlight = Color.fromARGB(255, 248, 249, 250);

  // Utility colors for specific use cases
  static const Color info = Color.fromARGB(255, 24, 143, 228);
  static const Color success = Color.fromARGB(255, 0, 161, 32);
  static const Color warning = Color.fromARGB(255, 254, 174, 1);
  static const Color error = Color.fromARGB(255, 223, 0, 0);
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
          primary: AppColors.textdark,
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
          unselectedItemColor: AppColors.textmedium,
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
            borderSide: BorderSide(color: AppColors.textmedium.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.textmedium.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.textdark, width: 1.5),
          ),
          hintStyle: const TextStyle(
            color: AppColors.textmedium,
            fontSize: 14,
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textdark),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textdark),
          bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textdark),
          bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textmedium),
          bodySmall: TextStyle(fontSize: 12, color: AppColors.textmedium),
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
        dividerTheme: DividerThemeData(color: AppColors.textmedium.withValues(alpha: 0.3), thickness: 1),
      );
}
