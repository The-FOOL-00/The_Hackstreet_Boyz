/// Multiplayer Hub Screen
///
/// Allows users to select which game to play in multiplayer mode.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../providers/game_provider.dart';
import '../providers/shopping_list_provider.dart';
import 'multiplayer_setup_screen.dart';
import 'shopping_multiplayer_setup_screen.dart';

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
            ],
          ),
        ),
      ),
    );
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
