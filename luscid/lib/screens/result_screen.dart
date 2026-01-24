/// Result screen showing game completion
///
/// Displays encouraging messages and options to play again.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/utils/helpers.dart';
import '../providers/game_provider.dart';
import '../widgets/large_button.dart';
import 'home_screen.dart';
import 'difficulty_select_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final isMultiplayer = gameProvider.isMultiplayer;
        final message = Helpers.getGameCompleteMessage();

        return Scaffold(
          backgroundColor: AppColors.backgroundBeige,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Celebration
                    const Text('🎉', style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 24),
                    Text(
                      'Well Done!',
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.accentGreen,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    // Stats card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Pairs found
                          _buildStatRow(
                            icon: '🎯',
                            label: 'Pairs Found',
                            value:
                                '${gameProvider.matchesFound}/${gameProvider.totalPairs}',
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          // Moves
                          _buildStatRow(
                            icon: '🔄',
                            label: 'Total Moves',
                            value: '${gameProvider.moves}',
                          ),
                          if (isMultiplayer && gameProvider.room != null) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            // Multiplayer scores
                            _buildStatRow(
                              icon: '👤',
                              label: 'Your Score',
                              value:
                                  '${gameProvider.room!.getScore(gameProvider.room!.hostId)}',
                            ),
                            const SizedBox(height: 12),
                            _buildStatRow(
                              icon: '👥',
                              label: 'Partner Score',
                              value:
                                  '${gameProvider.room!.getScore(gameProvider.room!.guestId ?? '')}',
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Encouraging message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🧠', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Great exercise for your mind!',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.accentGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    if (!isMultiplayer) ...[
                      LargeButton(
                        text: 'Play Again',
                        emoji: '🔄',
                        onPressed: () {
                          gameProvider.reset();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const DifficultySelectScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    LargeButton(
                      text: 'Back to Home',
                      emoji: '🏠',
                      isPrimary: isMultiplayer,
                      onPressed: () {
                        gameProvider.reset();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow({
    required String icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: AppTextStyles.heading4.copyWith(color: AppColors.primaryBlue),
        ),
      ],
    );
  }
}
