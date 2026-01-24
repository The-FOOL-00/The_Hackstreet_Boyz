/// Validation utilities for user input
///
/// PIN validation, room code validation, and other input checks.
library;

class Validators {
  // Prevent instantiation
  Validators._();

  /// Validates a 4-digit PIN
  /// Returns null if valid, error message if invalid
  static String? validatePin(String? pin) {
    if (pin == null || pin.isEmpty) {
      return 'Please enter your PIN';
    }
    if (pin.length != 4) {
      return 'PIN must be 4 digits';
    }
    if (!RegExp(r'^[0-9]{4}$').hasMatch(pin)) {
      return 'PIN must contain only numbers';
    }
    return null;
  }

  /// Validates a 4-digit room code
  /// Returns null if valid, error message if invalid
  static String? validateRoomCode(String? code) {
    if (code == null || code.isEmpty) {
      return 'Please enter a room code';
    }
    if (code.length != 4) {
      return 'Room code must be 4 digits';
    }
    if (!RegExp(r'^[0-9]{4}$').hasMatch(code)) {
      return 'Room code must contain only numbers';
    }
    return null;
  }

  /// Quick check if PIN is valid
  static bool isValidPin(String? pin) {
    return validatePin(pin) == null;
  }

  /// Quick check if room code is valid
  static bool isValidRoomCode(String? code) {
    return validateRoomCode(code) == null;
  }

  /// Checks if a PIN is strong enough (not all same digits, not sequential)
  static bool isPinStrong(String pin) {
    if (pin.length != 4) return false;

    // Check for all same digits (e.g., 1111)
    if (pin.split('').toSet().length == 1) {
      return false;
    }

    // Check for sequential digits (e.g., 1234, 4321)
    const sequentialAsc = [
      '0123',
      '1234',
      '2345',
      '3456',
      '4567',
      '5678',
      '6789',
    ];
    const sequentialDesc = [
      '9876',
      '8765',
      '7654',
      '6543',
      '5432',
      '4321',
      '3210',
    ];

    if (sequentialAsc.contains(pin) || sequentialDesc.contains(pin)) {
      return false;
    }

    return true;
  }

  /// Checks if a string is a valid user ID (for Firebase)
  static bool isValidUserId(String? id) {
    if (id == null || id.isEmpty) return false;
    // Firebase UIDs are typically 28 characters
    return id.length >= 20 && id.length <= 128;
  }
}
