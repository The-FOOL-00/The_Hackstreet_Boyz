/// Unit tests for GameCard model
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:luscid/models/game_card_model.dart';

void main() {
  group('GameCard', () {
    test('creates card with default states', () {
      final card = GameCard(id: 'card-1', symbol: '🍎', position: 0);

      expect(card.id, 'card-1');
      expect(card.symbol, '🍎');
      expect(card.position, 0);
      expect(card.isFlipped, false);
      expect(card.isMatched, false);
    });

    test('creates card with explicit states', () {
      final card = GameCard(
        id: 'card-2',
        symbol: '🍊',
        position: 1,
        isFlipped: true,
        isMatched: true,
      );

      expect(card.isFlipped, true);
      expect(card.isMatched, true);
    });

    test('flip() returns new card with flipped state', () {
      final original = GameCard(id: 'card-3', symbol: '🍋', position: 2);

      final flipped = original.flip();

      expect(original.isFlipped, false); // original unchanged
      expect(flipped.isFlipped, true);
      expect(flipped.id, original.id);
      expect(flipped.symbol, original.symbol);
    });

    test('flip() toggles flipped state', () {
      final card = GameCard(
        id: 'card-4',
        symbol: '🍇',
        position: 3,
        isFlipped: true,
      );

      final unflipped = card.flip();

      expect(unflipped.isFlipped, false);
    });

    test('match() returns card with matched state', () {
      final card = GameCard(id: 'card-5', symbol: '🍓', position: 4);

      final matched = card.match();

      expect(matched.isMatched, true);
      expect(matched.isFlipped, true); // matched cards stay flipped
    });

    test('reset() clears flipped state but preserves matched', () {
      final flippedCard = GameCard(
        id: 'card-6',
        symbol: '🫐',
        position: 5,
        isFlipped: true,
      );

      final reset = flippedCard.reset();

      expect(reset.isFlipped, false);
    });

    test('copyWith() creates new instance with changes', () {
      final original = GameCard(id: 'card-7', symbol: '🍑', position: 6);

      final copy = original.copyWith(isFlipped: true);

      expect(copy.isFlipped, true);
      expect(copy.id, original.id);
      expect(copy.symbol, original.symbol);
      expect(copy.position, original.position);
    });

    test('toJson() serializes correctly', () {
      final card = GameCard(
        id: 'json-card',
        symbol: '🥝',
        position: 7,
        isFlipped: true,
        isMatched: false,
      );

      final json = card.toJson();

      expect(json['id'], 'json-card');
      expect(json['symbol'], '🥝');
      expect(json['position'], 7);
      expect(json['isFlipped'], true);
      expect(json['isMatched'], false);
    });

    test('fromJson() deserializes correctly', () {
      final json = {
        'id': 'from-json-card',
        'symbol': '🍒',
        'position': 8,
        'isFlipped': false,
        'isMatched': true,
      };

      final card = GameCard.fromJson(json);

      expect(card.id, 'from-json-card');
      expect(card.symbol, '🍒');
      expect(card.position, 8);
      expect(card.isFlipped, false);
      expect(card.isMatched, true);
    });

    test('toJson() and fromJson() are reversible', () {
      final original = GameCard(
        id: 'round-trip',
        symbol: '🍌',
        position: 9,
        isFlipped: true,
        isMatched: true,
      );

      final json = original.toJson();
      final restored = GameCard.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.symbol, original.symbol);
      expect(restored.position, original.position);
      expect(restored.isFlipped, original.isFlipped);
      expect(restored.isMatched, original.isMatched);
    });
  });
}
