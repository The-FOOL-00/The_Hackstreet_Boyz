/// Game screen for memory match gameplay
///
/// Stitch Design: Stats bar with dividers, turn indicator pill, rounded cards.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../providers/game_provider.dart';
import '../providers/activity_provider.dart';
import '../widgets/game_card_widget.dart';
import '../voice_chat/voice_chat_service.dart';
import 'result_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _isListening = false;
  VoiceChatService? _voiceChat;

  @override
  void initState() {
    super.initState();
    // Listen for game completion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkGameComplete();
        _initVoiceChat();
      }
    });
  }

  void _initVoiceChat() {
    final gameProvider = context.read<GameProvider>();
    final room = gameProvider.room;
    if (gameProvider.isMultiplayer && room != null) {
      // Use hostId or guestId based on isMyTurn state
      final myId = gameProvider.isMyTurn ? room.currentTurn : 
          (room.hostId == room.currentTurn ? room.guestId : room.hostId);
      _voiceChat = VoiceChatService(
        roomId: room.roomCode,
        userId: myId ?? 'player_${DateTime.now().millisecondsSinceEpoch}',
        userName: 'Player',
      );
      _voiceChat!.joinRoom();
      _voiceChat!.addListener(_onVoiceChatChanged);
    }
  }

  void _onVoiceChatChanged() {
    if (mounted) setState(() {});
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
    _voiceChat?.removeListener(_onVoiceChatChanged);
    _voiceChat?.leaveRoom();
    _voiceChat?.dispose();
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
            backgroundColor: AppColors.backgroundLight,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Loading game...',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          body: Stack(
            children: [
              // Stitch: Decorative blur circle
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
              SafeArea(
                child: Column(
                  children: [
                    // Stitch: Custom header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Close button
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
                              icon: const Icon(Icons.close_rounded),
                              color: AppColors.textPrimary,
                              onPressed: () => _showExitConfirmation(context),
                            ),
                          ),
                          const Spacer(),
                          // Title with pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🧠', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  'Memory Game',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Restart button (single player only)
                          if (!isMultiplayer)
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
                                icon: const Icon(Icons.refresh_rounded),
                                color: AppColors.primaryBlue,
                                onPressed: () {
                                  gameProvider.restartGame();
                                },
                              ),
                            )
                          else
                            _buildVoiceChatButton(),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Stats bar
                            _buildStatsBar(gameProvider),
                            const SizedBox(height: 12),
                            // Message display
                            if (gameProvider.message != null) ...[
                              _buildMessageBanner(
                                gameProvider.message!,
                                AppColors.accentGreen,
                              ),
                              const SizedBox(height: 12),
                            ],
                            // Turn indicator (multiplayer)
                            if (isMultiplayer) ...[
                              _buildTurnIndicator(
                                isMyTurn: gameProvider.isMyTurn,
                                myTurnText: 'Your Turn! 🎯',
                                waitingText: 'Waiting for opponent...',
                              ),
                              const SizedBox(height: 12),
                            ],
                            // Turn indicator (bot game)
                            if (gameProvider.isBotGame) ...[
                              Builder(
                                builder: (context) {
                                  final isBotTurn =
                                      !gameProvider.isMyTurn || gameProvider.isProcessing;
                                  return _buildTurnIndicator(
                                    isMyTurn: !isBotTurn,
                                    myTurnText: 'Your Turn! 🎯',
                                    waitingText: '🤖 Bot is thinking...',
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                            // Game grid
                            Expanded(
                              child: Center(
                                child: _buildGameGrid(gameProvider, gridSize, cards),
                              ),
                            ),
                            const SizedBox(height: 16),
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
      },
    );
  }

  Widget _buildVoiceChatButton() {
    final isConnected = _voiceChat?.isConnected ?? false;
    final isMuted = _voiceChat?.isMuted ?? true;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: !isConnected
            ? AppColors.backgroundWhite
            : isMuted
                ? const Color(0xFFFFEBEE)
                : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: !isConnected
              ? AppColors.borderBlue
              : isMuted
                  ? const Color(0xFFE53935)
                  : const Color(0xFF4CAF50),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          color: !isConnected
              ? AppColors.textSecondary
              : isMuted
                  ? const Color(0xFFE53935)
                  : const Color(0xFF4CAF50),
        ),
        onPressed: isConnected ? () => _voiceChat?.toggleMute() : null,
        tooltip: isMuted ? 'Unmute' : 'Mute',
      ),
    );
  }

  Widget _buildMessageBanner(String message, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('✨', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Text(
            message,
            style: AppTextStyles.bodyLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTurnIndicator({
    required bool isMyTurn,
    required String myTurnText,
    required String waitingText,
  }) {
    final color = isMyTurn ? AppColors.accentGreen : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        isMyTurn ? myTurnText : waitingText,
        style: AppTextStyles.bodyLarge.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatsBar(GameProvider gameProvider) {
    final isBotGame = gameProvider.isBotGame;
    final isMultiplayer = gameProvider.isMultiplayer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderBlue),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 16,
            offset: const Offset(0, 4),
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
          _buildDivider(),
          _buildStatItem(
            icon: '🔄',
            label: 'Moves',
            value: '${gameProvider.moves}',
          ),
          if (isBotGame) ...[
            _buildDivider(),
            _buildStatItem(
              icon: '⚔️',
              label: 'You vs Bot',
              value: '${gameProvider.playerScore} - ${gameProvider.botScore}',
            ),
          ],
          if (isMultiplayer) ...[
            _buildDivider(),
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

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 44,
      color: AppColors.borderBlue,
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
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(
              value,
              style: AppTextStyles.statsValue.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildGameGrid(GameProvider gameProvider, int gridSize, List cards) {
    // Calculate card size based on screen and grid
    final screenWidth = MediaQuery.of(context).size.width - 32;
    final screenHeight = MediaQuery.of(context).size.height - 380;
    final maxCardSize = 100.0;
    final horizontalGap = 10.0 * (gridSize - 1);
    final verticalGap = 10.0 * (gridSize - 1);

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
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
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
            // Use bot-aware tap handler if it's a bot game
            if (gameProvider.isBotGame) {
              gameProvider.onCardTapBotGame(index);
            } else {
              gameProvider.onCardTap(index);
            }
          },
        );
      },
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.backgroundWhite,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🚪', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Text('Leave Game?', style: AppTextStyles.heading4),
          ],
        ),
        content: Text(
          'Are you sure you want to leave? Your progress will be lost.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.borderBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Stay',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final gameProvider = context.read<GameProvider>();
                    gameProvider.reset();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Leave',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
