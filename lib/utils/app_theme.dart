import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.skyBlue,
      primaryColor: AppColors.navy,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.navy,
        onPrimary: AppColors.white,
        secondary: AppColors.teal,
        onSecondary: AppColors.white,
        error: Colors.red,
        onError: AppColors.white,
        surface: AppColors.beige,
        onSurface: AppColors.navy,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.beige,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.navy,
        ),
        bodyMedium: TextStyle(color: AppColors.navy),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.darkTeal,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkTeal,
        onPrimary: AppColors.darkBackground,
        secondary: AppColors.darkTeal,
        onSecondary: AppColors.darkBackground,
        error: Colors.redAccent,
        onError: AppColors.darkBackground,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.darkText,
        ),
        bodyMedium: TextStyle(color: AppColors.darkText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        hintStyle: const TextStyle(color: AppColors.darkSecondaryText),
        labelStyle: const TextStyle(color: AppColors.darkText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkTeal),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkTeal, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkTeal, width: 1),
        ),
      ),
    );
  }
}
