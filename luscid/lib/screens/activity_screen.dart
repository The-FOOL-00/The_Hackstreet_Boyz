/// Activity screen for daily checklist
///
/// Stitch Design: Progress ring, card-style checklist, decorative circles.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../providers/activity_provider.dart';
import '../widgets/activity_card.dart';
import '../widgets/loading_overlay.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    // Load activities
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().loadActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        final activities = activityProvider.activities;
        final progress = activityProvider.progress;
        final completedCount = activityProvider.completedCount;
        final totalCount = activityProvider.totalCount;

        return LoadingOverlay(
          isLoading: activityProvider.isLoading,
          child: Scaffold(
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
                              'Today\'s Activity',
                              style: AppTextStyles.heading4.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      // Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stitch: Progress header card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundWhite,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: AppColors.borderBlue),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.shadowCard,
                                      blurRadius: 20,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                activityProvider.allCompleted
                                                    ? 'Great Job Today! 🎉'
                                                    : 'Keep Going! 💪',
                                                style: AppTextStyles.heading4.copyWith(
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primarySoft,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '$completedCount of $totalCount completed',
                                                  style: AppTextStyles.labelSmall.copyWith(
                                                    color: AppColors.primaryBlue,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Stitch: Progress ring
                                        SizedBox(
                                          width: 72,
                                          height: 72,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              SizedBox(
                                                width: 72,
                                                height: 72,
                                                child: CircularProgressIndicator(
                                                  value: progress,
                                                  strokeWidth: 6,
                                                  backgroundColor: AppColors.borderBlue,
                                                  valueColor: AlwaysStoppedAnimation(
                                                    activityProvider.allCompleted
                                                        ? AppColors.accentGreen
                                                        : AppColors.primaryBlue,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                activityProvider.allCompleted ? '✅' : '📅',
                                                style: const TextStyle(fontSize: 28),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    // Progress bar
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        minHeight: 10,
                                        backgroundColor: AppColors.borderBlue,
                                        valueColor: AlwaysStoppedAnimation(
                                          activityProvider.allCompleted
                                              ? AppColors.accentGreen
                                              : AppColors.primaryBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Activities list header
                              Text(
                                'Daily Checklist',
                                style: AppTextStyles.heading4.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Expanded(
                                child: activities.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 64,
                                              height: 64,
                                              decoration: BoxDecoration(
                                                color: AppColors.primarySoft,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Loading activities...',
                                              style: AppTextStyles.bodyMedium.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: activities.length,
                                        itemBuilder: (context, index) {
                                          final activity = activities[index];
                                          return ActivityCard(
                                            activity: activity,
                                            onMarkComplete: () {
                                              activityProvider.completeActivity(
                                                activity.id,
                                              );
                                            },
                                          );
                                        },
                                      ),
                              ),
                              // Stitch: Encouragement card
                              if (!activityProvider.allCompleted)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 16),
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
                                          'Small steps lead to big improvements!',
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
