/// Numeric keypad widget for PIN entry
///
/// Large, accessible numeric buttons for elderly users.
library;

import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

class NumericKeypad extends StatelessWidget {
  final Function(String) onDigitPressed;
  final VoidCallback onBackspace;
  final VoidCallback? onClear;
  final int maxLength;
  final String currentValue;

  const NumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspace,
    this.onClear,
    this.maxLength = 4,
    this.currentValue = '',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PIN display
        _buildPinDisplay(),
        const SizedBox(height: 24),
        // Keypad
        _buildKeypad(),
      ],
    );
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLength, (index) {
        final isFilled = index < currentValue.length;
        return Container(
          width: 56,
          height: 64,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFilled ? AppColors.primaryBlue : AppColors.borderMedium,
              width: 2,
            ),
          ),
          child: Center(
            child: isFilled
                ? Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        // Row 1: 1, 2, 3
        _buildRow(['1', '2', '3']),
        const SizedBox(height: 12),
        // Row 2: 4, 5, 6
        _buildRow(['4', '5', '6']),
        const SizedBox(height: 12),
        // Row 3: 7, 8, 9
        _buildRow(['7', '8', '9']),
        const SizedBox(height: 12),
        // Row 4: Clear, 0, Backspace
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActionButton(icon: Icons.clear_all, onPressed: onClear),
            const SizedBox(width: 12),
            _buildDigitButton('0'),
            const SizedBox(width: 12),
            _buildActionButton(
              icon: Icons.backspace_outlined,
              onPressed: onBackspace,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((digit) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _buildDigitButton(digit),
        );
      }).toList(),
    );
  }

  Widget _buildDigitButton(String digit) {
    final isDisabled = currentValue.length >= maxLength;

    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: isDisabled ? null : () => onDigitPressed(digit),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.backgroundWhite,
          foregroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.backgroundWhite.withOpacity(0.5),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(digit, style: AppTextStyles.pinDigit),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, VoidCallback? onPressed}) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.backgroundBeige,
          foregroundColor: AppColors.textSecondary,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, size: 32),
      ),
    );
  }
}
