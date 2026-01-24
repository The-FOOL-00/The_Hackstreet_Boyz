/// Help screen with game instructions
///
/// Explains how to play and the benefits of memory training.
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
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Help', style: AppTextStyles.heading4),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // How to Play
              _buildSection(
                emoji: '🎮',
                title: 'How to Play',
                content: '''
1. Tap on any card to flip it over

2. Try to remember what you see

3. Tap another card to find a match

4. If the symbols match, they stay face up

5. If they don't match, both cards flip back

6. Find all pairs to win the game!''',
              ),
              const SizedBox(height: 24),
              // Why This Helps
              _buildSection(
                emoji: '🧠',
                title: 'Why This Helps',
                content: '''
Memory games are great for keeping your mind sharp!

✓ Improves short-term memory

✓ Enhances concentration

✓ Stimulates brain activity

✓ Provides a fun mental workout

✓ Can be enjoyed at any pace''',
              ),
              const SizedBox(height: 24),
              // Playing with Family
              _buildSection(
                emoji: '👨‍👩‍👧',
                title: 'Playing with Family',
                content: '''
Make it a social activity!

1. Tap "Play With Someone" on the home screen

2. Create a room and share the 4-digit code

3. Your partner enters the code on their device

4. Take turns finding matching pairs

5. The player who finds the most pairs wins

6. Have fun together! 🎉''',
              ),
              const SizedBox(height: 24),
              // Tips
              _buildSection(
                emoji: '💡',
                title: 'Tips for Success',
                content: '''
• Start with the Easy level if you're new

• Take your time - there's no rush!

• Play a little each day for best results

• Don't worry about mistakes - they help you learn

• Enjoy the process! 😊''',
              ),
              const SizedBox(height: 32),
              // Back button
              LargeButton(
                text: 'Back to Home',
                emoji: '🏠',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String emoji,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: AppTextStyles.heading4)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
