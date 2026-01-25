/// Home screen with main navigation
///
/// Stitch Design: Header with pill badge, card-style nav buttons, decorative circles.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/utils/helpers.dart';
import '../widgets/large_button.dart';
import '../widgets/buddy_fab.dart';
import '../widgets/buddy_popup.dart';
import '../providers/activity_provider.dart';
import '../models/activity_model.dart';
import '../services/reminder_service.dart';
import 'game_mode_screen.dart';
import 'activity_screen.dart';
import 'help_screen.dart';
import 'buddy_circle_screen.dart';
import 'phone_auth_screen.dart';
import '../widgets/notification_bell.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ReminderService _reminderService = ReminderService();

  @override
  void initState() {
    super.initState();
    _setupReminderService();
  }

  void _setupReminderService() async {
    await _reminderService.init();
    
    // Set up notification tap handler
    _reminderService.onNotificationTapped = (payload) {
      if (payload != null && payload.startsWith('overdue_task:')) {
        final activityId = payload.replaceFirst('overdue_task:', '');
        // Show Buddy popup for the overdue task
        if (mounted) {
          showBuddyReminderPopup(
            context,
            activityId: activityId,
            userName: 'friend', // TODO: Get from user profile
          );
        }
      }
    };
    
    // Set up activity provider reminder callback
    final activities = context.read<ActivityProvider>();
    activities.onReminderTriggered = (activity) async {
      await _reminderService.showOverdueReminder(activity, userName: 'friend');
    };
  }

  /// Simulate medicine reminder (for testing)
  void _simulateMedicineReminder() async {
    final activities = context.read<ActivityProvider>();
    
    debugPrint('🧪 Testing medicine reminder...');
    debugPrint('📋 Total activities: ${activities.activities.length}');
    
    // If medicine activity doesn't exist, reset activities first
    final hasMedicine = activities.activities.any((a) => a.id == 'take_medicine');
    if (!hasMedicine) {
      debugPrint('⚠️ Medicine not found, resetting activities...');
      await activities.resetActivities();
      debugPrint('📋 After reset: ${activities.activities.length} activities');
    }
    
    // Find the medicine activity
    ActivityModel? medicineActivity;
    try {
      medicineActivity = activities.activities.firstWhere(
        (a) => a.id == 'take_medicine',
      );
    } catch (e) {
      debugPrint('❌ Medicine activity still not found after reset!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load medicine activity. Try restarting the app.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    debugPrint('✅ Found medicine: ${medicineActivity.title}, completed: ${medicineActivity.isCompleted}');
    
    if (medicineActivity.isCompleted) {
      // Reset activities to test again
      await activities.resetActivities();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activities reset! Tap again to test reminder.'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }
    
    // Show notification on mobile
    try {
      await _reminderService.showOverdueReminder(
        medicineActivity,
        userName: 'friend',
      );
      debugPrint('🔔 Notification sent');
    } catch (e) {
      debugPrint('⚠️ Notification error: $e');
    }
    
    // Show the Buddy popup directly
    if (mounted) {
      debugPrint('💬 Showing Buddy popup...');
      await showBuddyReminderPopup(
        context,
        activityId: 'take_medicine',
        userName: 'friend',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final greeting = Helpers.getGreeting();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Stitch: Decorative blur circle top-right
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
          // Stitch: Decorative blur circle bottom-left
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft.withOpacity(0.5),
              ),
            ),
          ),
          // Main content area
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stitch: Header with logo and pill
                  Row(
                    children: [
                      // Logo container
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryBlue, Color(0xFF60A5FA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🧠', style: TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Luscid',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            // Stitch: Pill badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Memory Trainer',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Notification Bell
                      const NotificationBell(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Stitch: Welcome card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundWhite,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderBlue, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowCard,
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$greeting! 👋',
                                style: AppTextStyles.heading3.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
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
                        // Decorative icon
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.accentBlueLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text('✨', style: TextStyle(fontSize: 28)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Main buttons
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Play Memory Game (Single Player)
                          LargeButton(
                            text: 'Memory Game',
                            subtitle: 'Train your memory',
                            emoji: '🧠',
                            isPrimary: true,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const GameModeScreen(
                                    gameType: GameType.memory,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          // Shopping List Game
                          LargeButton(
                            text: 'Shopping List',
                            subtitle: 'Remember items',
                            emoji: '🛒',
                            isPrimary: true,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const GameModeScreen(
                                    gameType: GameType.shopping,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          // Play with Friends (Buddy Circle)
                          LargeButton(
                            text: 'Play With Friends',
                            subtitle: 'Invite your buddies',
                            emoji: '👥',
                            isPrimary: false,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const BuddyCircleScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          // Today's Activity
                          LargeButton(
                            text: 'Today\'s Activity',
                            subtitle: 'Track your progress',
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
                          const SizedBox(height: 14),
                          // Help
                          LargeButton(
                            text: 'Help',
                            subtitle: 'How to play',
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
                          const SizedBox(height: 14),
                          // Phone Login Test
                          LargeButton(
                            text: 'Phone Login',
                            subtitle: 'Test authentication',
                            emoji: '📱',
                            isPrimary: false,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PhoneAuthScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          // Test Medicine Reminder (Demo)
                          LargeButton(
                            text: 'Test Reminder',
                            subtitle: 'Simulate medicine alert',
                            emoji: '💊',
                            isPrimary: false,
                            onPressed: _simulateMedicineReminder,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Floating Buddy FAB - bottom right corner
          Positioned(
            bottom: 100,
            right: 20,
            child: BuddyFab(),
          ),
        ],
      ),
    );
  }
}
