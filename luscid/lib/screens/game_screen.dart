/// Game screen for memory match gameplay
///
/// Displays the card grid and handles game interactions.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../providers/game_provider.dart';
import '../providers/activity_provider.dart';
import '../widgets/game_card_widget.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Listen for game completion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkGameComplete();
      }
    });
  }

  void _checkGameComplete() {
    if (!mounted) return;
    final gameProvider = context.read<GameProvider>();
    gameProvider.addListener(_onGameStateChanged);
    _isListening = true;
  }

  void _onGameStateChanged() {
    if (!mounted) return;
    final gameProvider = context.read<GameProvider>();
    if (gameProvider.isGameComplete) {
      // Mark activity as complete
      context.read<ActivityProvider>().markGamePlayed();

      // Navigate to result screen
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ResultScreen()),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    if (_isListening) {
      try {
        final gameProvider = context.read<GameProvider>();
        gameProvider.removeListener(_onGameStateChanged);
      } catch (_) {
        // Provider may already be disposed
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final gridSize = gameProvider.gridSize;
        final cards = gameProvider.cards;
        final isMultiplayer = gameProvider.isMultiplayer;

        // Show loading if cards are empty (waiting for sync)
        if (cards.isEmpty || gridSize == 0) {
          return Scaffold(
            backgroundColor: AppColors.backgroundBeige,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text('Memory Game', style: AppTextStyles.heading4),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading game...'),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundBeige,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => _showExitConfirmation(context),
            ),
            title: Text('Memory Game', style: AppTextStyles.heading4),
            actions: [
              // Restart button (single player only)
              if (!isMultiplayer)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () {
                    gameProvider.restartGame();
                  },
                ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stats bar
                  _buildStatsBar(gameProvider),
                  const SizedBox(height: 16),
                  // Message display
                  if (gameProvider.message != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        gameProvider.message!,
                        style: AppTextStyles.encouragement,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Turn indicator (multiplayer)
                  if (isMultiplayer) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: gameProvider.isMyTurn
                            ? AppColors.accentGreen.withOpacity(0.2)
                            : AppColors.warning.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        gameProvider.isMyTurn
                            ? 'Your Turn! 🎯'
                            : 'Waiting for opponent...',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: gameProvider.isMyTurn
                              ? AppColors.accentGreen
                              : AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Game grid
                  Expanded(
                    child: Center(
                      child: _buildGameGrid(gameProvider, gridSize, cards),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsBar(GameProvider gameProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: '🎯',
            label: 'Matches',
            value: '${gameProvider.matchesFound}/${gameProvider.totalPairs}',
          ),
          Container(width: 1, height: 40, color: AppColors.borderLight),
          _buildStatItem(
            icon: '🔄',
            label: 'Moves',
            value: '${gameProvider.moves}',
          ),
          if (gameProvider.isMultiplayer) ...[
            Container(width: 1, height: 40, color: AppColors.borderLight),
            _buildStatItem(
              icon: '👤',
              label: 'Score',
              value:
                  '${gameProvider.room?.getScore(gameProvider.room?.hostId ?? '') ?? 0} - ${gameProvider.room?.getScore(gameProvider.room?.guestId ?? '') ?? 0}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(value, style: AppTextStyles.heading4),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGameGrid(GameProvider gameProvider, int gridSize, List cards) {
    // Calculate card size based on screen and grid
    final screenWidth = MediaQuery.of(context).size.width - 32;
    final screenHeight = MediaQuery.of(context).size.height - 350;
    final maxCardSize = 100.0;
    final horizontalGap = 8.0 * (gridSize - 1);
    final verticalGap = 8.0 * (gridSize - 1);

    final cardSizeByWidth = (screenWidth - horizontalGap) / gridSize;
    final cardSizeByHeight = (screenHeight - verticalGap) / gridSize;
    final cardSize = [
      cardSizeByWidth,
      cardSizeByHeight,
      maxCardSize,
    ].reduce((a, b) => a < b ? a : b);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridSize,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return GameCardWidget(
          card: card,
          size: cardSize,
          disabled: gameProvider.isProcessing || !gameProvider.isMyTurn,
          onTap: () {
            gameProvider.onCardTap(index);
          },
        );
      },
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Leave Game?', style: AppTextStyles.heading3),
        content: Text(
          'Are you sure you want to leave? Your progress will be lost.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Stay',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final gameProvider = context.read<GameProvider>();
              gameProvider.reset();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text('Leave', style: AppTextStyles.buttonMedium),
          ),
        ],
      ),
    );
  }
}
