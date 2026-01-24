/// CineRecall Trivia Game Screen
///
/// Multiplayer movie puzzle game for elderly users with
/// high contrast, large text, and nostalgia-themed UI.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../models/trivia_model.dart';
import '../providers/trivia_provider.dart';

class TriviaGameScreen extends StatefulWidget {
  final String roomCode;
  final bool isHost;
  final bool isSolo;

  const TriviaGameScreen({
    super.key,
    required this.roomCode,
    required this.isHost,
    this.isSolo = false,
  });

  @override
  State<TriviaGameScreen> createState() => _TriviaGameScreenState();
}

class _TriviaGameScreenState extends State<TriviaGameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TriviaProvider>(
      builder: (context, provider, child) {
        final room = provider.room;
        final puzzle = provider.currentPuzzle;

        // Loading state
        if (room == null) {
          return Scaffold(
            backgroundColor: AppColors.backgroundBeige,
            appBar: _buildAppBar(context, null),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryBlue),
                  SizedBox(height: 24),
                  Text(
                    'Loading game...',
                    style: TextStyle(
                      fontSize: 24,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Waiting for other player (skip in solo mode)
        if (!room.isRoomFull && !widget.isSolo) {
          return Scaffold(
            backgroundColor: AppColors.backgroundBeige,
            appBar: _buildAppBar(context, null),
            body: _buildWaitingScreen(room),
          );
        }

        // Game finished
        if (provider.isFinished) {
          return Scaffold(
            backgroundColor: AppColors.backgroundBeige,
            appBar: _buildAppBar(context, puzzle),
            body: _buildFinishedScreen(provider),
          );
        }

        // Active game
        return Scaffold(
          backgroundColor: AppColors.backgroundBeige,
          appBar: _buildAppBar(context, puzzle),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Progress indicator
                  _buildProgressBar(provider),
                  const SizedBox(height: 24),

                  // Puzzle area
                  Expanded(
                    child: puzzle != null
                        ? _buildPuzzleArea(context, provider, puzzle)
                        : const Center(child: Text('No puzzle available')),
                  ),

                  // Interaction area
                  _buildInteractionArea(context, provider, puzzle),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, MoviePuzzle? puzzle) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, size: 32),
        onPressed: () => _showExitConfirmation(context),
      ),
      title: Text(
        puzzle != null ? 'Guess the ${puzzle.category} Movie' : 'CineRecall 🎬',
        style: AppTextStyles.heading3,
      ),
      centerTitle: true,
    );
  }

  Widget _buildWaitingScreen(TriviaRoom room) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Room code display
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Room Code',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    room.roomCode,
                    style: AppTextStyles.heading1.copyWith(
                      letterSpacing: 8,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Waiting animation
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.5 + (_pulseController.value * 0.5),
                  child: child,
                );
              },
              child: const Icon(
                Icons.people_rounded,
                size: 80,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Waiting for your partner...',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Share the room code with your friend',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(TriviaProvider provider) {
    final current = provider.currentQuestionIndex + 1;
    final total = provider.totalQuestions;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Question $current of $total',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: current / total,
          backgroundColor: AppColors.borderLight,
          valueColor: const AlwaysStoppedAnimation<Color>(
            AppColors.accentGreen,
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildPuzzleArea(
    BuildContext context,
    TriviaProvider provider,
    MoviePuzzle puzzle,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Rebus images equation
          _buildRebusEquation(context, puzzle),
          const SizedBox(height: 24),

          // Hint area (if revealed)
          if (puzzle.isRevealed) _buildHintDisplay(puzzle),
        ],
      ),
    );
  }

  Widget _buildRebusEquation(BuildContext context, MoviePuzzle puzzle) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Take 40-50% of available height for the image
        final imageHeight = constraints.maxHeight > 0
            ? constraints.maxHeight * 0.45
            : 280.0;

        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: 200,
            maxHeight: imageHeight.clamp(200.0, 350.0),
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primaryBlue.withOpacity(0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Stack(
              children: [
                // Main zoomable image
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image.asset(
                      puzzle.imageAsset,
                      fit: BoxFit.contain,
                      semanticLabel: _getSemanticLabel(puzzle.imageAsset),
                      errorBuilder: (context, error, stackTrace) {
                        return _buildAssetFallback(
                          puzzle.imageAsset,
                          isCompact: false,
                        );
                      },
                    ),
                  ),
                ),
                // Zoom hint overlay
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.zoom_in_rounded,
                          size: 18,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pinch to zoom',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tap to expand button
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () =>
                        _showFullScreenImage(context, puzzle.imageAsset),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows the puzzle image in fullscreen with zoom capability
  void _showFullScreenImage(BuildContext context, String assetPath) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // Fullscreen zoomable image
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      semanticLabel: _getSemanticLabel(assetPath),
                      errorBuilder: (context, error, stackTrace) {
                        return SizedBox(
                          width: 300,
                          height: 300,
                          child: _buildAssetFallback(
                            assetPath,
                            isCompact: false,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Instructions at bottom
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Pinch to zoom • Tap X to close',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a fallback widget when asset is missing
  /// Shows broken_image icon with descriptive label for seniors
  Widget _buildAssetFallback(String assetPath, {bool isCompact = false}) {
    final label = _getPlaceholderText(assetPath);

    return Container(
      color: AppColors.backgroundBeige,
      padding: EdgeInsets.all(isCompact ? 8 : 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: isCompact ? 36 : 64,
            color: AppColors.error.withOpacity(0.7),
          ),
          SizedBox(height: isCompact ? 4 : 12),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 11 : 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!isCompact) ...[
            const SizedBox(height: 4),
            Text(
              'Asset not found:\n$assetPath',
              style: TextStyle(fontSize: 11, color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Gets semantic label for accessibility
  String _getSemanticLabel(String path) {
    final fileName = path.split('/').last.split('.').first;
    return 'Puzzle image: ${fileName.replaceAll('_', ' ')}';
  }

  String _getPlaceholderText(String path) {
    final fileName = path.split('/').last.split('.').first;
    return fileName.replaceAll('_', '\n');
  }

  Widget _buildHintDisplay(MoviePuzzle puzzle) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            puzzle.hintType == HintType.lyric
                ? Icons.music_note_rounded
                : Icons.format_quote_rounded,
            size: 32,
            color: AppColors.warning,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  puzzle.hintType == HintType.lyric
                      ? 'பாடல் குறிப்பு'
                      : 'வசன குறிப்பு',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  puzzle.hint,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionArea(
    BuildContext context,
    TriviaProvider provider,
    MoviePuzzle? puzzle,
  ) {
    final status = provider.status;

    // Revealed state - show correct answer
    if (status == TriviaStatus.revealed) {
      return _buildRevealedArea(provider, puzzle);
    }

    // Answering state - show options
    if (status == TriviaStatus.answering && provider.showOptions) {
      return _buildOptionsGrid(provider, puzzle);
    }

    // Discussing state - show discussion controls
    return _buildDiscussionArea(context, provider, puzzle);
  }

  Widget _buildDiscussionArea(
    BuildContext context,
    TriviaProvider provider,
    MoviePuzzle? puzzle,
  ) {
    return Column(
      children: [
        // Voice chat area - modular for easy ZegoCloud/Agora integration
        _buildVoiceChatArea(),
        const SizedBox(height: 16),

        // Hint button - audio hint only
        if (puzzle != null && !puzzle.isRevealed) ...[
          // Audio hint button (if puzzle has audio)
          if (puzzle.audioAsset != null)
            OutlinedButton.icon(
              onPressed: () => provider.playAudioHint(),
              icon: Icon(
                provider.isPlayingAudio
                    ? Icons.stop_circle_rounded
                    : Icons.music_note_rounded,
                size: 28,
              ),
              label: Text(
                provider.isPlayingAudio ? 'Stop Song' : '🎵 Play Song Hint',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 64),
                foregroundColor:
                    provider.isPlayingAudio ? AppColors.error : AppColors.primaryBlue,
                side: BorderSide(
                  color:
                      provider.isPlayingAudio ? AppColors.error : AppColors.primaryBlue,
                  width: 2,
                ),
                textStyle: AppTextStyles.buttonLarge,
              ),
            ),
        ],
        const SizedBox(height: 12),

        // Ready button
        ElevatedButton.icon(
          onPressed: provider.isProcessingAction
              ? null
              : () => provider.readyToAnswer(),
          icon: provider.isProcessingAction
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle_rounded, size: 28),
          label: Text(
            provider.isProcessingAction
                ? 'Loading...'
                : 'We are Ready to Answer',
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 72),
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            textStyle: AppTextStyles.buttonLarge,
          ),
        ),
      ],
    );
  }

  /// Voice chat placeholder widget
  /// TODO: Replace with ZegoCloud/Agora widget
  /// This method is isolated for easy integration swap
  Widget _buildVoiceChatArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentGreen.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: child,
              );
            },
            child: Icon(
              Icons.mic_rounded,
              size: 48,
              color: AppColors.accentGreen.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isSolo
                      ? 'Think carefully...'
                      : 'Discuss with your partner!',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isSolo
                      ? 'Take your time to recall.'
                      : 'Voice chat coming soon...',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsGrid(TriviaProvider provider, MoviePuzzle? puzzle) {
    if (puzzle == null) return const SizedBox.shrink();

    final isProcessing = provider.isProcessingAction;

    return Column(
      children: [
        Text('Select the Movie:', style: AppTextStyles.heading4),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            // Increased aspect ratio for longer text accommodation
            childAspectRatio: 2.0,
          ),
          itemCount: puzzle.options.length,
          itemBuilder: (context, index) {
            final option = puzzle.options[index];
            final isSelected = provider.selectedAnswer == option;
            final isCorrectAnswer = option == puzzle.answer;
            final showResult = provider.status == TriviaStatus.revealed;

            // Determine button color based on state
            Color backgroundColor;
            Color foregroundColor;
            Color borderColor;

            if (showResult) {
              if (isCorrectAnswer) {
                backgroundColor = AppColors.success.withOpacity(0.2);
                foregroundColor = AppColors.success;
                borderColor = AppColors.success;
              } else if (isSelected) {
                backgroundColor = AppColors.error.withOpacity(0.2);
                foregroundColor = AppColors.error;
                borderColor = AppColors.error;
              } else {
                backgroundColor = AppColors.backgroundWhite;
                foregroundColor = AppColors.textSecondary;
                borderColor = AppColors.borderLight;
              }
            } else {
              backgroundColor = isSelected
                  ? AppColors.primaryBlue
                  : AppColors.backgroundWhite;
              foregroundColor = isSelected
                  ? Colors.white
                  : AppColors.textPrimary;
              borderColor = isSelected
                  ? AppColors.primaryBlue
                  : AppColors.borderMedium;
            }

            return Material(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: (provider.selectedAnswer == null && !isProcessing)
                    ? () => provider.selectAnswer(option)
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Center(
                    child: _buildOptionText(
                      option,
                      foregroundColor,
                      isSelected,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Builds option text with proper overflow handling for long Tamil movie names
  Widget _buildOptionText(String text, Color color, bool isSelected) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 50),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }

  Widget _buildRevealedArea(TriviaProvider provider, MoviePuzzle? puzzle) {
    if (puzzle == null) return const SizedBox.shrink();

    final isCorrect = provider.selectedAnswer == puzzle.answer;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Correct Answer:',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            puzzle.answer,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.accentGreen,
            ),
          ),
          if (provider.selectedAnswer != null &&
              provider.selectedAnswer != puzzle.answer) ...[
            const SizedBox(height: 12),
            Text(
              'Your selection: ${provider.selectedAnswer}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: null,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              isCorrect ? AppColors.accentGreen : AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text('Next question in 3 seconds...', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildFinishedScreen(TriviaProvider provider) {
    final scores = provider.scores;
    final currentUserId = provider.currentUserId;
    final room = provider.room;

    if (room == null) return const SizedBox.shrink();

    final myScore = scores[currentUserId] ?? 0;
    final totalQuestions = provider.totalQuestions;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Trophy icon
            const Icon(
              Icons.emoji_events_rounded,
              size: 100,
              color: AppColors.warning,
            ),
            const SizedBox(height: 24),

            // Result message
            Text(
              'Great Job! 🎉',
              style: AppTextStyles.heading1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Final score
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text('Your Score', style: AppTextStyles.heading3),
                  const SizedBox(height: 20),
                  Text(
                    '$myScore / $totalQuestions',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.primaryBlue,
                      fontSize: 48,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Correct Answers',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Play again button
            ElevatedButton.icon(
              onPressed: () {
                provider.leaveRoom();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.home_rounded, size: 28),
              label: const Text('Back to Home'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(280, 72),
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
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
          style: AppTextStyles.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Stay',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TriviaProvider>().leaveRoom();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Leave screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}
