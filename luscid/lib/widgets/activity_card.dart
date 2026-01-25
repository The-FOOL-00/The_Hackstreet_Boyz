/// Activity card widget for daily checklist
///
/// Large, accessible card showing activity with completion button.
library;

import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';

class ActivityCard extends StatelessWidget {
  final ActivityModel activity;
  final VoidCallback? onMarkComplete;

  const ActivityCard({super.key, required this.activity, this.onMarkComplete});

  String _formatScheduledTime(ActivityModel activity) {
    if (activity.scheduledTime == null) return '';
    
    final time = activity.scheduledTime!;
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    if (activity.isCompleted) {
      return 'Completed ✓';
    } else if (activity.isOverdue) {
      return 'Overdue (was $displayHour:$minute $ampm)';
    }
    return 'Scheduled: $displayHour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: activity.isCompleted
            ? AppColors.accentGreen.withOpacity(0.1)
            : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activity.isCompleted
              ? AppColors.accentGreen
              : AppColors.borderLight,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Icon/Emoji
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: activity.isCompleted
                    ? AppColors.accentGreen.withOpacity(0.2)
                    : AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  activity.icon,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: AppTextStyles.heading4.copyWith(
                      color: activity.isCompleted
                          ? AppColors.accentGreen
                          : AppColors.textPrimary,
                      decoration: activity.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: activity.isCompleted
                          ? AppColors.textLight
                          : AppColors.textSecondary,
                    ),
                  ),
                  // Show scheduled time if available
                  if (activity.scheduledTime != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          activity.isOverdue
                              ? Icons.warning_amber_rounded
                              : Icons.schedule_rounded,
                          size: 14,
                          color: activity.isCompleted
                              ? AppColors.accentGreen
                              : (activity.isOverdue
                                  ? Colors.orange.shade700
                                  : AppColors.primaryBlue),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatScheduledTime(activity),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: activity.isCompleted
                                ? AppColors.accentGreen
                                : (activity.isOverdue
                                    ? Colors.orange.shade700
                                    : AppColors.primaryBlue),
                            fontWeight: activity.isOverdue
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Action
            if (activity.isCompleted)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.textOnPrimary,
                  size: 28,
                ),
              )
            else
              ElevatedButton(
                onPressed: onMarkComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  foregroundColor: AppColors.textOnPrimary,
                  minimumSize: const Size(80, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Done',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
