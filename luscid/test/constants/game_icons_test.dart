/// Unit tests for GameIcons
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:luscid/core/constants/game_icons.dart';

void main() {
  group('GameIcons - Symbol Collections', () {
    test('fruits list is not empty', () {
      expect(GameIcons.fruits, isNotEmpty);
    });

    test('animals list is not empty', () {
      expect(GameIcons.animals, isNotEmpty);
    });

    test('objects list is not empty', () {
      expect(GameIcons.objects, isNotEmpty);
    });

    test('fruits contains valid emoji strings', () {
      for (final fruit in GameIcons.fruits) {
        expect(fruit, isNotEmpty);
        expect(fruit.length, greaterThan(0));
      }
    });

    test('animals contains valid emoji strings', () {
      for (final animal in GameIcons.animals) {
        expect(animal, isNotEmpty);
      }
    });

    test('all symbols are unique within fruits', () {
      final set = GameIcons.fruits.toSet();
      expect(set.length, GameIcons.fruits.length);
    });

    test('all symbols are unique within animals', () {
      final set = GameIcons.animals.toSet();
      expect(set.length, GameIcons.animals.length);
    });
  });

  group('GameIcons - Symbol Selection', () {
    test('getSymbolsForDifficulty() returns 2 symbols for easy', () {
      final symbols = GameIcons.getSymbolsForDifficulty(GameDifficulty.easy);

      expect(symbols.length, 2);
    });

    test('getSymbolsForDifficulty() returns 8 symbols for medium', () {
      final symbols = GameIcons.getSymbolsForDifficulty(GameDifficulty.medium);

      expect(symbols.length, 8);
    });

    test('getSymbolsForDifficulty() returns 18 symbols for hard', () {
      final symbols = GameIcons.getSymbolsForDifficulty(GameDifficulty.hard);

      expect(symbols.length, 18);
    });

    test('getSymbolsForDifficulty() returns unique symbols', () {
      final symbols = GameIcons.getSymbolsForDifficulty(GameDifficulty.hard);
      final uniqueSymbols = symbols.toSet();

      expect(uniqueSymbols.length, symbols.length);
    });

    test('getRandomSymbols() returns requested count', () {
      final symbols = GameIcons.getRandomSymbols(5);

      expect(symbols.length, 5);
    });

    test('getRandomSymbols() returns unique symbols', () {
      final symbols = GameIcons.getRandomSymbols(10);
      final uniqueSymbols = symbols.toSet();

      expect(uniqueSymbols.length, symbols.length);
    });
  });

  group('GameDifficulty', () {
    test('easy difficulty has correct grid size', () {
      expect(GameIcons.getGridSize(GameDifficulty.easy), 2);
    });

    test('medium difficulty has correct grid size', () {
      expect(GameIcons.getGridSize(GameDifficulty.medium), 4);
    });

    test('hard difficulty has correct grid size', () {
      expect(GameIcons.getGridSize(GameDifficulty.hard), 6);
    });

    test('easy difficulty has correct pair count', () {
      expect(GameIcons.getPairs(GameDifficulty.easy), 2);
    });

    test('medium difficulty has correct pair count', () {
      expect(GameIcons.getPairs(GameDifficulty.medium), 8);
    });

    test('hard difficulty has correct pair count', () {
      expect(GameIcons.getPairs(GameDifficulty.hard), 18);
    });

    test('all difficulties have display names', () {
      for (final difficulty in GameDifficulty.values) {
        expect(difficulty.displayName, isNotEmpty);
      }
    });
  });
}
