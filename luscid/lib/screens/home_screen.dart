/// Home screen with main navigation
///
/// Central hub with main actions: Games, Friends, Activity, Help.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/utils/helpers.dart';
import '../providers/auth_provider.dart';
import '../providers/game_provider.dart';
import '../widgets/large_button.dart';
import 'difficulty_select_screen.dart';
import 'multiplayer_setup_screen.dart';
import 'activity_screen.dart';
import 'help_screen.dart';
import 'buddy_circle_screen.dart';
import 'shopping_game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final greeting = Helpers.getGreeting();

    return Scaffold(
      backgroundColor: AppColors.backgroundBeige,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('🧠', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Luscid',
                          style: AppTextStyles.heading3.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        Text('Memory Trainer', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Welcome message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$greeting! 👋', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    Text(
                      'Let\'s keep your mind active today 😊',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Main buttons
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Play Memory Game (Single Player)
                      LargeButton(
                        text: 'Play Memory Game',
                        emoji: '🧠',
                        isPrimary: true,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DifficultySelectScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Multiplayer Memory Game (Room Code)
                      LargeButton(
                        text: 'Multiplayer Game',
                        emoji: '🎮',
                        isPrimary: false,
                        onPressed: () {
                          // Set user ID for multiplayer
                          final gameProvider = context.read<GameProvider>();
                          gameProvider.setCurrentUserId(
                            authProvider.userId ??
                                'user_${DateTime.now().millisecondsSinceEpoch}',
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MultiplayerSetupScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Shopping List Game (New!)
                      LargeButton(
                        text: 'Shopping List Game',
                        emoji: '🛒',
                        isPrimary: true,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ShoppingGameScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Play with Friends (Buddy Circle)
                      LargeButton(
                        text: 'Play With Friends',
                        emoji: '👥',
                        isPrimary: false,
                        onPressed: () {
                          // Navigate to Buddy Circle to invite friends
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BuddyCircleScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Today's Activity
                      LargeButton(
                        text: 'Today\'s Activity',
                        emoji: '📅',
                        isPrimary: false,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ActivityScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      // Help
                      LargeButton(
                        text: 'Help',
                        emoji: '❓',
                        isPrimary: false,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HelpScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
