/// Phone Authentication Service
///
/// Handles Firebase phone authentication with OTP verification.
library;

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Result class for phone verification
class PhoneVerificationResult {
  final bool success;
  final String? verificationId;
  final String? error;
  final int? resendToken;

  PhoneVerificationResult({
    required this.success,
    this.verificationId,
    this.error,
    this.resendToken,
  });
}

/// Result class for OTP verification
class OtpVerificationResult {
  final bool success;
  final User? user;
  final String? error;

  OtpVerificationResult({required this.success, this.user, this.error});
}

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Reference to users in Firebase
  DatabaseReference get _usersRef => _database.ref('users');

  /// Current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sends OTP to phone number
  ///
  /// [phoneNumber] should be in E.164 format: +[country code][number]
  /// Example: +919876543210
  Future<PhoneVerificationResult> sendOtp({
    required String phoneNumber,
    int? resendToken,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final completer = Completer<PhoneVerificationResult>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: timeout,
        forceResendingToken: resendToken,

        // Called when verification is complete (auto-retrieval on Android)
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto sign-in (mainly on Android)
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            if (!completer.isCompleted) {
              completer.complete(
                PhoneVerificationResult(
                  success: true,
                  verificationId: null, // Auto-completed, no ID needed
                ),
              );
            }
            // Create/update user profile
            if (userCredential.user != null) {
              await _createOrUpdateUserProfile(
                userCredential.user!,
                phoneNumber,
              );
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.complete(
                PhoneVerificationResult(
                  success: false,
                  error: 'Auto-verification failed: ${e.toString()}',
                ),
              );
            }
          }
        },

        // Called when verification fails
        verificationFailed: (FirebaseAuthException e) {
          String errorMessage;
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage =
                  'The phone number is invalid. Please check and try again.';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many attempts. Please try again later.';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please try again later.';
              break;
            default:
              errorMessage =
                  e.message ?? 'Verification failed. Please try again.';
          }

          if (!completer.isCompleted) {
            completer.complete(
              PhoneVerificationResult(success: false, error: errorMessage),
            );
          }
        },

        // Called when code is sent successfully
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(
              PhoneVerificationResult(
                success: true,
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            );
          }
        },

        // Called when auto-retrieval timeout expires
        codeAutoRetrievalTimeout: (String verificationId) {
          // Code auto-retrieval timed out, user needs to enter manually
          // This is not an error, just informational
        },
      );
    } catch (e) {
      if (!completer.isCompleted) {
        completer.complete(
          PhoneVerificationResult(
            success: false,
            error: 'Failed to send OTP: ${e.toString()}',
          ),
        );
      }
    }

    return completer.future;
  }

  /// Verifies OTP and signs in user
  Future<OtpVerificationResult> verifyOtp({
    required String verificationId,
    required String otp,
    required String phoneNumber,
  }) async {
    try {
      // Create credential from verification ID and OTP
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Create/update user profile in database
        await _createOrUpdateUserProfile(user, phoneNumber);

        return OtpVerificationResult(success: true, user: user);
      }

      return OtpVerificationResult(
        success: false,
        error: 'Failed to sign in. Please try again.',
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP. Please check and try again.';
          break;
        case 'invalid-verification-id':
          errorMessage = 'Verification expired. Please request a new OTP.';
          break;
        case 'session-expired':
          errorMessage = 'Session expired. Please request a new OTP.';
          break;
        default:
          errorMessage = e.message ?? 'Verification failed. Please try again.';
      }

      return OtpVerificationResult(success: false, error: errorMessage);
    } catch (e) {
      return OtpVerificationResult(
        success: false,
        error: 'An error occurred: ${e.toString()}',
      );
    }
  }

  /// Creates or updates user profile in Firebase Database
  Future<void> _createOrUpdateUserProfile(
    User firebaseUser,
    String phoneNumber,
  ) async {
    final userRef = _usersRef.child(firebaseUser.uid);
    final snapshot = await userRef.get();

    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (snapshot.exists) {
      // Update existing user
      await userRef.update({
        'lastActive': now,
        'status': 'online',
        'phone': normalizedPhone,
      });
    } else {
      // Create new user
      await userRef.set({
        'uid': firebaseUser.uid,
        'phone': normalizedPhone,
        'displayName': firebaseUser.displayName ?? 'User',
        'photoUrl': firebaseUser.photoURL,
        'status': 'online',
        'createdAt': now,
        'lastActive': now,
        'role': 'senior',
      });
    }

    // Also index by phone number for contact matching
    await _database.ref('phoneIndex/$normalizedPhone').set(firebaseUser.uid);
  }

  /// Normalizes phone number for consistent storage
  String _normalizePhoneNumber(String phone) {
    // Remove all non-digit characters except leading +
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Updates user's online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    final user = currentUser;
    if (user != null) {
      await _usersRef.child(user.uid).update({
        'status': isOnline ? 'online' : 'offline',
        'lastActive': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  /// Updates user display name
  Future<void> updateDisplayName(String name) async {
    final user = currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
      await _usersRef.child(user.uid).update({'displayName': name});
    }
  }

  /// Signs out current user
  Future<void> signOut() async {
    await updateOnlineStatus(false);
    await _auth.signOut();
  }

  /// Gets user data from database
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final snapshot = await _usersRef.child(uid).get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  /// Streams user data changes
  Stream<Map<String, dynamic>?> watchUserData(String uid) {
    return _usersRef.child(uid).onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  /// Checks if phone number is already registered
  Future<bool> isPhoneRegistered(String phoneNumber) async {
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    final snapshot = await _database.ref('phoneIndex/$normalizedPhone').get();
    return snapshot.exists;
  }

  /// Gets user ID by phone number
  Future<String?> getUserIdByPhone(String phoneNumber) async {
    final normalizedPhone = _normalizePhoneNumber(phoneNumber);
    final snapshot = await _database.ref('phoneIndex/$normalizedPhone').get();
    if (snapshot.exists) {
      return snapshot.value as String;
    }
    return null;
  }

  /// Deletes user account
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user != null) {
      // Get user data to find phone
      final userData = await getUserData(user.uid);
      if (userData != null && userData['phone'] != null) {
        // Remove phone index
        await _database.ref('phoneIndex/${userData['phone']}').remove();
      }
      // Remove user data
      await _usersRef.child(user.uid).remove();
      // Delete Firebase auth account
      await user.delete();
    }
  }
}
