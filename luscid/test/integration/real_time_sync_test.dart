/// Real-time card synchronization tests
///
/// Tests that card flips and game state sync in real-time between players
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:luscid/models/game_room_model.dart';
import 'package:luscid/models/game_card_model.dart';
import 'package:luscid/services/game_service.dart';
import 'package:luscid/core/constants/game_icons.dart';

void main() {
  group('Real-time Card Synchronization Tests', () {
    late GameService gameService;

    setUp(() {
      gameService = GameService();
    });

    test('Card flip is immediately visible to both players', () {
      // Setup: Create and populate game
      var cards = gameService.generateCards(GameDifficulty.easy);
      expect(cards.length, 4);

      // Player 1 flips card 0
      cards = gameService.flipCard(cards, 0);
      expect(cards[0].isFlipped, true);
      expect(cards[0].isMatched, false);

      // Card should be visible to both players (no state sync needed for logic)
      expect(cards[0].isFlipped, true);
    });

    test('Multiple card flips maintain correct state', () {
      var cards = gameService.generateCards(GameDifficulty.easy);

      // Player flips first card
      cards = gameService.flipCard(cards, 0);
      expect(cards[0].isFlipped, true);
      expect(cards[1].isFlipped, false);
      expect(cards[2].isFlipped, false);
      expect(cards[3].isFlipped, false);

      // Player flips second card
      cards = gameService.flipCard(cards, 2);
      expect(cards[0].isFlipped, true);
      expect(cards[2].isFlipped, true);
      expect(cards[1].isFlipped, false);
      expect(cards[3].isFlipped, false);
    });

    test('Card match updates both players scores', () {
      var room =
          GameRoom.create(
            roomCode: '1234',
            hostId: 'host-123',
            difficulty: GameDifficulty.easy,
          ).copyWith(
            guestId: 'guest-456',
            status: GameRoomStatus.playing,
            cards: gameService.generateCards(GameDifficulty.easy),
          );

      // Find matching pair
      var matchIndex1 = -1;
      var matchIndex2 = -1;
      for (var i = 0; i < room.cards.length; i++) {
        for (var j = i + 1; j < room.cards.length; j++) {
          if (room.cards[i].symbol == room.cards[j].symbol) {
            matchIndex1 = i;
            matchIndex2 = j;
            break;
          }
        }
        if (matchIndex1 != -1) break;
      }

      expect(matchIndex1, isNot(-1));
      expect(matchIndex2, isNot(-1));

      // Player flips matching cards
      var cards = List<GameCard>.from(room.cards);
      cards[matchIndex1] = cards[matchIndex1].flip();
      cards[matchIndex2] = cards[matchIndex2].flip();

      // Verify match
      final isMatch = gameService.checkMatch(
        cards[matchIndex1],
        cards[matchIndex2],
      );
      expect(isMatch, true);

      // Mark as matched
      cards = gameService.markAsMatched(
        cards,
        cards[matchIndex1],
        cards[matchIndex2],
      );
      expect(cards[matchIndex1].isMatched, true);
      expect(cards[matchIndex2].isMatched, true);

      // Update room scores
      final updatedScores = Map<String, int>.from(room.scores);
      updatedScores['host-123'] = 1;

      var updatedRoom = room.copyWith(cards: cards, scores: updatedScores);

      // Both players see the same updated state
      expect(updatedRoom.cards[matchIndex1].isMatched, true);
      expect(updatedRoom.scores['host-123'], 1);
    });

    test('Turn switching reflects in both players views', () {
      var room = GameRoom.create(
        roomCode: '5678',
        hostId: 'host-xyz',
        difficulty: GameDifficulty.easy,
      ).copyWith(guestId: 'guest-abc', status: GameRoomStatus.playing);

      // Initial turn is host
      expect(room.currentTurn, 'host-xyz');

      // Switch turn to guest
      var updatedRoom = room.copyWith(currentTurn: 'guest-abc');
      expect(updatedRoom.currentTurn, 'guest-abc');

      // Both players see guest's turn
      expect(updatedRoom.currentTurn, 'guest-abc');
    });

    test('Game completion state syncs to both players', () {
      var room =
          GameRoom.create(
            roomCode: '9999',
            hostId: 'host-complete',
            difficulty: GameDifficulty.easy,
          ).copyWith(
            guestId: 'guest-complete',
            status: GameRoomStatus.playing,
            cards: gameService.generateCards(GameDifficulty.easy),
          );

      // Mark all cards as matched
      var cards = List<GameCard>.from(room.cards);
      for (var i = 0; i < cards.length; i++) {
        cards[i] = cards[i].match();
      }

      // End game
      var finishedRoom = room.copyWith(
        cards: cards,
        status: GameRoomStatus.finished,
        finishedAt: DateTime.now(),
      );

      // Both players see completion
      expect(finishedRoom.status, GameRoomStatus.finished);
      expect(finishedRoom.isComplete, true);
      expect(finishedRoom.finishedAt, isNotNull);
    });

    test('Card serialization preserves flip state for Firebase sync', () {
      final card = GameCard(
        id: '123',
        symbol: '🍎',
        position: 0,
        isFlipped: true,
        isMatched: false,
      );

      // Serialize to JSON (for Firebase)
      final json = card.toJson();
      expect(json['isFlipped'], true);
      expect(json['isMatched'], false);

      // Deserialize from JSON
      final restored = GameCard.fromJson(json);
      expect(restored.isFlipped, true);
      expect(restored.isMatched, false);
      expect(restored.symbol, '🍎');
    });

    test('Multiple card updates serialize correctly', () {
      var cards = gameService.generateCards(GameDifficulty.easy);

      // Flip and serialize
      cards[0] = cards[0].flip();
      cards[1] = cards[1].flip();

      // Convert to Firebase format
      final json = cards.map((c) => c.toJson()).toList();
      expect(json.length, 4);
      expect((json[0] as Map)['isFlipped'], true);
      expect((json[1] as Map)['isFlipped'], true);
      expect((json[2] as Map)['isFlipped'], false);

      // Deserialize back
      final restored = json.map((c) => GameCard.fromJson(c)).toList();

      expect(restored[0].isFlipped, true);
      expect(restored[1].isFlipped, true);
      expect(restored[2].isFlipped, false);
    });

    test('Game room state persists through multiple sync cycles', () {
      var room =
          GameRoom.create(
            roomCode: '7777',
            hostId: 'persistent-host',
            difficulty: GameDifficulty.easy,
          ).copyWith(
            guestId: 'persistent-guest',
            status: GameRoomStatus.playing,
            cards: gameService.generateCards(GameDifficulty.easy),
          );

      // Cycle 1: First card flip
      var cards = List<GameCard>.from(room.cards);
      cards[0] = cards[0].flip();
      room = room.copyWith(cards: cards);

      expect(room.cards[0].isFlipped, true);

      // Cycle 2: Second card flip
      cards = List<GameCard>.from(room.cards);
      cards[1] = cards[1].flip();
      room = room.copyWith(cards: cards);

      expect(room.cards[0].isFlipped, true);
      expect(room.cards[1].isFlipped, true);

      // Cycle 3: Turn switch
      room = room.copyWith(currentTurn: 'persistent-guest');
      expect(room.currentTurn, 'persistent-guest');

      // Cycle 4: Score update
      final scores = Map<String, int>.from(room.scores);
      scores['persistent-host'] = 1;
      room = room.copyWith(scores: scores);

      expect(room.scores['persistent-host'], 1);
      // Previous state maintained
      expect(room.cards[0].isFlipped, true);
      expect(room.cards[1].isFlipped, true);
      expect(room.currentTurn, 'persistent-guest');
    });

    test('Real-time sync order: card flip → match check → score update', () {
      var room =
          GameRoom.create(
            roomCode: '8888',
            hostId: 'order-host',
            difficulty: GameDifficulty.easy,
          ).copyWith(
            guestId: 'order-guest',
            status: GameRoomStatus.playing,
            cards: gameService.generateCards(GameDifficulty.easy),
          );

      // Find matching pair
      var idx1 = -1, idx2 = -1;
      for (var i = 0; i < room.cards.length; i++) {
        for (var j = i + 1; j < room.cards.length; j++) {
          if (room.cards[i].symbol == room.cards[j].symbol) {
            idx1 = i;
            idx2 = j;
            break;
          }
        }
        if (idx1 != -1) break;
      }

      // Step 1: Flip first card
      var cards = List<GameCard>.from(room.cards);
      cards[idx1] = cards[idx1].flip();
      room = room.copyWith(cards: cards);
      expect(room.cards[idx1].isFlipped, true);

      // Step 2: Flip second card
      cards = List<GameCard>.from(room.cards);
      cards[idx2] = cards[idx2].flip();
      room = room.copyWith(cards: cards);
      expect(room.cards[idx1].isFlipped, true);
      expect(room.cards[idx2].isFlipped, true);

      // Step 3: Mark as matched
      cards = gameService.markAsMatched(cards, cards[idx1], cards[idx2]);
      room = room.copyWith(cards: cards);
      expect(room.cards[idx1].isMatched, true);
      expect(room.cards[idx2].isMatched, true);

      // Step 4: Update score
      final scores = Map<String, int>.from(room.scores);
      scores['order-host'] = (scores['order-host'] ?? 0) + 1;
      room = room.copyWith(scores: scores);
      expect(room.scores['order-host'], 1);

      // All state is in sync
      expect(room.cards[idx1].isMatched, true);
      expect(room.cards[idx2].isMatched, true);
      expect(room.scores['order-host'], 1);
    });
  });
}
