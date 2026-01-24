/// Unit tests for GameService
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:luscid/services/game_service.dart';
import 'package:luscid/models/game_card_model.dart';
import 'package:luscid/core/constants/game_icons.dart';

void main() {
  late GameService gameService;

  setUp(() {
    gameService = GameService();
  });

  group('GameService - Card Generation', () {
    test('generateCards() for easy difficulty returns 4 cards (2 pairs)', () {
      final cards = gameService.generateCards(GameDifficulty.easy);

      expect(cards.length, 4);
    });

    test(
      'generateCards() for medium difficulty returns 16 cards (8 pairs)',
      () {
        final cards = gameService.generateCards(GameDifficulty.medium);

        expect(cards.length, 16);
      },
    );

    test('generateCards() for hard difficulty returns 36 cards (18 pairs)', () {
      final cards = gameService.generateCards(GameDifficulty.hard);

      expect(cards.length, 36);
    });

    test('generateCards() creates pairs of matching symbols', () {
      final cards = gameService.generateCards(GameDifficulty.easy);

      final symbols = cards.map((c) => c.symbol).toList();
      final uniqueSymbols = symbols.toSet();

      // Each symbol should appear exactly twice
      for (final symbol in uniqueSymbols) {
        final count = symbols.where((s) => s == symbol).length;
        expect(count, 2, reason: 'Symbol $symbol should appear twice');
      }
    });

    test('generateCards() all cards start face down', () {
      final cards = gameService.generateCards(GameDifficulty.medium);

      for (final card in cards) {
        expect(card.isFlipped, false);
        expect(card.isMatched, false);
      }
    });

    test('generateCards() assigns unique IDs', () {
      final cards = gameService.generateCards(GameDifficulty.medium);

      final ids = cards.map((c) => c.id).toSet();
      expect(ids.length, cards.length, reason: 'All IDs should be unique');
    });

    test('generateCards() shuffles cards (different positions)', () {
      // Generate multiple times and check for variation
      final firstGeneration = gameService.generateCards(GameDifficulty.medium);
      final secondGeneration = gameService.generateCards(GameDifficulty.medium);

      // Symbols at same positions should differ (statistically very likely)
      bool anyDifferent = false;
      for (int i = 0; i < firstGeneration.length; i++) {
        if (firstGeneration[i].symbol != secondGeneration[i].symbol) {
          anyDifferent = true;
          break;
        }
      }
      // This could theoretically fail but probability is astronomically low
      expect(anyDifferent, true, reason: 'Cards should be shuffled');
    });
  });

  group('GameService - Card Operations', () {
    test('flipCard() flips card at given index', () {
      final cards = gameService.generateCards(GameDifficulty.easy);

      final updatedCards = gameService.flipCard(cards, 0);

      expect(updatedCards[0].isFlipped, true);
      expect(updatedCards[1].isFlipped, false); // others unchanged
    });

    test('flipCard() preserves other cards', () {
      final cards = gameService.generateCards(GameDifficulty.easy);

      final updatedCards = gameService.flipCard(cards, 1);

      expect(updatedCards[0].isFlipped, false);
      expect(updatedCards[1].isFlipped, true);
      expect(updatedCards[2].isFlipped, false);
      expect(updatedCards[3].isFlipped, false);
    });

    test('checkMatch() returns true for matching symbols', () {
      final card1 = GameCard(id: '1', symbol: '🍎', position: 0);
      final card2 = GameCard(id: '2', symbol: '🍎', position: 1);

      final result = gameService.checkMatch(card1, card2);

      expect(result, true);
    });

    test('checkMatch() returns false for different symbols', () {
      final card1 = GameCard(id: '1', symbol: '🍎', position: 0);
      final card2 = GameCard(id: '2', symbol: '🍊', position: 1);

      final result = gameService.checkMatch(card1, card2);

      expect(result, false);
    });

    test('markAsMatched() marks both cards as matched', () {
      final cards = [
        GameCard(id: '1', symbol: '🍎', position: 0),
        GameCard(id: '2', symbol: '🍊', position: 1),
        GameCard(id: '3', symbol: '🍎', position: 2),
        GameCard(id: '4', symbol: '🍊', position: 3),
      ];

      final updated = gameService.markAsMatched(cards, cards[0], cards[2]);

      expect(updated[0].isMatched, true);
      expect(updated[2].isMatched, true);
      expect(updated[1].isMatched, false);
      expect(updated[3].isMatched, false);
    });

    test('resetFlippedCards() resets non-matched flipped cards', () {
      final cards = [
        GameCard(id: '1', symbol: '🍎', position: 0, isFlipped: true),
        GameCard(id: '2', symbol: '🍊', position: 1, isFlipped: true),
        GameCard(
          id: '3',
          symbol: '🍎',
          position: 2,
          isFlipped: true,
          isMatched: true,
        ),
        GameCard(id: '4', symbol: '🍊', position: 3, isFlipped: false),
      ];

      final reset = gameService.resetFlippedCards(cards);

      expect(reset[0].isFlipped, false); // reset
      expect(reset[1].isFlipped, false); // reset
      expect(reset[2].isFlipped, true); // matched, stays flipped
      expect(reset[3].isFlipped, false); // was not flipped
    });
  });

  group('GameService - Game State', () {
    test('isGameComplete() returns true when all cards matched', () {
      final cards = [
        GameCard(id: '1', symbol: '🍎', position: 0, isMatched: true),
        GameCard(id: '2', symbol: '🍎', position: 1, isMatched: true),
        GameCard(id: '3', symbol: '🍊', position: 2, isMatched: true),
        GameCard(id: '4', symbol: '🍊', position: 3, isMatched: true),
      ];

      expect(gameService.isGameComplete(cards), true);
    });

    test('isGameComplete() returns false when some cards unmatched', () {
      final cards = [
        GameCard(id: '1', symbol: '🍎', position: 0, isMatched: true),
        GameCard(id: '2', symbol: '🍎', position: 1, isMatched: true),
        GameCard(id: '3', symbol: '🍊', position: 2, isMatched: false),
        GameCard(id: '4', symbol: '🍊', position: 3, isMatched: false),
      ];

      expect(gameService.isGameComplete(cards), false);
    });

    test('isGameComplete() returns false for empty cards', () {
      expect(gameService.isGameComplete([]), false);
    });

    test('getTotalPairs() returns correct count', () {
      final cards = gameService.generateCards(GameDifficulty.easy);

      expect(gameService.getTotalPairs(cards), 2);
    });

    test('getGridSize() returns 2 for easy (4 cards)', () {
      final cards = gameService.generateCards(GameDifficulty.easy);

      expect(gameService.getGridSize(cards), 2);
    });

    test('getGridSize() returns 4 for medium (16 cards)', () {
      final cards = gameService.generateCards(GameDifficulty.medium);

      expect(gameService.getGridSize(cards), 4);
    });

    test('getGridSize() returns 6 for hard (36 cards)', () {
      final cards = gameService.generateCards(GameDifficulty.hard);

      expect(gameService.getGridSize(cards), 6);
    });
  });

  group('GameService - Difficulty Detection', () {
    test('getDifficultyFromCards() detects easy', () {
      final cards = gameService.generateCards(GameDifficulty.easy);

      expect(gameService.getDifficultyFromCards(cards), GameDifficulty.easy);
    });

    test('getDifficultyFromCards() detects medium', () {
      final cards = gameService.generateCards(GameDifficulty.medium);

      expect(gameService.getDifficultyFromCards(cards), GameDifficulty.medium);
    });

    test('getDifficultyFromCards() detects hard', () {
      final cards = gameService.generateCards(GameDifficulty.hard);

      expect(gameService.getDifficultyFromCards(cards), GameDifficulty.hard);
    });
  });

  group('GameService - Validation', () {
    test('validateGameState() returns true for valid cards', () {
      final cards = gameService.generateCards(GameDifficulty.easy);

      expect(gameService.validateGameState(cards), true);
    });

    test('validateGameState() returns false for empty list', () {
      expect(gameService.validateGameState([]), false);
    });

    test('validateGameState() returns false for odd number of cards', () {
      final cards = [
        GameCard(id: '1', symbol: '🍎', position: 0),
        GameCard(id: '2', symbol: '🍊', position: 1),
        GameCard(id: '3', symbol: '🍋', position: 2),
      ];

      expect(gameService.validateGameState(cards), false);
    });
  });
}
