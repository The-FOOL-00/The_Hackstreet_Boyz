/// Buddy List Provider
///
/// Manages buddy list state and real-time status updates.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/contact_service.dart';

class BuddyListProvider extends ChangeNotifier {
  final ContactService _contactService = ContactService();

  List<Buddy> _buddies = [];
  bool _isLoading = false;
  String? _error;
  bool _hasPermission = false;
  String? _currentUserId;

  StreamSubscription<List<Buddy>>? _buddySubscription;

  // Getters
  List<Buddy> get buddies => _buddies;
  List<Buddy> get onlineBuddies => _buddies.where((b) => b.isOnline).toList();
  List<Buddy> get offlineBuddies => _buddies.where((b) => !b.isOnline).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasPermission => _hasPermission;
  bool get hasBuddies => _buddies.isNotEmpty;

  /// Initializes the provider with current user ID
  Future<void> init(String userId) async {
    _currentUserId = userId;
    await _checkPermission();
  }

  /// Checks and requests contacts permission
  Future<bool> _checkPermission() async {
    _hasPermission = await _contactService.hasContactsPermission();
    notifyListeners();
    return _hasPermission;
  }

  /// Requests contacts permission
  Future<bool> requestPermission() async {
    _hasPermission = await _contactService.requestContactsPermission();
    notifyListeners();
    return _hasPermission;
  }

  /// Loads buddies from contacts
  Future<void> loadBuddies() async {
    // Generate a temporary user ID if not set
    _currentUserId ??= 'user_${DateTime.now().millisecondsSinceEpoch}';

    if (!_hasPermission) {
      final granted = await requestPermission();
      if (!granted) {
        _error = 'Contacts permission is required to find buddies';
        notifyListeners();
        return;
      }
    }

    _setLoading(true);
    _clearError();

    try {
      _buddies = await _contactService.findBuddies(excludeUid: _currentUserId!);

      // Start watching for status changes
      _startWatchingBuddies();
    } catch (e) {
      _error = 'Failed to load buddies: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  /// Starts watching buddy status changes
  void _startWatchingBuddies() {
    _buddySubscription?.cancel();

    if (_buddies.isEmpty || _currentUserId == null) return;

    final buddyUids = _buddies.map((b) => b.uid).toList();

    _buddySubscription = _contactService
        .watchBuddies(excludeUid: _currentUserId!, buddyUids: buddyUids)
        .listen((updatedBuddies) {
          // Update buddies while preserving contact names
          final nameMap = {for (var b in _buddies) b.uid: b.displayName};

          _buddies = updatedBuddies.map((b) {
            // Use saved contact name if available
            final savedName = nameMap[b.uid];
            if (savedName != null && savedName != 'User') {
              return Buddy(
                uid: b.uid,
                displayName: savedName,
                phone: b.phone,
                status: b.status,
                lastActive: b.lastActive,
                photoUrl: b.photoUrl,
              );
            }
            return b;
          }).toList();

          notifyListeners();
        });
  }

  /// Refreshes buddy list
  Future<void> refresh() async {
    await loadBuddies();
  }

  /// Gets a buddy by ID
  Buddy? getBuddyById(String uid) {
    try {
      return _buddies.firstWhere((b) => b.uid == uid);
    } catch (_) {
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _buddySubscription?.cancel();
    super.dispose();
  }
}
