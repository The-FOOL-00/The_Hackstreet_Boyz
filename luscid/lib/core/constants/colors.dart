/// App color constants for elderly-friendly UI
///
/// Design philosophy: Clean blue-tinted palette with high contrast
/// and clear visual distinction for accessibility.
/// Based on Stitch Design System.
library;

import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // Primary colors (Stitch Design)
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryBlueDark = Color(0xFF2563EB);
  static const Color primaryBlueLight = Color(0xFF60A5FA);
  static const Color primarySoft = Color(0xFFDBEAFE); // Blue-100

  // Background colors (Stitch: light blue tint)
  static const Color backgroundLight = Color(0xFFF0F7FF); // Light blue tint
  static const Color backgroundBeige = Color(0xFFF0F7FF); // Alias for compatibility
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B); // Slate-800

  // Accent colors
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentGreenLight = Color(0xFF34D399);
  static const Color accentGreenDark = Color(0xFF059669);
  static const Color accentBlueLight = Color(0xFFE0F2FE); // For icon backgrounds

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Text colors (Stitch: Slate palette)
  static const Color textPrimary = Color(0xFF1E293B); // Slate-800
  static const Color textMain = Color(0xFF1E293B); // Alias
  static const Color textSecondary = Color(0xFF64748B); // Slate-500
  static const Color textSub = Color(0xFF64748B); // Alias
  static const Color textLight = Color(0xFF94A3B8); // Slate-400
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Border colors (Stitch: blue tint)
  static const Color borderLight = Color(0xFFE2E8F0); // Slate-200
  static const Color borderMedium = Color(0xFFCBD5E1); // Slate-300
  static const Color borderBlue = Color(0xFFBFDBFE); // Blue-200

  // Game-specific colors
  static const Color cardBack = Color(0xFF3B82F6);
  static const Color cardBackGradientStart = Color(0xFF60A5FA);
  static const Color cardBackGradientEnd = Color(0xFF3B82F6);
  static const Color cardFront = Color(0xFFFFFFFF);
  static const Color cardMatched = Color(0xFF10B981);
  static const Color cardBorder = Color(0xFFBFDBFE); // Blue-200
  static const Color cardRevealedBg = Color(0xFFEFF6FF); // Blue-50

  // Overlay colors
  static const Color overlayDark = Color(0x80000000);
  static const Color overlayLight = Color(0x40FFFFFF);

  // Shadow colors (Stitch)
  static const Color shadowSoft = Color(0x1A3B82F6); // 10% primary
  static const Color shadowButton = Color(0x663B82F6); // 40% primary
  static const Color shadowCard = Color(0x0D1E3A8A); // 5% deep blue
}
