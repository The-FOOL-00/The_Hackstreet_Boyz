/// Result screen showing game completion
///
/// Stitch Design: Celebration layout with gradient decorations, stats card.
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
          backgroundColor: AppColors.backgroundLight,
          body: Stack(
            children: [
              // Stitch: Decorative gradient circle top
              Positioned(
                top: -100,
                left: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentGreen.withOpacity(0.15),
                        AppColors.accentGreen.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              // Stitch: Decorative gradient circle bottom-right
              Positioned(
                bottom: -60,
                right: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryBlue.withOpacity(0.1),
                        AppColors.primaryBlue.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        // Stitch: Celebration icon in container
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.accentGreen.withOpacity(0.15),
                                AppColors.accentGreen.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: AppColors.accentGreen.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Text('🎉', style: TextStyle(fontSize: 60)),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Well Done!',
                          style: AppTextStyles.heading1.copyWith(
                            color: AppColors.accentGreen,
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            message,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Stitch: Stats card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.borderBlue),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowCard,
                                blurRadius: 24,
                                offset: const Offset(0, 8),
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
                              _buildStitchDivider(),
                              const SizedBox(height: 16),
                              // Moves
                              _buildStatRow(
                                icon: '🔄',
                                label: 'Total Moves',
                                value: '${gameProvider.moves}',
                              ),
                              if (isMultiplayer && gameProvider.room != null) ...[
                                const SizedBox(height: 16),
                                _buildStitchDivider(),
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
                        const SizedBox(height: 24),
                        // Stitch: Encouraging message
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.accentGreen.withOpacity(0.15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.accentGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text('🧠', style: TextStyle(fontSize: 22)),
                                ),
                              ),
                              const SizedBox(width: 14),
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
                        const SizedBox(height: 28),
                        // Buttons
                        if (!isMultiplayer) ...[
                          LargeButton(
                            text: 'Play Again',
                            subtitle: 'Start a new game',
                            emoji: '🔄',
                            isPrimary: true,
                            onPressed: () {
                              gameProvider.reset();
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const DifficultySelectScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                        ],
                        LargeButton(
                          text: 'Back to Home',
                          subtitle: 'Main menu',
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
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStitchDivider() {
    return Container(
      height: 1,
      color: AppColors.borderBlue,
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),
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
          style: AppTextStyles.statsValue.copyWith(
            color: AppColors.primaryBlue,
          ),
        ),
      ],
    );
  }
}
