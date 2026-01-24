/// Unit tests for Helpers
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:luscid/core/utils/helpers.dart';

void main() {
  group('Helpers - Room Code Generation', () {
    test('generateRoomCode() returns 4-digit string', () {
      final code = Helpers.generateRoomCode();

      expect(code.length, 4);
      expect(int.tryParse(code), isNotNull);
    });

    test('generateRoomCode() returns numeric string', () {
      for (int i = 0; i < 10; i++) {
        final code = Helpers.generateRoomCode();
        expect(RegExp(r'^[0-9]{4}$').hasMatch(code), true);
      }
    });

    test('generateRoomCode() generates varying codes', () {
      final codes = <String>{};
      for (int i = 0; i < 20; i++) {
        codes.add(Helpers.generateRoomCode());
      }
      // Should have at least some variation
      expect(codes.length, greaterThan(1));
    });

    test('generateRoomCode() returns codes >= 1000', () {
      for (int i = 0; i < 100; i++) {
        final code = Helpers.generateRoomCode();
        final numValue = int.parse(code);
        expect(numValue, greaterThanOrEqualTo(1000));
        expect(numValue, lessThanOrEqualTo(9999));
      }
    });
  });

  group('Helpers - List Shuffling', () {
    test('shuffleList() returns list of same length', () {
      final original = [1, 2, 3, 4, 5];
      final shuffled = Helpers.shuffleList(original);

      expect(shuffled.length, original.length);
    });

    test('shuffleList() contains same elements', () {
      final original = [1, 2, 3, 4, 5];
      final shuffled = Helpers.shuffleList(original);

      expect(shuffled.toSet(), original.toSet());
    });

    test('shuffleList() does not modify original list', () {
      final original = [1, 2, 3, 4, 5];
      final originalCopy = List.from(original);
      Helpers.shuffleList(original);

      expect(original, originalCopy);
    });

    test('shuffleList() handles empty list', () {
      final empty = <int>[];
      final shuffled = Helpers.shuffleList(empty);

      expect(shuffled, isEmpty);
    });

    test('shuffleList() handles single element', () {
      final single = [42];
      final shuffled = Helpers.shuffleList(single);

      expect(shuffled, [42]);
    });
  });

  group('Helpers - Encouragement Messages', () {
    test('getMatchMessage() returns non-empty string', () {
      final message = Helpers.getMatchMessage();

      expect(message, isNotEmpty);
    });

    test('getGameCompleteMessage() returns non-empty string', () {
      final message = Helpers.getGameCompleteMessage();

      expect(message, isNotEmpty);
    });

    test('getEncouragementMessage() returns non-empty string', () {
      final message = Helpers.getEncouragementMessage();

      expect(message, isNotEmpty);
    });
  });

  group('Helpers - Time Formatting', () {
    test('formatDuration() formats zero seconds', () {
      final result = Helpers.formatDuration(Duration.zero);

      expect(result, contains('0'));
    });

    test('formatDuration() formats minutes and seconds', () {
      final result = Helpers.formatDuration(
        const Duration(minutes: 2, seconds: 30),
      );

      expect(result, contains('2'));
      expect(result, contains('30'));
    });

    test('formatDuration() formats hours', () {
      final result = Helpers.formatDuration(
        const Duration(hours: 1, minutes: 5, seconds: 10),
      );

      expect(result, isNotEmpty);
    });
  });

  group('Helpers - Delay', () {
    test('delay() completes after specified time', () async {
      final stopwatch = Stopwatch()..start();

      await Helpers.delay(100);

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
    });
  });
}
