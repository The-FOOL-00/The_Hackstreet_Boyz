/// Unit tests for Validators
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:luscid/core/utils/validators.dart';

void main() {
  group('Validators - PIN Validation', () {
    test('validatePin() returns null for valid 4-digit PIN', () {
      expect(Validators.validatePin('1234'), isNull);
      expect(Validators.validatePin('0000'), isNull);
      expect(Validators.validatePin('9999'), isNull);
    });

    test('validatePin() returns error for empty PIN', () {
      final result = Validators.validatePin('');
      expect(result, isNotNull);
      expect(result, contains('enter'));
    });

    test('validatePin() returns error for null PIN', () {
      final result = Validators.validatePin(null);
      expect(result, isNotNull);
    });

    test('validatePin() returns error for PIN less than 4 digits', () {
      expect(Validators.validatePin('123'), isNotNull);
      expect(Validators.validatePin('12'), isNotNull);
      expect(Validators.validatePin('1'), isNotNull);
    });

    test('validatePin() returns error for PIN more than 4 digits', () {
      expect(Validators.validatePin('12345'), isNotNull);
      expect(Validators.validatePin('123456'), isNotNull);
    });

    test('validatePin() returns error for non-numeric PIN', () {
      expect(Validators.validatePin('abcd'), isNotNull);
      expect(Validators.validatePin('12ab'), isNotNull);
      expect(Validators.validatePin('1 34'), isNotNull);
    });

    test('isValidPin() returns true for valid PIN', () {
      expect(Validators.isValidPin('1234'), true);
      expect(Validators.isValidPin('0000'), true);
    });

    test('isValidPin() returns false for invalid PIN', () {
      expect(Validators.isValidPin(''), false);
      expect(Validators.isValidPin('123'), false);
      expect(Validators.isValidPin('abcd'), false);
    });
  });

  group('Validators - Room Code Validation', () {
    test('validateRoomCode() returns null for valid 4-digit code', () {
      expect(Validators.validateRoomCode('1234'), isNull);
      expect(Validators.validateRoomCode('5678'), isNull);
    });

    test('validateRoomCode() returns error for empty code', () {
      final result = Validators.validateRoomCode('');
      expect(result, isNotNull);
    });

    test('validateRoomCode() returns error for null code', () {
      final result = Validators.validateRoomCode(null);
      expect(result, isNotNull);
    });

    test('validateRoomCode() returns error for wrong length', () {
      expect(Validators.validateRoomCode('123'), isNotNull);
      expect(Validators.validateRoomCode('12345'), isNotNull);
    });

    test('validateRoomCode() returns error for non-numeric code', () {
      expect(Validators.validateRoomCode('ABCD'), isNotNull);
      expect(Validators.validateRoomCode('12AB'), isNotNull);
    });

    test('isValidRoomCode() returns true for valid code', () {
      expect(Validators.isValidRoomCode('1234'), true);
    });

    test('isValidRoomCode() returns false for invalid code', () {
      expect(Validators.isValidRoomCode(''), false);
      expect(Validators.isValidRoomCode('ABC'), false);
    });
  });
}
