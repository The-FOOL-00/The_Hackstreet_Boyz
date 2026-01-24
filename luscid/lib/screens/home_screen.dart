/// Home screen with main navigation
///
/// Central hub with four main actions: Play, Multiplayer, Activity, Help.
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
              const SizedBox(height: 32),
              // Main buttons
              Expanded(
                child: Column(
                  children: [
                    // Play Memory Game
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
                    const SizedBox(height: 16),
                    // Play with Someone
                    LargeButton(
                      text: 'Play With Someone',
                      emoji: '👥',
                      isPrimary: false,
                      onPressed: () {
                        // Set user ID for multiplayer
                        final gameProvider = context.read<GameProvider>();
                        gameProvider.setCurrentUserId(
                          authProvider.userId ?? '',
                        );

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MultiplayerSetupScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    // Help
                    LargeButton(
                      text: 'Help',
                      emoji: '❓',
                      isPrimary: false,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const HelpScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
