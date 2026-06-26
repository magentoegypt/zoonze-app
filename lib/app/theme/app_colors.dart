import 'package:flutter/material.dart';

/// Figma design tokens (`Zoonze/Color`). A single source of truth for brand
/// colours so theming stays consistent across every screen.
abstract final class AppColors {
  /// Burgundy — primary actions, prices, wordmark.
  static const Color brandPrimary = Color(0xFF9E1B3F);

  /// Pressed / active state.
  static const Color brandPrimaryPressed = Color(0xFF7E1632);

  /// Blush — section backgrounds, icon chips, empty-state circles.
  static const Color surfaceTint = Color(0xFFFBF1F4);

  /// Discount badges (e.g. `-24%`).
  static const Color accentSale = Color(0xFFEF4444);

  /// `BESTSELLER` badge and review stars.
  static const Color accentGold = Color(0xFFC9A24C);

  /// Headings / primary text.
  static const Color inkHeading = Color(0xFF1F2937);

  /// Secondary text, struck-through prices.
  static const Color inkMuted = Color(0xFF6B7280);

  /// Dark surfaces.
  static const Color surfaceDark = Color(0xFF1F2937);
}
