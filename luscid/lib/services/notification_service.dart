/// Notification Service
///
/// Handles in-app and push notifications for buddy invites and game events.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

/// Notification types
enum NotificationType {
  buddyInvite,
  buddyAccepted,
  gameInvite,
  gameStarting,
  message,
}

/// Notification model
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? fromUserId;
  final String? fromUserName;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.fromUserId,
    this.fromUserName,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.message,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      fromUserId: json['fromUserId'] as String?,
      fromUserName: json['fromUserName'] as String?,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'body': body,
    'fromUserId': fromUserId,
    'fromUserName': fromUserName,
    'data': data,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'isRead': isRead,
  };

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    String? fromUserId,
    String? fromUserName,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Reference to notifications
  DatabaseReference _notificationsRef(String userId) =>
      _database.ref('notifications/$userId');

  /// Reference to buddy requests
  DatabaseReference _buddyRequestsRef(String userId) =>
      _database.ref('buddy_requests/$userId');

  /// Send a notification to a user
  Future<void> sendNotification({
    required String toUserId,
    required NotificationType type,
    required String title,
    required String body,
    String? fromUserId,
    String? fromUserName,
    Map<String, dynamic>? data,
  }) async {
    final notificationId = 'notif_${DateTime.now().millisecondsSinceEpoch}';

    final notification = AppNotification(
      id: notificationId,
      type: type,
      title: title,
      body: body,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      data: data,
      createdAt: DateTime.now(),
      isRead: false,
    );

    await _notificationsRef(
      toUserId,
    ).child(notificationId).set(notification.toJson());
  }

  /// Send buddy invite notification
  Future<void> sendBuddyInvite({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
  }) async {
    // Create buddy request record
    final requestId = 'req_${DateTime.now().millisecondsSinceEpoch}';
    await _buddyRequestsRef(toUserId).child(requestId).set({
      'id': requestId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    // Send notification
    await sendNotification(
      toUserId: toUserId,
      type: NotificationType.buddyInvite,
      title: 'Buddy Request',
      body: '$fromUserName wants to add you as a buddy!',
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      data: {'requestId': requestId},
    );
  }

  /// Accept buddy request
  Future<void> acceptBuddyRequest({
    required String requestId,
    required String myUserId,
    required String myUserName,
    required String fromUserId,
  }) async {
    // Update request status
    await _buddyRequestsRef(myUserId).child(requestId).update({
      'status': 'accepted',
      'acceptedAt': DateTime.now().millisecondsSinceEpoch,
    });

    // Add each other as buddies
    await _database.ref('buddies/$myUserId/$fromUserId').set({
      'addedAt': DateTime.now().millisecondsSinceEpoch,
    });
    await _database.ref('buddies/$fromUserId/$myUserId').set({
      'addedAt': DateTime.now().millisecondsSinceEpoch,
    });

    // Send notification to requester
    await sendNotification(
      toUserId: fromUserId,
      type: NotificationType.buddyAccepted,
      title: 'Buddy Accepted! 🎉',
      body: '$myUserName accepted your buddy request!',
      fromUserId: myUserId,
      fromUserName: myUserName,
    );
  }

  /// Decline buddy request
  Future<void> declineBuddyRequest({
    required String requestId,
    required String myUserId,
  }) async {
    await _buddyRequestsRef(myUserId).child(requestId).update({
      'status': 'declined',
      'declinedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Get pending buddy requests
  Stream<List<Map<String, dynamic>>> watchBuddyRequests(String userId) {
    return _buddyRequestsRef(userId).onValue.map((event) {
      if (!event.snapshot.exists) return [];

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final requests = <Map<String, dynamic>>[];

      data.forEach((key, value) {
        final request = Map<String, dynamic>.from(value as Map);
        if (request['status'] == 'pending') {
          requests.add(request);
        }
      });

      // Sort by newest first
      requests.sort(
        (a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int),
      );

      return requests;
    });
  }

  /// Watch notifications stream
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _notificationsRef(userId).orderByChild('createdAt').onValue.map((
      event,
    ) {
      if (!event.snapshot.exists) return [];

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final notifications = <AppNotification>[];

      data.forEach((key, value) {
        notifications.add(
          AppNotification.fromJson(Map<String, dynamic>.from(value as Map)),
        );
      });

      // Sort by newest first
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notifications;
    });
  }

  /// Get unread notification count
  Stream<int> watchUnreadCount(String userId) {
    return watchNotifications(
      userId,
    ).map((notifications) => notifications.where((n) => !n.isRead).length);
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    await _notificationsRef(
      userId,
    ).child(notificationId).update({'isRead': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final snapshot = await _notificationsRef(userId).get();
    if (!snapshot.exists) return;

    final updates = <String, dynamic>{};
    final data = Map<String, dynamic>.from(snapshot.value as Map);

    data.forEach((key, value) {
      updates['$key/isRead'] = true;
    });

    await _notificationsRef(userId).update(updates);
  }

  /// Delete a notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _notificationsRef(userId).child(notificationId).remove();
  }

  /// Clear all notifications
  Future<void> clearAllNotifications(String userId) async {
    await _notificationsRef(userId).remove();
  }

  /// Check if users are buddies
  Future<bool> areBuddies(String userId1, String userId2) async {
    final snapshot = await _database.ref('buddies/$userId1/$userId2').get();
    return snapshot.exists;
  }

  /// Get all buddies for a user
  Future<List<String>> getBuddyIds(String userId) async {
    final snapshot = await _database.ref('buddies/$userId').get();
    if (!snapshot.exists) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return data.keys.toList();
  }

  /// Remove buddy
  Future<void> removeBuddy(String myUserId, String buddyUserId) async {
    await _database.ref('buddies/$myUserId/$buddyUserId').remove();
    await _database.ref('buddies/$buddyUserId/$myUserId').remove();
  }
}
