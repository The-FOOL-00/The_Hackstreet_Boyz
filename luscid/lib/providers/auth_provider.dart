/// Authentication provider for state management
///
/// Manages user authentication state across the app.
library;

import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../services/push_notification_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  late final AuthService _authService;
  late final LocalStorageService _localStorage;
  final PushNotificationService _pushService = PushNotificationService();
  final NotificationService _notificationService = NotificationService();
  bool _initialized = false;

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isFirstLaunch = true;

  AuthProvider() {
    _authService = AuthService();
    _localStorage = LocalStorageService();
  }

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isFirstLaunch => _isFirstLaunch;
  String? get userId => _user?.uid;

  /// Initializes the provider
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _setLoading(true);
    try {
      _isFirstLaunch = await _localStorage.isFirstLaunch();

      // Try auto login
      final savedUser = await _authService.autoLogin();
      if (savedUser != null) {
        _user = savedUser;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Creates a new user account
  Future<bool> createAccount({
    required String pin,
    required UserRole role,
    String? displayName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.createUser(
        pin: pin,
        role: role,
        displayName: displayName,
      );

      if (user != null) {
        _user = user;
        _isFirstLaunch = false;
        
        // Initialize push notifications
        await _pushService.init(user.uid);
        await _pushService.setOnlineStatus(true);
        
        // Notify buddies user is online
        await _notificationService.notifyBuddiesOnline(
          userId: user.uid,
          userName: user.displayName ?? 'A friend',
        );
        
        notifyListeners();
        return true;
      }
      _error = 'Failed to create account';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Signs in with PIN
  Future<bool> signIn(String pin) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signInWithPin(pin);
      if (user != null) {
        _user = user;
        
        // Initialize push notifications
        await _pushService.init(user.uid);
        await _pushService.setOnlineStatus(true);
        
        // Notify buddies user is online
        await _notificationService.notifyBuddiesOnline(
          userId: user.uid,
          userName: user.displayName ?? 'A friend',
        );
        
        notifyListeners();
        return true;
      }
      _error = 'Invalid PIN';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Signs out the user
  Future<void> signOut() async {
    _setLoading(true);
    try {
      // Clean up push notifications
      await _pushService.logout();
      
      await _authService.signOut();
      _user = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Checks if user has existing account
  Future<bool> hasExistingAccount() async {
    return _authService.hasExistingAccount();
  }

  /// Validates PIN format
  bool validatePin(String pin) {
    return _authService.validatePinFormat(pin);
  }

  /// Changes the PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.changePin(oldPin, newPin);
      if (success && _user != null) {
        _user = _user!.copyWith(pin: newPin);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
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
}
