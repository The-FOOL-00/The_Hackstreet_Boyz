/// Difficulty selection screen
///
/// Allows users to choose game difficulty before starting.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/constants/game_icons.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

class DifficultySelectScreen extends StatelessWidget {
  final bool isMultiplayer;

  const DifficultySelectScreen({super.key, this.isMultiplayer = false});

  void _selectDifficulty(BuildContext context, GameDifficulty difficulty) {
    final gameProvider = context.read<GameProvider>();

    if (isMultiplayer) {
      // For multiplayer, return the selected difficulty
      Navigator.of(context).pop(difficulty);
    } else {
      // For single player, start the game
      gameProvider.startSinglePlayerGame(difficulty);
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const GameScreen()));
    }
  }

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
        title: Text('Choose Difficulty', style: AppTextStyles.heading4),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      'How challenging would you like it?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Difficulty options
              _buildDifficultyCard(
                context: context,
                difficulty: GameDifficulty.easy,
                title: 'Easy',
                subtitle: '2×2 Grid • 2 Pairs',
                emoji: '😊',
                color: AppColors.accentGreen,
              ),
              const SizedBox(height: 16),
              _buildDifficultyCard(
                context: context,
                difficulty: GameDifficulty.medium,
                title: 'Medium',
                subtitle: '4×4 Grid • 8 Pairs',
                emoji: '🤔',
                color: AppColors.warning,
              ),
              const SizedBox(height: 16),
              _buildDifficultyCard(
                context: context,
                difficulty: GameDifficulty.hard,
                title: 'Hard',
                subtitle: '6×6 Grid • 18 Pairs',
                emoji: '💪',
                color: AppColors.error,
              ),
              const Spacer(),
              // Tip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Start with Easy if you\'re new!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard({
    required BuildContext context,
    required GameDifficulty difficulty,
    required String title,
    required String subtitle,
    required String emoji,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _selectDifficulty(context, difficulty),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading4),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
