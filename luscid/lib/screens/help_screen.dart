/// Help screen with game instructions
///
/// Stitch Design: Card sections, decorative circles, icon containers.
library;

import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../widgets/large_button.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Stitch: Decorative blur circle top-right
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withOpacity(0.08),
              ),
            ),
          ),
          // Stitch: Decorative blur circle bottom-left
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft.withOpacity(0.5),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Stitch: Custom header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // Back button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderBlue),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowSoft,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AppColors.textPrimary,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Help',
                        style: AppTextStyles.heading4.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // How to Play
                        _buildSection(
                          emoji: '🎮',
                          title: 'How to Play',
                          color: AppColors.primaryBlue,
                          content: '''
1. Tap on any card to flip it over

2. Try to remember what you see

3. Tap another card to find a match

4. If the symbols match, they stay face up

5. If they don't match, both cards flip back

6. Find all pairs to win the game!''',
                        ),
                        const SizedBox(height: 16),
                        // Why This Helps
                        _buildSection(
                          emoji: '🧠',
                          title: 'Why This Helps',
                          color: AppColors.accentGreen,
                          content: '''
Memory games are great for keeping your mind sharp!

✓ Improves short-term memory

✓ Enhances concentration

✓ Stimulates brain activity

✓ Provides a fun mental workout

✓ Can be enjoyed at any pace''',
                        ),
                        const SizedBox(height: 16),
                        // Playing with Family
                        _buildSection(
                          emoji: '👨‍👩‍👧',
                          title: 'Playing with Family',
                          color: AppColors.warning,
                          content: '''
Make it a social activity!

1. Tap "Play With Someone" on the home screen

2. Create a room and share the 4-digit code

3. Your partner enters the code on their device

4. Take turns finding matching pairs

5. The player who finds the most pairs wins

6. Have fun together! 🎉''',
                        ),
                        const SizedBox(height: 16),
                        // Tips
                        _buildSection(
                          emoji: '💡',
                          title: 'Tips for Success',
                          color: AppColors.primaryBlue,
                          content: '''
• Start with the Easy level if you're new

• Take your time - there's no rush!

• Play a little each day for best results

• Don't worry about mistakes - they help you learn

• Enjoy the process! 😊''',
                        ),
                        const SizedBox(height: 28),
                        // Back button
                        LargeButton(
                          text: 'Back to Home',
                          subtitle: 'Return to main menu',
                          emoji: '🏠',
                          isPrimary: false,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String emoji,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderBlue),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Stitch: Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
