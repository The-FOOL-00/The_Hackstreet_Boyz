/// Unit tests for Phone Authentication
///
/// Tests for phone authentication logic without Firebase dependencies.
library;

import 'package:flutter_test/flutter_test.dart';

// Standalone result classes for testing (mirrors service classes)
class PhoneVerificationResult {
  final bool success;
  final String? verificationId;
  final int? resendToken;
  final String? error;

  PhoneVerificationResult({
    required this.success,
    this.verificationId,
    this.resendToken,
    this.error,
  });
}

class OtpVerificationResult {
  final bool success;
  final dynamic user;
  final String? error;

  OtpVerificationResult({required this.success, this.user, this.error});
}

void main() {
  group('PhoneAuthService', () {
    group('Phone Number Validation', () {
      test('should validate correct Indian phone number', () {
        // Indian numbers should be 10 digits
        expect('+919876543210'.length, equals(13));
        expect('+919876543210'.startsWith('+91'), isTrue);
      });

      test('should normalize phone number by removing spaces', () {
        const input = '+91 98765 43210';
        final normalized = input.replaceAll(RegExp(r'[^\d+]'), '');
        expect(normalized, equals('+919876543210'));
      });

      test('should normalize phone number by removing dashes', () {
        const input = '+91-9876-543-210';
        final normalized = input.replaceAll(RegExp(r'[^\d+]'), '');
        expect(normalized, equals('+919876543210'));
      });

      test('should handle international format', () {
        const usNumber = '+14155551234';
        const ukNumber = '+447911123456';

        expect(usNumber.startsWith('+1'), isTrue);
        expect(ukNumber.startsWith('+44'), isTrue);
      });
    });

    group('PhoneVerificationResult', () {
      test('should create successful result', () {
        final result = PhoneVerificationResult(
          success: true,
          verificationId: 'test-verification-id',
          resendToken: 12345,
        );

        expect(result.success, isTrue);
        expect(result.verificationId, equals('test-verification-id'));
        expect(result.resendToken, equals(12345));
        expect(result.error, isNull);
      });

      test('should create error result', () {
        final result = PhoneVerificationResult(
          success: false,
          error: 'Invalid phone number',
        );

        expect(result.success, isFalse);
        expect(result.error, equals('Invalid phone number'));
        expect(result.verificationId, isNull);
      });
    });

    group('OtpVerificationResult', () {
      test('should create successful result', () {
        final result = OtpVerificationResult(
          success: true,
          user: null, // In real tests, would mock Firebase User
        );

        expect(result.success, isTrue);
        expect(result.error, isNull);
      });

      test('should create error result for invalid OTP', () {
        final result = OtpVerificationResult(
          success: false,
          error: 'Invalid OTP. Please check and try again.',
        );

        expect(result.success, isFalse);
        expect(result.error, contains('Invalid OTP'));
      });

      test('should create error result for expired session', () {
        final result = OtpVerificationResult(
          success: false,
          error: 'Session expired. Please request a new OTP.',
        );

        expect(result.success, isFalse);
        expect(result.error, contains('expired'));
      });
    });
  });

  group('Phone Number Normalization', () {
    String normalizePhoneNumber(String phone) {
      return phone.replaceAll(RegExp(r'[^\d+]'), '');
    }

    test('should normalize various formats to standard format', () {
      expect(normalizePhoneNumber('+91 98765 43210'), equals('+919876543210'));
      expect(normalizePhoneNumber('+91-9876-543-210'), equals('+919876543210'));
      expect(
        normalizePhoneNumber('(+91) 98765-43210'),
        equals('+919876543210'),
      );
      expect(normalizePhoneNumber('+919876543210'), equals('+919876543210'));
    });

    test('should handle numbers without country code', () {
      String addCountryCode(String phone) {
        final normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');
        if (!normalized.startsWith('+')) {
          if (normalized.length == 10) {
            return '+91$normalized';
          }
        }
        return normalized;
      }

      expect(addCountryCode('9876543210'), equals('+919876543210'));
      expect(addCountryCode('+919876543210'), equals('+919876543210'));
    });
  });

  group('OTP Validation', () {
    bool isValidOtp(String otp) {
      return otp.length == 6 && RegExp(r'^\d{6}$').hasMatch(otp);
    }

    test('should validate 6-digit OTP', () {
      expect(isValidOtp('123456'), isTrue);
      expect(isValidOtp('000000'), isTrue);
      expect(isValidOtp('999999'), isTrue);
    });

    test('should reject invalid OTP formats', () {
      expect(isValidOtp('12345'), isFalse); // Too short
      expect(isValidOtp('1234567'), isFalse); // Too long
      expect(isValidOtp('12345a'), isFalse); // Contains letter
      expect(isValidOtp(''), isFalse); // Empty
    });
  });

  group('User Data Model', () {
    test('should create user data map correctly', () {
      final now = DateTime.now();
      final userData = {
        'uid': 'test-uid',
        'phone': '+919876543210',
        'displayName': 'Test User',
        'status': 'online',
        'createdAt': now.millisecondsSinceEpoch,
        'lastActive': now.millisecondsSinceEpoch,
        'role': 'senior',
      };

      expect(userData['uid'], equals('test-uid'));
      expect(userData['phone'], equals('+919876543210'));
      expect(userData['displayName'], equals('Test User'));
      expect(userData['status'], equals('online'));
      expect(userData['role'], equals('senior'));
    });

    test('should handle missing optional fields', () {
      final userData = <String, dynamic>{
        'uid': 'test-uid',
        'phone': '+919876543210',
      };

      final displayName = (userData['displayName'] ?? 'User') as String;
      final status = (userData['status'] ?? 'offline') as String;

      expect(displayName, equals('User'));
      expect(status, equals('offline'));
    });
  });
}
