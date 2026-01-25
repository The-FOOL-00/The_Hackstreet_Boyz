/// Push Notification Service
///
/// Handles Firebase Cloud Messaging (FCM) for push notifications
/// when the app is in background or terminated.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background message received: ${message.messageId}');
  // Handle background message if needed
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _currentUserId;
  String? _fcmToken;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Android notification channel for high importance notifications
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'luscid_notifications',
    'Luscid Notifications',
    description: 'Notifications for buddy invites and game events',
    importance: Importance.high,
    playSound: true,
  );

  /// Initialize push notifications
  Future<void> init(String userId) async {
    _currentUserId = userId;

    // Request permission
    await _requestPermission();

    // Initialize local notifications for foreground
    await _initLocalNotifications();

    // Get FCM token and save to database
    await _getAndSaveToken();

    // Listen for token refresh
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      _saveTokenToDatabase(token);
    });

    // Handle foreground messages
    _foregroundSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    debugPrint('✅ Push notification service initialized for user: $userId');
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('📱 Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications for foreground display
  Future<void> _initLocalNotifications() async {
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

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  /// Get FCM token and save to database
  Future<void> _getAndSaveToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        await _saveTokenToDatabase(_fcmToken!);
        debugPrint('📲 FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// Save FCM token to Firebase Database
  Future<void> _saveTokenToDatabase(String token) async {
    if (_currentUserId == null) return;

    try {
      await _database.ref('user_tokens/${_currentUserId}').set({
        'fcmToken': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updatedAt': ServerValue.timestamp,
      });
      _fcmToken = token;
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages - show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    final android = message.notification?.android;

    // Show local notification on Android
    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle notification tap from background
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.data}');
    // Navigate based on notification type
    _processNotificationData(message.data);
  }

  /// Handle local notification tap
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('🔔 Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _processNotificationData(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Process notification data for navigation
  void _processNotificationData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    
    switch (type) {
      case 'buddy_invite':
        // Navigate to notifications screen
        debugPrint('Navigate to buddy invites');
        break;
      case 'game_invite':
        final roomCode = data['roomCode'] as String?;
        debugPrint('Navigate to game room: $roomCode');
        break;
      case 'friend_online':
        debugPrint('Friend came online: ${data['friendName']}');
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  /// Get FCM token for a user (to send targeted notifications)
  Future<String?> getUserToken(String userId) async {
    try {
      final snapshot = await _database.ref('user_tokens/$userId/fcmToken').get();
      return snapshot.value as String?;
    } catch (e) {
      debugPrint('Error getting user token: $e');
      return null;
    }
  }

  /// Update user online status
  Future<void> setOnlineStatus(bool isOnline) async {
    if (_currentUserId == null) return;

    try {
      await _database.ref('user_status/${_currentUserId}').set({
        'isOnline': isOnline,
        'lastSeen': ServerValue.timestamp,
      });

      // Set up disconnect handler
      if (isOnline) {
        await _database.ref('user_status/${_currentUserId}').onDisconnect().set({
          'isOnline': false,
          'lastSeen': ServerValue.timestamp,
        });
      }
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  /// Watch a friend's online status
  Stream<bool> watchFriendOnlineStatus(String friendId) {
    return _database.ref('user_status/$friendId/isOnline').onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  /// Subscribe to topic for broadcast notifications
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  /// Clean up
  void dispose() {
    _foregroundSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
  }

  /// Remove token on logout
  Future<void> logout() async {
    if (_currentUserId != null) {
      await setOnlineStatus(false);
      await _database.ref('user_tokens/${_currentUserId}').remove();
    }
    _currentUserId = null;
    _fcmToken = null;
    dispose();
  }
}
