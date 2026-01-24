/// Difficulty selection screen
///
/// Stitch Design: Radio cards with checkmarks, gradient header, rounded-3xl cards.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/constants/game_icons.dart';
import '../providers/game_provider.dart';
import 'game_screen.dart';

class DifficultySelectScreen extends StatefulWidget {
  final bool isMultiplayer;

  const DifficultySelectScreen({super.key, this.isMultiplayer = false});

  @override
  State<DifficultySelectScreen> createState() => _DifficultySelectScreenState();
}

class _DifficultySelectScreenState extends State<DifficultySelectScreen> {
  GameDifficulty? _selectedDifficulty;

  void _selectDifficulty(BuildContext context, GameDifficulty difficulty) {
    setState(() => _selectedDifficulty = difficulty);
  }

  void _confirmSelection() {
    if (_selectedDifficulty == null) return;

    final gameProvider = context.read<GameProvider>();

    if (widget.isMultiplayer) {
      Navigator.of(context).pop(_selectedDifficulty);
    } else {
      gameProvider.startSinglePlayerGame(_selectedDifficulty!);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Stitch: Decorative blur circle
          Positioned(
            top: -60,
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
                        'Choose Difficulty',
                        style: AppTextStyles.heading4.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // Balance
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Stitch: Header card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primaryBlue, Color(0xFF60A5FA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Text('🎯', style: TextStyle(fontSize: 40)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'How challenging would you like it?',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: Colors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Stitch: Difficulty cards with radio selection
                        _buildDifficultyCard(
                          difficulty: GameDifficulty.easy,
                          title: 'Easy',
                          subtitle: '2×2 Grid • 2 Pairs',
                          emoji: '😊',
                          color: AppColors.accentGreen,
                        ),
                        const SizedBox(height: 14),
                        _buildDifficultyCard(
                          difficulty: GameDifficulty.medium,
                          title: 'Medium',
                          subtitle: '4×4 Grid • 8 Pairs',
                          emoji: '🤔',
                          color: AppColors.warning,
                        ),
                        const SizedBox(height: 14),
                        _buildDifficultyCard(
                          difficulty: GameDifficulty.hard,
                          title: 'Hard',
                          subtitle: '6×6 Grid • 18 Pairs',
                          emoji: '💪',
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 28),
                        // Stitch: Tip card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderBlue),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text('💡', style: TextStyle(fontSize: 22)),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Start with Easy if you\'re new!',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w500,
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
                // Stitch: Bottom CTA
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowCard,
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 72,
                      child: ElevatedButton(
                        onPressed: _selectedDifficulty != null ? _confirmSelection : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          disabledBackgroundColor: AppColors.borderBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Start Game',
                              style: AppTextStyles.buttonLarge.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildDifficultyCard({
    required GameDifficulty difficulty,
    required String title,
    required String subtitle,
    required String emoji,
    required Color color,
  }) {
    final isSelected = _selectedDifficulty == difficulty;

    return GestureDetector(
      onTap: () => _selectDifficulty(context, difficulty),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? color : AppColors.borderBlue,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withOpacity(0.15) : AppColors.shadowCard,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji container
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 18),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.cardSubtitle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Stitch: Radio/Check indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : AppColors.borderMedium,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
