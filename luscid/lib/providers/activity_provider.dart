/// Activity provider for daily checklist state management
///
/// Manages daily activities and their completion status.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/activity_model.dart';
import '../services/local_storage_service.dart';

class ActivityProvider extends ChangeNotifier {
  late final LocalStorageService _localStorage;

  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  String? _error;
  Timer? _reminderCheckTimer;

  // Callback for when a reminder should be shown
  Function(ActivityModel)? onReminderTriggered;

  ActivityProvider() {
    _localStorage = LocalStorageService();
    _startReminderChecker();
  }

  // Getters
  List<ActivityModel> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get completedCount => _activities.where((a) => a.isCompleted).length;
  int get totalCount => _activities.length;
  double get progress => totalCount > 0 ? completedCount / totalCount : 0;
  bool get allCompleted => completedCount == totalCount && totalCount > 0;

  /// Get pending (incomplete) activities
  List<ActivityModel> get pendingActivities =>
      _activities.where((a) => !a.isCompleted).toList();

  /// Get overdue activities
  List<ActivityModel> get overdueActivities =>
      _activities.where((a) => a.isOverdue).toList();

  /// Get completed activities
  List<ActivityModel> get completedActivities =>
      _activities.where((a) => a.isCompleted).toList();

  /// Get activities summary for AI context
  String getActivitiesSummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== TODAY\'S TASKS ===');
    
    for (final activity in _activities) {
      final status = activity.isCompleted ? '✅ DONE' : '⏳ PENDING';
      buffer.write('${activity.icon} ${activity.title}: $status');
      if (activity.scheduledTime != null) {
        final hour = activity.scheduledTime!.hour;
        final minute = activity.scheduledTime!.minute.toString().padLeft(2, '0');
        final ampm = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        buffer.write(' (scheduled: $displayHour:$minute $ampm)');
        if (activity.isOverdue) {
          buffer.write(' [OVERDUE!]');
        }
      }
      buffer.writeln();
    }
    
    buffer.writeln('');
    buffer.writeln('Completed: $completedCount/$totalCount');
    
    if (overdueActivities.isNotEmpty) {
      buffer.writeln('⚠️ OVERDUE TASKS: ${overdueActivities.map((a) => a.title).join(", ")}');
    }
    
    return buffer.toString();
  }

  /// Start periodic reminder checker
  void _startReminderChecker() {
    _reminderCheckTimer?.cancel();
    _reminderCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkForReminders();
    });
  }

  /// Check if any reminders should be triggered
  void _checkForReminders() {
    for (final activity in _activities) {
      if (activity.isOverdue && onReminderTriggered != null) {
        onReminderTriggered!(activity);
      }
    }
  }

  /// Force check reminders (for testing)
  void checkRemindersNow() {
    _checkForReminders();
  }

  /// Reset all activities to defaults (clears cache and reloads)
  Future<void> resetActivities() async {
    _setLoading(true);
    try {
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);
      _activities = DailyActivities.getDefaultActivities(todayOnly);
      await _localStorage.saveActivities(_activities);
      debugPrint('🔄 Activities reset to defaults: ${_activities.length} activities');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Reset error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Loads today's activities
  Future<void> loadActivities() async {
    _setLoading(true);
    try {
      _activities = await _localStorage.getTodaysActivities();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Marks an activity as complete
  Future<void> completeActivity(String activityId) async {
    final index = _activities.indexWhere((a) => a.id == activityId);
    if (index == -1) return;

    // Optimistic update
    _activities[index] = _activities[index].markComplete();
    notifyListeners();

    // Persist
    try {
      await _localStorage.completeActivity(activityId);
    } catch (e) {
      // Revert on error
      _activities = await _localStorage.getTodaysActivities();
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Marks the "play game" activity as complete
  Future<void> markGamePlayed() async {
    await completeActivity(DailyActivities.playGameId);
  }

  /// Checks if the game activity is completed
  bool get isGameActivityCompleted {
    final gameActivity = _activities.firstWhere(
      (a) => a.id == DailyActivities.playGameId,
      orElse: () => ActivityModel(
        id: '',
        title: '',
        description: '',
        icon: '',
        date: DateTime.now(),
      ),
    );
    return gameActivity.isCompleted;
  }

  /// Find activity by keyword (for voice commands)
  ActivityModel? findActivityByKeyword(String keyword) {
    final lower = keyword.toLowerCase();
    
    // Common keyword mappings
    final keywordMap = {
      'medicine': 'take_medicine',
      'tablet': 'take_medicine',
      'pill': 'take_medicine',
      'medication': 'take_medicine',
      'water': 'drink_water',
      'drink': 'drink_water',
      'hydrate': 'drink_water',
      'walk': 'take_walk',
      'walking': 'take_walk',
      'exercise': 'take_walk',
      'game': 'play_game',
      'memory': 'play_game',
      'brain': 'play_game',
    };
    
    // Check keyword map first
    for (final entry in keywordMap.entries) {
      if (lower.contains(entry.key)) {
        final activity = _activities.firstWhere(
          (a) => a.id == entry.value,
          orElse: () => ActivityModel(id: '', title: '', description: '', icon: '', date: DateTime.now()),
        );
        if (activity.id.isNotEmpty) return activity;
      }
    }
    
    // Fuzzy match on title
    for (final activity in _activities) {
      if (activity.title.toLowerCase().contains(lower) ||
          lower.contains(activity.title.toLowerCase().split(' ').first)) {
        return activity;
      }
    }
    
    return null;
  }

  /// Complete activity by keyword (for voice commands)
  Future<String> completeActivityByKeyword(String keyword) async {
    final activity = findActivityByKeyword(keyword);
    if (activity == null) {
      return "I couldn't find a task matching '$keyword'. What task did you complete?";
    }
    
    if (activity.isCompleted) {
      return "You've already completed '${activity.title}'! Great job keeping track! 🌟";
    }
    
    await completeActivity(activity.id);
    
    // Check if it was overdue
    if (activity.isOverdue) {
      return "Better late than never! '${activity.title}' is now done. Keep up the good work! 💪";
    }
    
    return "Wonderful! '${activity.title}' is done! ${_getCelebration()}";
  }

  /// Add a custom activity via voice command
  Future<String> addCustomActivity({
    required String title,
    String? description,
    DateTime? scheduledTime,
  }) async {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    
    final newActivity = ActivityModel(
      id: id,
      title: title,
      description: description ?? 'Added by you',
      icon: '📝',
      date: dateOnly,
      scheduledTime: scheduledTime,
      isCustom: true,
      reminderMinutes: scheduledTime != null ? 60 : null,
    );
    
    _activities.add(newActivity);
    await _localStorage.saveActivities(_activities);
    notifyListeners();
    
    if (scheduledTime != null) {
      final hour = scheduledTime.hour;
      final minute = scheduledTime.minute.toString().padLeft(2, '0');
      final ampm = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return "Got it! I've added '$title' to your list, scheduled for $displayHour:$minute $ampm. I'll remind you! 📋";
    }
    
    return "Done! '$title' is now on your to-do list. You've got this! 📋";
  }

  /// Remove/delete an activity by keyword
  Future<String> removeActivityByKeyword(String keyword) async {
    final activity = findActivityByKeyword(keyword);
    if (activity == null) {
      return "I couldn't find a task matching '$keyword' to remove.";
    }
    
    _activities.removeWhere((a) => a.id == activity.id);
    await _localStorage.saveActivities(_activities);
    notifyListeners();
    
    return "Removed '${activity.title}' from your list. One less thing to worry about! ✨";
  }

  String _getCelebration() {
    final celebrations = [
      "You're doing amazing! 🌟",
      "Keep it up, superstar! ⭐",
      "That's the spirit! 🎉",
      "You're on a roll! 🏆",
      "Fantastic work! 💫",
    ];
    return celebrations[DateTime.now().millisecond % celebrations.length];
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _reminderCheckTimer?.cancel();
    super.dispose();
  }
}
