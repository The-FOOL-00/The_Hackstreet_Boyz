/// App color constants for elderly-friendly UI
///
/// Design philosophy: Warm, high-contrast colors that are easy on the eyes
/// and provide clear visual distinction between interactive elements.
library;

import 'package:flutter/material.dart';

class AppColors {
  // Prevent instantiation
  AppColors._();

  // Primary colors
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color primaryBlueDark = Color(0xFF2563EB);
  static const Color primaryBlueLight = Color(0xFF60A5FA);

  // Background colors
  static const Color backgroundBeige = Color(0xFFF7F5F2);
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundCard = Color(0xFFFFFFFF);

  // Accent colors
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentGreenLight = Color(0xFF34D399);
  static const Color accentGreenDark = Color(0xFF059669);

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Text colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Border colors
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color borderMedium = Color(0xFFD1D5DB);

  // Game-specific colors
  static const Color cardBack = Color(0xFF3B82F6);
  static const Color cardFront = Color(0xFFFFFFFF);
  static const Color cardMatched = Color(0xFF10B981);
  static const Color cardBorder = Color(0xFFE5E7EB);

  // Overlay colors
  static const Color overlayDark = Color(0x80000000);
  static const Color overlayLight = Color(0x40FFFFFF);
}
