/// Local storage service for persisting data
///
/// Handles PIN storage, session management, and activity data persistence.
library;

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';

class LocalStorageService {
  static const String _userKey = 'luscid_user';
  static const String _activitiesKey = 'luscid_activities';
  static const String _lastActivityDateKey = 'luscid_last_activity_date';
  static const String _isFirstLaunchKey = 'luscid_first_launch';

  // Singleton instance
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static SharedPreferences? _prefs;

  /// Initialize the service - must be called before using the service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Gets SharedPreferences instance (initializes if needed)
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==================== User Management ====================

  /// Saves user data locally
  Future<bool> saveUser(UserModel user) async {
    final p = await prefs;
    return p.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Gets saved user data
  Future<UserModel?> getUser() async {
    final p = await prefs;
    final data = p.getString(_userKey);
    if (data == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(data) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Removes user data (logout)
  Future<bool> removeUser() async {
    final p = await prefs;
    return p.remove(_userKey);
  }

  /// Checks if user is logged in
  Future<bool> isLoggedIn() async {
    final user = await getUser();
    return user != null;
  }

  // ==================== First Launch ====================

  /// Checks if this is the first app launch
  Future<bool> isFirstLaunch() async {
    final p = await prefs;
    return p.getBool(_isFirstLaunchKey) ?? true;
  }

  /// Marks that the app has been launched before
  Future<bool> setFirstLaunchComplete() async {
    final p = await prefs;
    return p.setBool(_isFirstLaunchKey, false);
  }

  // ==================== Activity Management ====================

  /// Saves daily activities
  Future<bool> saveActivities(List<ActivityModel> activities) async {
    final p = await prefs;
    final data = activities.map((a) => a.toJson()).toList();
    return p.setString(_activitiesKey, jsonEncode(data));
  }

  /// Gets saved activities
  Future<List<ActivityModel>> getActivities() async {
    final p = await prefs;
    final data = p.getString(_activitiesKey);
    if (data == null) return [];
    try {
      final list = jsonDecode(data) as List;
      return list
          .map((item) => ActivityModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets the last date activities were updated
  Future<DateTime?> getLastActivityDate() async {
    final p = await prefs;
    final timestamp = p.getInt(_lastActivityDateKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Sets the last activity date
  Future<bool> setLastActivityDate(DateTime date) async {
    final p = await prefs;
    return p.setInt(_lastActivityDateKey, date.millisecondsSinceEpoch);
  }

  /// Gets today's activities (resets if new day)
  Future<List<ActivityModel>> getTodaysActivities() async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final lastDate = await getLastActivityDate();

    // Check if we need to reset for a new day
    if (lastDate == null ||
        lastDate.year != todayOnly.year ||
        lastDate.month != todayOnly.month ||
        lastDate.day != todayOnly.day) {
      // New day - create fresh activities
      final activities = DailyActivities.getDefaultActivities(todayOnly);
      await saveActivities(activities);
      await setLastActivityDate(todayOnly);
      return activities;
    }

    // Same day - return saved activities
    final saved = await getActivities();
    if (saved.isEmpty) {
      final activities = DailyActivities.getDefaultActivities(todayOnly);
      await saveActivities(activities);
      return activities;
    }
    return saved;
  }

  /// Marks an activity as complete
  Future<bool> completeActivity(String activityId) async {
    final activities = await getTodaysActivities();
    final index = activities.indexWhere((a) => a.id == activityId);
    if (index == -1) return false;

    activities[index] = activities[index].markComplete();
    return saveActivities(activities);
  }

  // ==================== Clear All Data ====================

  /// Clears all local storage data
  Future<bool> clearAll() async {
    final p = await prefs;
    return p.clear();
  }
}
