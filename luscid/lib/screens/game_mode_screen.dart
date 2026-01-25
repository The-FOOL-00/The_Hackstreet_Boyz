/// Game Mode Selection Screen
///
/// Allows users to choose between Solo, With Bot, or Multiplayer modes.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/constants/game_icons.dart'; // For GameDifficulty enum
import '../providers/game_provider.dart';
import '../providers/shopping_list_provider.dart';
import 'difficulty_select_screen.dart';
import 'game_screen.dart';
import 'shopping_game_screen.dart';
import 'multiplayer_setup_screen.dart';
import 'shopping_multiplayer_setup_screen.dart';

enum GameType { memory, shopping }

class GameModeScreen extends StatelessWidget {
  final GameType gameType;

  const GameModeScreen({super.key, required this.gameType});

  String get _gameTitle =>
      gameType == GameType.memory ? 'Memory Game' : 'Shopping List Game';

  String get _gameEmoji => gameType == GameType.memory ? '🧠' : '🛒';

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
        title: Text(_gameTitle, style: AppTextStyles.heading4),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Game icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0ED),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(_gameEmoji, style: const TextStyle(fontSize: 50)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'How would you like to play?',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3B36),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Solo Mode
              _buildModeCard(
                context: context,
                title: 'Solo',
                subtitle: 'Practice on your own',
                emoji: '🎯',
                color: const Color(0xFF6B9080),
                onTap: () => _navigateToSolo(context),
              ),
              const SizedBox(height: 16),

              // With Bot Mode
              _buildModeCard(
                context: context,
                title: 'With Bot',
                subtitle: 'Play against AI opponent',
                emoji: '🤖',
                color: const Color(0xFFE8A87C),
                onTap: () => _navigateToBot(context),
              ),
              const SizedBox(height: 16),

              // Multiplayer Mode
              _buildModeCard(
                context: context,
                title: 'Multiplayer',
                subtitle: 'Play with a friend',
                emoji: '👥',
                color: const Color(0xFF85C1E9),
                onTap: () => _navigateToMultiplayer(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D3B36),
                      ),
                    ),
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
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSolo(BuildContext context) {
    if (gameType == GameType.memory) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DifficultySelectScreen(isMultiplayer: false),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShoppingDifficultyScreen(mode: ShoppingGameMode.solo),
        ),
      );
    }
  }

  void _navigateToBot(BuildContext context) {
    if (gameType == GameType.memory) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MemoryBotDifficultyScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShoppingDifficultyScreen(mode: ShoppingGameMode.bot),
        ),
      );
    }
  }

  void _navigateToMultiplayer(BuildContext context) {
    if (gameType == GameType.memory) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MultiplayerSetupScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ShoppingMultiplayerSetupScreen()),
      );
    }
  }
}

/// Shopping Game Mode
enum ShoppingGameMode { solo, bot, multiplayer }

/// Shopping Difficulty Screen
class ShoppingDifficultyScreen extends StatelessWidget {
  final ShoppingGameMode mode;

  const ShoppingDifficultyScreen({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3B36)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose Difficulty',
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
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('🛒', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      mode == ShoppingGameMode.bot
                          ? 'Playing against Bot 🤖'
                          : 'Solo Practice',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF5C6B66),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Easy
              _buildDifficultyCard(
                context: context,
                title: 'Easy',
                subtitle: '6 Items • 45s to memorize',
                emoji: '😊',
                color: const Color(0xFF6B9080),
                onTap: () => _startGame(context, ShoppingDifficulty.easy),
              ),
              const SizedBox(height: 16),

              // Medium
              _buildDifficultyCard(
                context: context,
                title: 'Medium',
                subtitle: '8 Items • 30s to memorize',
                emoji: '🤔',
                color: const Color(0xFFE8A87C),
                onTap: () => _startGame(context, ShoppingDifficulty.medium),
              ),
              const SizedBox(height: 16),

              // Hard
              _buildDifficultyCard(
                context: context,
                title: 'Hard',
                subtitle: '12 Items • 20s to memorize',
                emoji: '😤',
                color: const Color(0xFFE57373),
                onTap: () => _startGame(context, ShoppingDifficulty.hard),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyCard({
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
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
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context, ShoppingDifficulty difficulty) {
    final provider = context.read<ShoppingListProvider>();

    // Initialize with temp user ID
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    provider.init(userId);

    // Get settings based on difficulty
    final settings = _getDifficultySettings(difficulty);

    if (mode == ShoppingGameMode.bot) {
      // Start game with bot
      provider.createSoloOrBotGame(
        targetItemCount: settings['items']!,
        memorizeTimeSeconds: settings['memorizeTime']!,
        selectionTimeSeconds: settings['selectionTime']!,
        withBot: true,
      );
    } else {
      // Start solo game
      provider.createSoloOrBotGame(
        targetItemCount: settings['items']!,
        memorizeTimeSeconds: settings['memorizeTime']!,
        selectionTimeSeconds: settings['selectionTime']!,
        withBot: false,
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ShoppingGameScreen()),
    );
  }

  Map<String, int> _getDifficultySettings(ShoppingDifficulty difficulty) {
    switch (difficulty) {
      case ShoppingDifficulty.easy:
        return {'items': 6, 'memorizeTime': 45, 'selectionTime': 90};
      case ShoppingDifficulty.medium:
        return {'items': 8, 'memorizeTime': 30, 'selectionTime': 60};
      case ShoppingDifficulty.hard:
        return {'items': 12, 'memorizeTime': 20, 'selectionTime': 45};
    }
  }
}

enum ShoppingDifficulty { easy, medium, hard }

/// Memory Game with Bot - Difficulty Selection
class MemoryBotDifficultyScreen extends StatelessWidget {
  const MemoryBotDifficultyScreen({super.key});

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
          'Choose Difficulty',
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
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text('🧠', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(
                      'Playing against Bot 🤖',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF5C6B66),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Easy
              _buildDifficultyCard(
                context: context,
                difficulty: GameDifficulty.easy,
                title: 'Easy',
                subtitle: '2×2 Grid • 2 Pairs',
                emoji: '😊',
                color: const Color(0xFF6B9080),
              ),
              const SizedBox(height: 16),

              // Medium
              _buildDifficultyCard(
                context: context,
                difficulty: GameDifficulty.medium,
                title: 'Medium',
                subtitle: '4×4 Grid • 8 Pairs',
                emoji: '🤔',
                color: const Color(0xFFE8A87C),
              ),
              const SizedBox(height: 16),

              // Hard
              _buildDifficultyCard(
                context: context,
                difficulty: GameDifficulty.hard,
                title: 'Hard',
                subtitle: '6×6 Grid • 18 Pairs',
                emoji: '😤',
                color: const Color(0xFFE57373),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _startBotGame(context, difficulty),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
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
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _startBotGame(BuildContext context, GameDifficulty difficulty) {
    final gameProvider = context.read<GameProvider>();
    gameProvider.startBotGame(difficulty);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }
}
