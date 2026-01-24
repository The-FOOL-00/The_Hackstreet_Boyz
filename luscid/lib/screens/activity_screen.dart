/// Activity screen for daily checklist
///
/// Shows daily wellness activities with completion tracking.
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
            backgroundColor: AppColors.backgroundBeige,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text('Today\'s Activity', style: AppTextStyles.heading4),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress header
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
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activityProvider.allCompleted
                                        ? 'Great Job Today! 🎉'
                                        : 'Keep Going! 💪',
                                    style: AppTextStyles.heading4,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$completedCount of $totalCount completed',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: activityProvider.allCompleted
                                      ? AppColors.accentGreen.withOpacity(0.2)
                                      : AppColors.primaryBlue.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    activityProvider.allCompleted ? '✅' : '📅',
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 12,
                              backgroundColor: AppColors.borderLight,
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
                    // Activities list
                    Text('Daily Checklist', style: AppTextStyles.heading4),
                    const SizedBox(height: 16),
                    Expanded(
                      child: activities.isEmpty
                          ? const Center(child: Text('Loading activities...'))
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
                    // Encouragement
                    if (!activityProvider.allCompleted)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Small steps lead to big improvements!',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primaryBlue,
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
          ),
        );
      },
    );
  }
}
