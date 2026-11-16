import 'package:flutter/material.dart';

/// Sitedeki renk sistemiyle uyumlu tema (lacivert ana renk, yeşil vurgu, logo mavisi).
class AppColors {
  AppColors._();
  static const navy = Color(0xFF232A36);
  static const navyDark = Color(0xFF161B23);
  static const green = Color(0xFF1F9A57);
  static const greenSoft = Color(0xFFE6F6EC);
  static const blue = Color(0xFF1E9AD6);
  static const background = Color(0xFFF5F6F8);
  static const surface = Colors.white;
  static const border = Color(0xFFE3E6EB);
  static const muted = Color(0xFF6B7280);
  static const danger = Color(0xFFDC2626);
  static const star = Color(0xFFF5A524);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.navy,
    primary: AppColors.navy,
    secondary: AppColors.green,
    surface: AppColors.surface,
    error: AppColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.navy,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(color: AppColors.navy, fontSize: 18, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 50),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        minimumSize: const Size(48, 50),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.greenSoft,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
  );
}
