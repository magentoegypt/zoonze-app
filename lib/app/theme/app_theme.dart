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

  static ThemeData light(String languageCode) => _build(languageCode, Brightness.light);
  static ThemeData dark(String languageCode) => _build(languageCode, Brightness.dark);

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
      scaffoldBackgroundColor:
          brightness == Brightness.light ? Colors.white : AppColors.surfaceDark,
      appBarTheme: AppBarTheme(
        backgroundColor:
            brightness == Brightness.light ? Colors.white : AppColors.surfaceDark,
        foregroundColor: AppColors.brandPrimary,
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
    );
  }
}
