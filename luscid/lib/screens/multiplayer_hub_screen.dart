/// Multiplayer Hub Screen
///
/// Allows users to select which game to play in multiplayer mode.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../providers/game_provider.dart';
import '../providers/trivia_provider.dart';
import 'multiplayer_setup_screen.dart';
import 'shopping_multiplayer_setup_screen.dart';
import 'trivia_game_screen.dart';

class MultiplayerHubScreen extends StatelessWidget {
  const MultiplayerHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3B36)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Multiplayer',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3B36),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0ED),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Center(
                  child: Text('👥', style: TextStyle(fontSize: 50)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Choose a Game',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3B36),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select which game you want to play with your friend',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5C6B66),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Memory Game Option
              _buildGameCard(
                context: context,
                title: 'Memory Game',
                subtitle: 'Match pairs of cards together',
                emoji: '🧠',
                color: const Color(0xFF6B9080),
                onTap: () {
                  // Set user ID for multiplayer
                  final gameProvider = context.read<GameProvider>();
                  gameProvider.setCurrentUserId(
                    'user_${DateTime.now().millisecondsSinceEpoch}',
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MultiplayerSetupScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Shopping List Game Option
              _buildGameCard(
                context: context,
                title: 'Shopping List Game',
                subtitle: 'Memorize and find shopping items',
                emoji: '🛒',
                color: const Color(0xFFE8A87C),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ShoppingMultiplayerSetupScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // CineRecall (Movie Trivia) Option
              _buildGameCard(
                context: context,
                title: 'CineRecall',
                subtitle: 'Guess the movie from images & songs',
                emoji: '🎬',
                color: const Color(0xFF9B7EDE),
                onTap: () => _showCineRecallDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows dialog for CineRecall - Solo, Create, or Join Room
  void _showCineRecallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _CineRecallDialog(
        onSolo: () {
          Navigator.pop(dialogContext);
          _startSoloGame(context);
        },
        onCreate: () {
          Navigator.pop(dialogContext);
          _createCineRecallRoom(context);
        },
        onJoin: () {
          Navigator.pop(dialogContext);
          _showJoinCineRecallDialog(context);
        },
      ),
    );
  }

  /// Starts a solo CineRecall game
  void _startSoloGame(BuildContext context) {
    final triviaProvider = Provider.of<TriviaProvider>(context, listen: false);
    triviaProvider.startSoloGame();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TriviaGameScreen(
          roomCode: 'solo',
          isHost: true,
          isSolo: true,
        ),
      ),
    );
  }

  /// Creates a new CineRecall room
  Future<void> _createCineRecallRoom(BuildContext context) async {
    final triviaProvider = Provider.of<TriviaProvider>(context, listen: false);

    // Generate user ID
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    triviaProvider.setCurrentUser(userId);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final roomCode = await triviaProvider.createRoom(userId);

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        if (roomCode != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TriviaGameScreen(
                roomCode: roomCode,
                isHost: true,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(triviaProvider.error ?? 'Failed to create room'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create room: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Shows dialog to join an existing CineRecall room
  void _showJoinCineRecallDialog(BuildContext context) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Text(
          'Join Room',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3B36),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter the 4-digit room code',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF5C6B66),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '0000',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 28,
                  color: Colors.grey.shade300,
                  letterSpacing: 8,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF9B7EDE), width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.length == 4) {
                Navigator.pop(context);
                _joinCineRecallRoom(context, code);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B7EDE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Join',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Joins an existing CineRecall room
  Future<void> _joinCineRecallRoom(BuildContext context, String roomCode) async {
    final triviaProvider = Provider.of<TriviaProvider>(context, listen: false);

    // Generate user ID
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    triviaProvider.setCurrentUser(userId);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await triviaProvider.joinRoom(roomCode, userId);

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        if (result != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TriviaGameScreen(
                roomCode: roomCode,
                isHost: false,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(triviaProvider.error ?? 'Failed to join room'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildGameCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String emoji,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3B36),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF5C6B66),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog widget for CineRecall game mode selection
class _CineRecallDialog extends StatelessWidget {
  final VoidCallback onSolo;
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _CineRecallDialog({
    required this.onSolo,
    required this.onCreate,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF9B7EDE).withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text('🎬', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'CineRecall',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3B36),
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How would you like to play?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF5C6B66),
            ),
          ),
          const SizedBox(height: 24),

          // Play Solo Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSolo,
              icon: const Icon(Icons.person_rounded, size: 24),
              label: Text(
                'Play Solo',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B9080),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Create Room Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_circle_outline, size: 24),
              label: Text(
                'Create Room',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B7EDE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Join Room Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.group_rounded, size: 24),
              label: Text(
                'Join Room',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF9B7EDE),
                side: const BorderSide(color: Color(0xFF9B7EDE), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
