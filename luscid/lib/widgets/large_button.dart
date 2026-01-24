/// Large button widget for elderly-friendly UI
///
/// Minimum 72px height, high contrast, with optional icon.
library;

import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

class LargeButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? emoji;
  final bool isPrimary;
  final bool isLoading;
  final double? width;
  final EdgeInsets? padding;

  const LargeButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.emoji,
    this.isPrimary = true,
    this.isLoading = false,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(
                isPrimary ? AppColors.textOnPrimary : AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ] else ...[
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
          ] else if (icon != null) ...[
            Icon(
              icon,
              size: 28,
              color: isPrimary
                  ? AppColors.textOnPrimary
                  : AppColors.primaryBlue,
            ),
            const SizedBox(width: 12),
          ],
        ],
        Flexible(
          child: Text(
            text,
            style: isPrimary
                ? AppTextStyles.buttonLarge.copyWith(
                    color: AppColors.textOnPrimary,
                  )
                : AppTextStyles.buttonLarge.copyWith(
                    color: AppColors.primaryBlue,
                  ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (isPrimary) {
      return SizedBox(
        width: width ?? double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: AppColors.textOnPrimary,
            minimumSize: const Size(double.infinity, 72),
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
          child: content,
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          minimumSize: const Size(double.infinity, 72),
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        child: content,
      ),
    );
  }
}

/// Secondary button with white background
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? emoji;
  final bool isLoading;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.emoji,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return LargeButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      emoji: emoji,
      isPrimary: false,
      isLoading: isLoading,
    );
  }
}
