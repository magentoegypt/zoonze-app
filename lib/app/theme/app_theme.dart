import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Builds the app [ThemeData] from Figma tokens with locale-aware typography:
/// Inter for Latin (EN), Cairo for Arabic (AR). The Playfair Display wordmark
/// is applied locally where the brand lockup is rendered, not as the base font.
abstract final class AppTheme {
  static const String latinFont = 'Inter';
  static const String arabicFont = 'Cairo';
  static const String displayFont = 'Playfair Display';

  static String fontFor(String languageCode) =>
      languageCode == 'ar' ? arabicFont : latinFont;

  static ThemeData light(String languageCode) =>
      _build(languageCode, Brightness.light);
  static ThemeData dark(String languageCode) =>
      _build(languageCode, Brightness.dark);

  static ThemeData _build(String languageCode, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: brightness,
      primary: AppColors.brandPrimary,
      secondary: AppColors.accentGold,
      error: AppColors.accentSale,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: fontFor(languageCode),
    );

    return base.copyWith(
      scaffoldBackgroundColor: brightness == Brightness.light
          ? Colors.white
          : AppColors.surfaceDark,
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light
            ? Colors.white
            : AppColors.surfaceDark,
        // Ink (near-black) titles + leading/action icons per QA — the burgundy
        // brand colour stays on the wordmark logo, prices and buttons, not the
        // page titles. Screens that render the BrandLogo image are unaffected.
        foregroundColor: AppColors.inkHeading,
        elevation: 0,
        centerTitle: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      // Figma form fields: filled grey (surface/alt), rounded, no hard border,
      // burgundy focus ring. Applies to every TextField/TextFormField app-wide.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? const Color(0xFFF3F4F6) // surface/alt
            : Colors.white10,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)), // text/muted
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.brandPrimary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
