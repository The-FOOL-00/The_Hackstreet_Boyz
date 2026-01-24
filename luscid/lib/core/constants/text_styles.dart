/// Text style constants for elderly-friendly typography
///
/// Design philosophy: Large, readable fonts with high contrast.
/// Based on Stitch Design System using Lexend font.
/// Minimum body text: 16px, headings: 20px+
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  // Prevent instantiation
  AppTextStyles._();

  // Font family
  static String get fontFamily => GoogleFonts.lexend().fontFamily ?? 'Lexend';

  // Heading styles (Stitch Design)
  static TextStyle get heading1 => GoogleFonts.lexend(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.5,
  );

  static TextStyle get heading2 => GoogleFonts.lexend(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get heading3 => GoogleFonts.lexend(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get heading4 => GoogleFonts.lexend(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  // Body styles
  static TextStyle get bodyLarge => GoogleFonts.lexend(
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.lexend(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.lexend(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // Button styles (Stitch: 22px bold for primary)
  static TextStyle get buttonLarge => GoogleFonts.lexend(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textOnPrimary,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static TextStyle get buttonMedium => GoogleFonts.lexend(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.2,
  );

  // Card title (Stitch: 22px bold)
  static TextStyle get cardTitle => GoogleFonts.lexend(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // Card subtitle (Stitch: 17px medium)
  static TextStyle get cardSubtitle => GoogleFonts.lexend(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  // Special styles
  static TextStyle get pinDigit => GoogleFonts.lexend(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 8,
  );

  static TextStyle get gameCard => GoogleFonts.lexend(
    fontSize: 32,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static TextStyle get encouragement => GoogleFonts.lexend(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: AppColors.accentGreen,
    height: 1.4,
  );

  static TextStyle get roomCode => GoogleFonts.lexend(
    fontSize: 56,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 16,
  );

  // Label style (Stitch: small caps)
  static TextStyle get labelSmall => GoogleFonts.lexend(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlue,
    letterSpacing: 1.2,
  );

  // Stats value
  static TextStyle get statsValue => GoogleFonts.lexend(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );
}
