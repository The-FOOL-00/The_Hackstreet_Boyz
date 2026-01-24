/// Activity provider for daily checklist state management
///
/// Manages daily activities and their completion status.
library;

import 'package:flutter/foundation.dart';
import '../models/activity_model.dart';
import '../services/local_storage_service.dart';

class ActivityProvider extends ChangeNotifier {
  late final LocalStorageService _localStorage;

  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  String? _error;

  ActivityProvider() {
    _localStorage = LocalStorageService();
  }

  // Getters
  List<ActivityModel> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get completedCount => _activities.where((a) => a.isCompleted).length;
  int get totalCount => _activities.length;
  double get progress => totalCount > 0 ? completedCount / totalCount : 0;
  bool get allCompleted => completedCount == totalCount && totalCount > 0;

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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
