/// Reminder Service
///
/// Handles scheduled notifications for overdue tasks and
/// triggers avatar popup when user taps the notification.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/activity_model.dart';

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  
  // Callback when notification is tapped
  Function(String? payload)? onNotificationTapped;
  
  // Track which activities we've already reminded about today
  final Set<String> _remindedToday = {};

  /// Initialize the notification service
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      
      _isInitialized = true;
      debugPrint('✅ Reminder service initialized');
    } catch (e) {
      // Notifications may not be supported on desktop platforms
      debugPrint('⚠️ Notifications not available on this platform: $e');
      _isInitialized = true; // Mark as initialized to prevent retries
    }
  }

  /// Handle notification tap
  void _onNotificationResponse(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    onNotificationTapped?.call(response.payload);
  }

  /// Show an immediate reminder notification for an overdue task
  Future<void> showOverdueReminder(ActivityModel activity, {String? userName}) async {
    if (!_isInitialized) await init();
    
    // Don't remind twice for the same activity in a day
    if (_remindedToday.contains(activity.id)) return;
    _remindedToday.add(activity.id);
    
    final name = userName ?? 'friend';
    
    // Build a warm, friendly message
    String title;
    String body;
    
    if (activity.id == 'take_medicine') {
      title = '💊 Hey $name!';
      body = 'Just checking in - did you get a chance to take your medicine? Tap to chat with Buddy!';
    } else {
      title = '${activity.icon} Quick reminder!';
      body = 'Did we maybe forget about "${activity.title}"? Tap to talk to Buddy!';
    }
    
    try {
      const androidDetails = AndroidNotificationDetails(
        'luscid_reminders',
        'Task Reminders',
        channelDescription: 'Gentle reminders for daily tasks',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        styleInformation: BigTextStyleInformation(''),
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await _notifications.show(
        activity.id.hashCode,
        title,
        body,
        details,
        payload: 'overdue_task:${activity.id}',
      );
      
      debugPrint('🔔 Showed reminder for: ${activity.title}');
    } catch (e) {
      // Notifications not supported on this platform (e.g., Windows)
      debugPrint('⚠️ Could not show notification: $e');
    }
  }

  /// Schedule a reminder for a specific time
  Future<void> scheduleReminder({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (!_isInitialized) await init();
    
    // For simplicity, we'll use immediate notification check
    // In production, use zonedSchedule for exact timing
    debugPrint('📅 Reminder scheduled for: $scheduledTime');
  }

  /// Clear today's reminder tracking (call at midnight)
  void resetDailyReminders() {
    _remindedToday.clear();
  }

  /// Cancel all pending notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}

/// Extension to help with reminder messages
extension ReminderMessages on ActivityModel {
  /// Get a friendly reminder message for this activity
  String get friendlyReminderMessage {
    switch (id) {
      case 'take_medicine':
        return "Just a gentle nudge - your medicine was scheduled a while ago. It's important to stay on track! 💊";
      case 'drink_water':
        return "Hey there! Have you had some water recently? Staying hydrated is so important! 💧";
      case 'take_walk':
        return "How about a little stretch or walk? Even a few steps can feel great! 🚶";
      case 'play_game':
        return "Ready for some brain exercise? A quick memory game keeps the mind sharp! 🧠";
      default:
        return "Don't forget about '$title'! You've got this! ✨";
    }
  }

  /// Get a congratulatory message for completing this activity
  String get completionMessage {
    switch (id) {
      case 'take_medicine':
        return "Great job taking your medicine! Staying healthy is so important. I'm proud of you! 💊✨";
      case 'drink_water':
        return "Wonderful! Staying hydrated is the best thing you can do for yourself! 💧";
      case 'take_walk':
        return "Amazing! Every step counts. Your body thanks you! 🚶‍♀️🌟";
      case 'play_game':
        return "Fantastic! You're keeping that brain nice and sharp! 🧠💪";
      default:
        return "You did it! '$title' is done! Keep up the fantastic work! 🎉";
    }
  }
}
