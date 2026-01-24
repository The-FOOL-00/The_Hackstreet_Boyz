/// Notification Provider
///
/// Manages notifications state and real-time updates.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  String? _currentUserId;
  String? _currentUserName;
  List<AppNotification> _notifications = [];
  List<Map<String, dynamic>> _buddyRequests = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<AppNotification>>? _notificationSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _requestsSubscription;

  // Getters
  List<AppNotification> get notifications => _notifications;
  List<Map<String, dynamic>> get buddyRequests => _buddyRequests;
  int get unreadCount => _unreadCount;
  int get pendingRequestsCount => _buddyRequests.length;
  bool get hasNotifications =>
      _notifications.isNotEmpty || _buddyRequests.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Initialize with user ID
  void init(String userId, String userName) {
    _currentUserId = userId;
    _currentUserName = userName;
    _startListening();
  }

  /// Start listening to notifications and buddy requests
  void _startListening() {
    if (_currentUserId == null) return;

    // Watch notifications
    _notificationSubscription?.cancel();
    _notificationSubscription = _service
        .watchNotifications(_currentUserId!)
        .listen(
          (notifications) {
            _notifications = notifications;
            _unreadCount = notifications.where((n) => !n.isRead).length;
            notifyListeners();
          },
          onError: (e) {
            _error = 'Failed to load notifications';
            notifyListeners();
          },
        );

    // Watch buddy requests
    _requestsSubscription?.cancel();
    _requestsSubscription = _service
        .watchBuddyRequests(_currentUserId!)
        .listen(
          (requests) {
            _buddyRequests = requests;
            notifyListeners();
          },
          onError: (e) {
            _error = 'Failed to load buddy requests';
            notifyListeners();
          },
        );
  }

  /// Send buddy invite
  Future<bool> sendBuddyInvite({
    required String toUserId,
    required String toUserName,
  }) async {
    if (_currentUserId == null || _currentUserName == null) return false;

    try {
      await _service.sendBuddyInvite(
        toUserId: toUserId,
        fromUserId: _currentUserId!,
        fromUserName: _currentUserName!,
      );
      return true;
    } catch (e) {
      _error = 'Failed to send invite: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Accept buddy request
  Future<bool> acceptBuddyRequest(Map<String, dynamic> request) async {
    if (_currentUserId == null || _currentUserName == null) return false;

    try {
      await _service.acceptBuddyRequest(
        requestId: request['id'] as String,
        myUserId: _currentUserId!,
        myUserName: _currentUserName!,
        fromUserId: request['fromUserId'] as String,
      );
      return true;
    } catch (e) {
      _error = 'Failed to accept request: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Decline buddy request
  Future<bool> declineBuddyRequest(String requestId) async {
    if (_currentUserId == null) return false;

    try {
      await _service.declineBuddyRequest(
        requestId: requestId,
        myUserId: _currentUserId!,
      );
      return true;
    } catch (e) {
      _error = 'Failed to decline request: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    if (_currentUserId == null) return;
    await _service.markAsRead(_currentUserId!, notificationId);
  }

  /// Mark all as read
  Future<void> markAllAsRead() async {
    if (_currentUserId == null) return;
    await _service.markAllAsRead(_currentUserId!);
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    if (_currentUserId == null) return;
    await _service.deleteNotification(_currentUserId!, notificationId);
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    if (_currentUserId == null) return;
    await _service.clearAllNotifications(_currentUserId!);
  }

  /// Check if users are buddies
  Future<bool> areBuddies(String otherUserId) async {
    if (_currentUserId == null) return false;
    return await _service.areBuddies(_currentUserId!, otherUserId);
  }

  /// Get buddy IDs
  Future<List<String>> getBuddyIds() async {
    if (_currentUserId == null) return [];
    return await _service.getBuddyIds(_currentUserId!);
  }

  /// Remove buddy
  Future<bool> removeBuddy(String buddyUserId) async {
    if (_currentUserId == null) return false;

    try {
      await _service.removeBuddy(_currentUserId!, buddyUserId);
      return true;
    } catch (e) {
      _error = 'Failed to remove buddy: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _requestsSubscription?.cancel();
    super.dispose();
  }
}
