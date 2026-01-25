/// Caregiver Mock Data Service
///
/// Provides mock data for the Caregiver Dashboard MVP demo.
/// Replace with real data service in production.
library;

import 'package:flutter/material.dart';

// ==================== Data Models ====================

/// Senior's profile information
class SeniorProfile {
  final String name;
  final String status; // "Online" or "Offline"
  final String lastActive;
  final String mood; // Emoji
  final String avatarUrl;
  final int wellnessScore; // 0-100

  const SeniorProfile({
    required this.name,
    required this.status,
    required this.lastActive,
    required this.mood,
    this.avatarUrl = '',
    required this.wellnessScore,
  });

  bool get isOnline => status == 'Online';
}

/// Daily routine stat
class DailyStat {
  final String label;
  final String value;
  final String status; // "Good", "Attention", "Pending"
  final double progress; // 0.0 - 1.0

  const DailyStat({
    required this.label,
    required this.value,
    required this.status,
    required this.progress,
  });

  Color get statusColor {
    switch (status) {
      case 'Good':
        return const Color(0xFF22C55E); // Green
      case 'Attention':
        return const Color(0xFFEF4444); // Red
      case 'Pending':
        return const Color(0xFF94A3B8); // Gray
      default:
        return const Color(0xFFF59E0B); // Yellow/Amber
    }
  }
}

/// Cognitive game metric
class GameMetric {
  final String gameName;
  final String score;
  final String? reactionTime;
  final String trend; // "up", "down", "stable"
  final IconData icon;

  const GameMetric({
    required this.gameName,
    required this.score,
    this.reactionTime,
    required this.trend,
    required this.icon,
  });

  IconData get trendIcon {
    switch (trend) {
      case 'up':
        return Icons.trending_up_rounded;
      case 'down':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  Color get trendColor {
    switch (trend) {
      case 'up':
        return const Color(0xFF22C55E);
      case 'down':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

/// Activity log entry
class ActivityLog {
  final String time;
  final String event;
  final String type; // "routine", "game", "alert", "social"
  final DateTime timestamp;

  const ActivityLog({
    required this.time,
    required this.event,
    required this.type,
    required this.timestamp,
  });

  IconData get icon {
    switch (type) {
      case 'routine':
        return Icons.medication_rounded;
      case 'game':
        return Icons.sports_esports_rounded;
      case 'alert':
        return Icons.warning_rounded;
      case 'social':
        return Icons.people_rounded;
      case 'exercise':
        return Icons.directions_walk_rounded;
      case 'hydration':
        return Icons.water_drop_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  Color get backgroundColor {
    switch (type) {
      case 'routine':
        return const Color(0xFF22C55E); // Green
      case 'game':
        return const Color(0xFF3B82F6); // Blue
      case 'alert':
        return const Color(0xFFEF4444); // Red
      case 'social':
        return const Color(0xFF8B5CF6); // Purple
      case 'exercise':
        return const Color(0xFFF59E0B); // Amber
      case 'hydration':
        return const Color(0xFF06B6D4); // Cyan
      default:
        return const Color(0xFF64748B); // Slate
    }
  }
}

/// Routine period status
class RoutinePeriod {
  final String period; // "Morning", "Afternoon", "Evening"
  final double completion; // 0.0 - 1.0
  final bool isPastDue;
  final int completedTasks;
  final int totalTasks;

  const RoutinePeriod({
    required this.period,
    required this.completion,
    required this.isPastDue,
    required this.completedTasks,
    required this.totalTasks,
  });

  bool get needsAttention => completion < 0.5 && isPastDue;

  Color get statusColor {
    if (completion >= 1.0) return const Color(0xFF22C55E);
    if (needsAttention) return const Color(0xFFEF4444);
    if (completion > 0) return const Color(0xFFF59E0B);
    return const Color(0xFFE2E8F0);
  }

  IconData get statusIcon {
    if (completion >= 1.0) return Icons.check_circle_rounded;
    if (needsAttention) return Icons.error_rounded;
    if (completion > 0) return Icons.timelapse_rounded;
    return Icons.radio_button_unchecked_rounded;
  }
}

// ==================== Mock Data Service ====================

class MockCaregiverData {
  // Prevent instantiation
  MockCaregiverData._();

  /// Get senior profile
  static SeniorProfile getSeniorProfile() {
    return const SeniorProfile(
      name: 'Grandpa Joe',
      status: 'Online',
      lastActive: '2 mins ago',
      mood: '😊',
      wellnessScore: 92,
    );
  }

  /// Get today's routine periods
  static List<RoutinePeriod> getRoutinePeriods() {
    final now = DateTime.now();
    return [
      RoutinePeriod(
        period: 'Morning',
        completion: 1.0,
        isPastDue: now.hour >= 12,
        completedTasks: 3,
        totalTasks: 3,
      ),
      RoutinePeriod(
        period: 'Afternoon',
        completion: 0.5,
        isPastDue: now.hour >= 17,
        completedTasks: 1,
        totalTasks: 2,
      ),
      RoutinePeriod(
        period: 'Evening',
        completion: 0.0,
        isPastDue: false,
        completedTasks: 0,
        totalTasks: 2,
      ),
    ];
  }

  /// Get daily stats
  static List<DailyStat> getDailyStats() {
    return const [
      DailyStat(
        label: 'Routine Completion',
        value: '85%',
        status: 'Good',
        progress: 0.85,
      ),
      DailyStat(
        label: 'Hydration',
        value: '6/8 glasses',
        status: 'Good',
        progress: 0.75,
      ),
      DailyStat(
        label: 'Medicine',
        value: '1 pending',
        status: 'Attention',
        progress: 0.5,
      ),
    ];
  }

  /// Get cognitive game metrics
  static List<GameMetric> getGameMetrics() {
    return const [
      GameMetric(
        gameName: 'Memory Match',
        score: '12 Pairs',
        reactionTime: '1.8s',
        trend: 'up',
        icon: Icons.grid_view_rounded,
      ),
      GameMetric(
        gameName: 'Shopping List',
        score: '5/6 Items',
        reactionTime: '1.2s',
        trend: 'up',
        icon: Icons.shopping_cart_rounded,
      ),
      GameMetric(
        gameName: 'Reaction Speed',
        score: '1.4s avg',
        reactionTime: null,
        trend: 'stable',
        icon: Icons.speed_rounded,
      ),
      GameMetric(
        gameName: 'Word Recall',
        score: '8/10 Words',
        reactionTime: '2.1s',
        trend: 'down',
        icon: Icons.text_fields_rounded,
      ),
    ];
  }

  /// Get recent activity log
  static List<ActivityLog> getActivityLog() {
    final now = DateTime.now();
    return [
      ActivityLog(
        time: '10:30 AM',
        event: 'Completed Morning Meds',
        type: 'routine',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      ActivityLog(
        time: '10:15 AM',
        event: 'Played Memory Match with Arun',
        type: 'social',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 15)),
      ),
      ActivityLog(
        time: '9:45 AM',
        event: 'Scored 12 pairs in Memory Match',
        type: 'game',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 45)),
      ),
      ActivityLog(
        time: '9:30 AM',
        event: 'Completed morning walk',
        type: 'exercise',
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      ActivityLog(
        time: '9:00 AM',
        event: 'Had breakfast',
        type: 'routine',
        timestamp: now.subtract(const Duration(hours: 3, minutes: 30)),
      ),
      ActivityLog(
        time: '8:30 AM',
        event: 'Drank water - Glass 3/8',
        type: 'hydration',
        timestamp: now.subtract(const Duration(hours: 4)),
      ),
      ActivityLog(
        time: '2:00 PM',
        event: 'Missed afternoon medicine',
        type: 'alert',
        timestamp: now.subtract(const Duration(minutes: 30)),
      ),
    ];
  }

  /// Get wellness insights
  static List<String> getWellnessInsights() {
    return [
      '🎯 Memory scores improved 15% this week!',
      '💊 1 medicine reminder pending for today',
      '🚶 Completed 2,500 steps today',
      '🧠 Played 3 brain games this morning',
    ];
  }
}
