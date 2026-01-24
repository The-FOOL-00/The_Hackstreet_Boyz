/// Authentication service for PIN-based login
///
/// Handles user creation, PIN validation, and session management.
/// Uses local storage with UUID for user identification (no Firebase Auth required).
library;

import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'local_storage_service.dart';

class AuthService {
  late final LocalStorageService _localStorage;
  static const Uuid _uuid = Uuid();

  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _localStorage = LocalStorageService();
  }

  // In-memory cache for current user
  UserModel? _currentUser;

  /// Gets the current user ID (from local storage)
  String? get currentUserId => _currentUser?.uid;

  /// Gets the current user
  UserModel? get currentUser => _currentUser;

  /// Creates a new user with PIN
  Future<UserModel?> createUser({
    required String pin,
    required UserRole role,
    String? displayName,
  }) async {
    try {
      // Generate a unique user ID using UUID
      final uniqueId = _uuid.v4();

      // Create our user model
      final user = UserModel.create(
        uid: uniqueId,
        pin: pin, // In production, this should be hashed
        role: role,
        displayName: displayName,
      );

      // Save locally
      await _localStorage.saveUser(user);
      await _localStorage.setFirstLaunchComplete();

      // Update cache
      _currentUser = user;

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Signs in with PIN
  Future<UserModel?> signInWithPin(String pin) async {
    try {
      // Get saved user
      final savedUser = await _localStorage.getUser();

      if (savedUser == null) {
        throw Exception('No user found. Please create an account first.');
      }

      // Validate PIN
      if (savedUser.pin != pin) {
        throw Exception('Incorrect PIN. Please try again.');
      }

      // Update last active
      final updatedUser = savedUser.copyWith(lastActive: DateTime.now());
      await _localStorage.saveUser(updatedUser);

      // Update cache
      _currentUser = updatedUser;

      return updatedUser;
    } catch (e) {
      rethrow;
    }
  }

  /// Checks if PIN exists (user has account)
  Future<bool> hasExistingAccount() async {
    final user = await _localStorage.getUser();
    return user != null;
  }

  /// Gets the saved user
  Future<UserModel?> getSavedUser() async {
    return _localStorage.getUser();
  }

  /// Validates a PIN format
  bool validatePinFormat(String pin) {
    return pin.length == 4 && RegExp(r'^[0-9]{4}$').hasMatch(pin);
  }

  /// Signs out the user
  Future<void> signOut() async {
    await _localStorage.removeUser();
    _currentUser = null;
  }

  /// Auto login if session exists
  Future<UserModel?> autoLogin() async {
    try {
      final savedUser = await _localStorage.getUser();
      if (savedUser == null) return null;

      // Update last active
      final updatedUser = savedUser.copyWith(lastActive: DateTime.now());
      await _localStorage.saveUser(updatedUser);

      // Update cache
      _currentUser = updatedUser;

      return updatedUser;
    } catch (e) {
      return null;
    }
  }

  /// Changes the PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      final savedUser = await _localStorage.getUser();
      if (savedUser == null) return false;

      // Validate old PIN
      if (savedUser.pin != oldPin) return false;

      // Validate new PIN format
      if (!validatePinFormat(newPin)) return false;

      // Update PIN
      final updatedUser = savedUser.copyWith(pin: newPin);
      await _localStorage.saveUser(updatedUser);

      // Update cache
      _currentUser = updatedUser;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Generates a unique device/session ID for multiplayer
  String generateSessionId() {
    return _uuid.v4();
  }
}
