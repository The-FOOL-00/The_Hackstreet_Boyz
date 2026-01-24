/// Integration tests for complete multiplayer game flow
///
/// Tests the full lifecycle: room creation, joining, playing, syncing, and game completion
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:luscid/models/game_room_model.dart';
import 'package:luscid/models/game_card_model.dart';
import 'package:luscid/services/game_service.dart';
import 'package:luscid/core/constants/game_icons.dart';

/// Simulates Firebase operations for testing
/// This mimics the actual FirebaseService behavior without requiring a live connection
class MockFirebaseDatabase {
  final Map<String, Map<String, dynamic>> _rooms = {};

  /// Creates a room in the mock database
  Future<GameRoom> createRoom({
    required String hostId,
    required GameDifficulty difficulty,
  }) async {
    // Generate unique room code (simulated)
    final roomCode = _generateRoomCode();

    final room = GameRoom.create(
      roomCode: roomCode,
      hostId: hostId,
      difficulty: difficulty,
    );

    _rooms[roomCode] = room.toJson();
    return room;
  }

  /// Joins an existing room
  Future<GameRoom> joinRoom({
    required String roomCode,
    required String guestId,
  }) async {
    if (!_rooms.containsKey(roomCode)) {
      throw Exception('Room not found');
    }

    final roomJson = _rooms[roomCode]!;
    final room = GameRoom.fromJson(roomJson);

    if (!room.canJoin) {
      throw Exception('Room is not available');
    }

    if (room.hostId == guestId) {
      throw Exception('Cannot join your own room');
    }

    // Update room with guest
    final updatedScores = Map<String, int>.from(room.scores);
    updatedScores[guestId] = 0;

    final updatedRoom = room.copyWith(guestId: guestId, scores: updatedScores);

    _rooms[roomCode] = updatedRoom.toJson();
    return updatedRoom;
  }

  /// Starts the game with generated cards
  Future<GameRoom> startGame(
    String roomCode,
    GameDifficulty difficulty,
    GameService gameService,
  ) async {
    final roomJson = _rooms[roomCode]!;
    final room = GameRoom.fromJson(roomJson);

    final cards = gameService.generateCards(difficulty);

    final updatedRoom = room.copyWith(
      cards: cards,
      status: GameRoomStatus.playing,
      startedAt: DateTime.now(),
    );

    _rooms[roomCode] = updatedRoom.toJson();
    return updatedRoom;
  }

  /// Updates card state after a move
  Future<GameRoom> updateCards(String roomCode, List<GameCard> cards) async {
    final roomJson = _rooms[roomCode]!;
    final room = GameRoom.fromJson(roomJson);

    final updatedRoom = room.copyWith(cards: cards);
    _rooms[roomCode] = updatedRoom.toJson();
    return updatedRoom;
  }

  /// Updates player score
  Future<GameRoom> updateScore(
    String roomCode,
    String playerId,
    int score,
  ) async {
    final roomJson = _rooms[roomCode]!;
    final room = GameRoom.fromJson(roomJson);

    final updatedScores = Map<String, int>.from(room.scores);
    updatedScores[playerId] = score;

    final updatedRoom = room.copyWith(scores: updatedScores);
    _rooms[roomCode] = updatedRoom.toJson();
    return updatedRoom;
  }

  /// Switches turn to next player
  Future<GameRoom> updateTurn(String roomCode, String nextPlayerId) async {
    final roomJson = _rooms[roomCode]!;
    final room = GameRoom.fromJson(roomJson);

    final updatedRoom = room.copyWith(currentTurn: nextPlayerId);
    _rooms[roomCode] = updatedRoom.toJson();
    return updatedRoom;
  }

  /// Ends the game
  Future<GameRoom> endGame(String roomCode) async {
    final roomJson = _rooms[roomCode]!;
    final room = GameRoom.fromJson(roomJson);

    final updatedRoom = room.copyWith(
      status: GameRoomStatus.finished,
      finishedAt: DateTime.now(),
    );

    _rooms[roomCode] = updatedRoom.toJson();
    return updatedRoom;
  }

  /// Gets current room state
  GameRoom? getRoom(String roomCode) {
    if (!_rooms.containsKey(roomCode)) return null;
    return GameRoom.fromJson(_rooms[roomCode]!);
  }

  /// Deletes a room
  void deleteRoom(String roomCode) {
    _rooms.remove(roomCode);
  }

  String _generateRoomCode() {
    return '${DateTime.now().millisecondsSinceEpoch % 10000}'.padLeft(4, '0');
  }
}

/// Simulates a player's game state
class PlayerState {
  final String userId;
  GameRoom? room;
  List<GameCard> localCards = [];
  int myScore = 0;

  PlayerState(this.userId);

  /// Syncs local state with room state
  void syncWithRoom(GameRoom newRoom) {
    room = newRoom;
    localCards = List.from(newRoom.cards);
    myScore = newRoom.getScore(userId);
  }

  bool get isMyTurn => room?.currentTurn == userId;
}

void main() {
  group('Complete Multiplayer Game Flow Integration Test', () {
    late MockFirebaseDatabase mockDb;
    late GameService gameService;
    late PlayerState hostPlayer;
    late PlayerState guestPlayer;

    const hostId = 'host-user-12345';
    const guestId = 'guest-user-67890';

    setUp(() {
      mockDb = MockFirebaseDatabase();
      gameService = GameService();
      hostPlayer = PlayerState(hostId);
      guestPlayer = PlayerState(guestId);
    });

    test('Step 1: Host creates a new room', () async {
      // Host creates room
      final room = await mockDb.createRoom(
        hostId: hostId,
        difficulty: GameDifficulty.easy,
      );

      hostPlayer.syncWithRoom(room);

      // Verify room was created correctly
      expect(room.roomCode.length, 4);
      expect(room.hostId, hostId);
      expect(room.guestId, isNull);
      expect(room.status, GameRoomStatus.waiting);
      expect(room.canJoin, true);
      expect(room.scores[hostId], 0);
      expect(room.currentTurn, hostId);

      // Verify room is in database
      final fetchedRoom = mockDb.getRoom(room.roomCode);
      expect(fetchedRoom, isNotNull);
      expect(fetchedRoom!.roomCode, room.roomCode);
    });

    test('Step 2: Guest joins the room with room code', () async {
      // Host creates room first
      final createdRoom = await mockDb.createRoom(
        hostId: hostId,
        difficulty: GameDifficulty.easy,
      );
      hostPlayer.syncWithRoom(createdRoom);
      final roomCode = createdRoom.roomCode;

      // Guest joins using room code
      final joinedRoom = await mockDb.joinRoom(
        roomCode: roomCode,
        guestId: guestId,
      );

      // Both players sync
      hostPlayer.syncWithRoom(joinedRoom);
      guestPlayer.syncWithRoom(joinedRoom);

      // Verify guest joined
      expect(joinedRoom.guestId, guestId);
      expect(joinedRoom.isFull, true);
      expect(joinedRoom.canJoin, false);
      expect(joinedRoom.scores[guestId], 0);
      expect(joinedRoom.scores.length, 2);

      // Both players should see the same room state
      expect(hostPlayer.room?.guestId, guestId);
      expect(guestPlayer.room?.hostId, hostId);
    });

    test('Step 3: Game starts with cards generated', () async {
      // Setup: Create and join room
      final createdRoom = await mockDb.createRoom(
        hostId: hostId,
        difficulty: GameDifficulty.easy,
      );
      final joinedRoom = await mockDb.joinRoom(
        roomCode: createdRoom.roomCode,
        guestId: guestId,
      );

      // Start game
      final playingRoom = await mockDb.startGame(
        joinedRoom.roomCode,
        GameDifficulty.easy,
        gameService,
      );

      // Both players sync
      hostPlayer.syncWithRoom(playingRoom);
      guestPlayer.syncWithRoom(playingRoom);

      // Verify game started
      expect(playingRoom.status, GameRoomStatus.playing);
      expect(playingRoom.cards.isNotEmpty, true);
      expect(playingRoom.startedAt, isNotNull);

      // Easy mode = 2x2 grid = 4 cards = 2 pairs
      expect(playingRoom.cards.length, 4);
      expect(playingRoom.totalPairs, 2);

      // Verify both players have same cards
      expect(hostPlayer.localCards.length, playingRoom.cards.length);
      expect(guestPlayer.localCards.length, playingRoom.cards.length);

      // Verify cards are shuffled and have pairs
      final symbols = playingRoom.cards.map((c) => c.symbol).toList();
      final uniqueSymbols = symbols.toSet();
      expect(uniqueSymbols.length, 2); // 2 unique symbols for 2 pairs
    });

    test('Step 4: Players take turns and cards sync', () async {
      // Full setup
      final createdRoom = await mockDb.createRoom(
        hostId: hostId,
        difficulty: GameDifficulty.easy,
      );
      await mockDb.joinRoom(roomCode: createdRoom.roomCode, guestId: guestId);
      var room = await mockDb.startGame(
        createdRoom.roomCode,
        GameDifficulty.easy,
        gameService,
      );

      hostPlayer.syncWithRoom(room);
      guestPlayer.syncWithRoom(room);

      // Verify host starts
      expect(room.currentTurn, hostId);
      expect(hostPlayer.isMyTurn, true);
      expect(guestPlayer.isMyTurn, false);

      // Host makes a move - flip first card
      var cards = List<GameCard>.from(room.cards);
      cards[0] = cards[0].flip();
      room = await mockDb.updateCards(room.roomCode, cards);

      // Sync both players
      hostPlayer.syncWithRoom(room);
      guestPlayer.syncWithRoom(room);

      // Verify sync
      expect(hostPlayer.localCards[0].isFlipped, true);
      expect(guestPlayer.localCards[0].isFlipped, true);

      // Host flips second card
      cards = List<GameCard>.from(room.cards);
      cards[1] = cards[1].flip();
      room = await mockDb.updateCards(room.roomCode, cards);

      hostPlayer.syncWithRoom(room);
      guestPlayer.syncWithRoom(room);

      // Both should see both cards flipped
      expect(hostPlayer.localCards[1].isFlipped, true);
      expect(guestPlayer.localCards[1].isFlipped, true);
    });

    test('Step 5: Match detection and score update', () async {
      // Setup with controlled cards for testing
      final createdRoom = await mockDb.createRoom(
        hostId: hostId,
        difficulty: GameDifficulty.easy,
      );
      await mockDb.joinRoom(roomCode: createdRoom.roomCode, guestId: guestId);
      var room = await mockDb.startGame(
        createdRoom.roomCode,
        GameDifficulty.easy,
        gameService,
      );

      // Find two matching cards
      final cards = room.cards;
      int? firstMatchIndex;
      int? secondMatchIndex;

      for (var i = 0; i < cards.length; i++) {
        for (var j = i + 1; j < cards.length; j++) {
          if (cards[i].symbol == cards[j].symbol) {
            firstMatchIndex = i;
            secondMatchIndex = j;
            break;
          }
        }
        if (firstMatchIndex != null) break;
      }

      expect(firstMatchIndex, isNotNull);
      expect(secondMatchIndex, isNotNull);

      // Host flips the matching cards
      var updatedCards = List<GameCard>.from(cards);
      updatedCards[firstMatchIndex!] = updatedCards[firstMatchIndex].flip();
      updatedCards[secondMatchIndex!] = updatedCards[secondMatchIndex].flip();

      // Check match
      final isMatch = gameService.checkMatch(
        updatedCards[firstMatchIndex],
        updatedCards[secondMatchIndex],
      );
      expect(isMatch, true);

      // Mark as matched
      updatedCards = gameService.markAsMatched(
        updatedCards,
        updatedCards[firstMatchIndex],
        updatedCards[secondMatchIndex],
      );

      room = await mockDb.updateCards(room.roomCode, updatedCards);

      // Update host's score
      room = await mockDb.updateScore(room.roomCode, hostId, 1);

      hostPlayer.syncWithRoom(room);
      guestPlayer.syncWithRoom(room);

      // Verify match and score
      expect(hostPlayer.localCards[firstMatchIndex].isMatched, true);
      expect(hostPlayer.localCards[secondMatchIndex].isMatched, true);
      expect(guestPlayer.localCards[firstMatchIndex].isMatched, true);
      expect(guestPlayer.localCards[secondMatchIndex].isMatched, true);
      expect(hostPlayer.myScore, 1);
      expect(room.scores[hostId], 1);
    });

    test('Step 6: Turn switching on no match', () async {
      // Setup
      final createdRoom = await mockDb.createRoom(
        hostId: hostId,
        difficulty: GameDifficulty.easy,
      );
      await mockDb.joinRoom(roomCode: createdRoom.roomCode, guestId: guestId);
      var room = await mockDb.startGame(
        createdRoom.roomCode,
        GameDifficulty.easy,
        gameService,
      );

      // Find two non-matching cards
      final cards = room.cards;
      int? firstIndex;
      int? secondIndex;

      for (var i = 0; i < cards.length; i++) {
        for (var j = i + 1; j < cards.length; j++) {
          if (cards[i].symbol != cards[j].symbol) {
            firstIndex = i;
            secondIndex = j;
            break;
          }
        }
        if (firstIndex != null) break;
      }

      // Host flips non-matching cards
      var updatedCards = List<GameCard>.from(cards);
      updatedCards[firstIndex!] = updatedCards[firstIndex].flip();
      updatedCards[secondIndex!] = updatedCards[secondIndex].flip();

      // Check no match
      final isMatch = gameService.checkMatch(
        updatedCards[firstIndex],
        updatedCards[secondIndex],
      );
      expect(isMatch, false);

      // Reset cards (flip back)
      updatedCards = gameService.resetFlippedCards(updatedCards);
      room = await mockDb.updateCards(room.roomCode, updatedCards);

      // Switch turn to guest
      room = await mockDb.updateTurn(room.roomCode, guestId);

      hostPlayer.syncWithRoom(room);
      guestPlayer.syncWithRoom(room);

      // Verify turn switched
      expect(room.currentTurn, guestId);
      expect(hostPlayer.isMyTurn, false);
      expect(guestPlayer.isMyTurn, true);

      // Verify cards are reset (not matched cards should be face down)
      final flippedCards = room.cards.where((c) => c.isFlipped && !c.isMatched);
      expect(flippedCards.length, 0);
    });

    test('Step 7: Complete game until all pairs matched', () async {
      // Setup
      final createdRoom = await mockDb.createRoom(
        hostId: hostId,
        difficulty: GameDifficulty.easy,
      );
      await mockDb.joinRoom(roomCode: createdRoom.roomCode, guestId: guestId);
      var room = await mockDb.startGame(
        createdRoom.roomCode,
        GameDifficulty.easy,
        gameService,
      );

      // Find all pairs and match them
      var cards = List<GameCard>.from(room.cards);
      final pairs = <List<int>>[];

      // Group cards by symbol to find pairs
      final symbolToIndices = <String, List<int>>{};
      for (var i = 0; i < cards.length; i++) {
        final symbol = cards[i].symbol;
        symbolToIndices.putIfAbsent(symbol, () => []);
        symbolToIndices[symbol]!.add(i);
      }

      for (final indices in symbolToIndices.values) {
        if (indices.length >= 2) {
          pairs.add([indices[0], indices[1]]);
        }
      }

      // Simulate game play - match all pairs alternating between players
      var currentPlayer = hostId;
      var hostScore = 0;
      var guestScore = 0;

      for (var i = 0; i < pairs.length; i++) {
        final pair = pairs[i];

        // Player flips and matches
        cards[pair[0]] = cards[pair[0]].flip().match();
        cards[pair[1]] = cards[pair[1]].flip().match();

        room = await mockDb.updateCards(room.roomCode, cards);

        // Update score
        if (currentPlayer == hostId) {
          hostScore++;
          room = await mockDb.updateScore(room.roomCode, hostId, hostScore);
        } else {
          guestScore++;
          room = await mockDb.updateScore(room.roomCode, guestId, guestScore);
        }

        // Alternate turns
        currentPlayer = currentPlayer == hostId ? guestId : hostId;
        room = await mockDb.updateTurn(room.roomCode, currentPlayer);
      }

      // Sync both players
      hostPlayer.syncWithRoom(room);
      guestPlayer.syncWithRoom(room);

      // Verify all cards matched
      expect(room.cards.every((c) => c.isMatched), true);
      expect(room.isComplete, true);
      expect(room.totalMatches, room.totalPairs);
    });

    test('Step 8: Game ends with final scores', () async {
      // Setup and play full game
      final createdRoom = await mockDb.createRoom(
        hostId: hostId,
        difficulty: GameDifficulty.easy,
      );
      await mockDb.joinRoom(roomCode: createdRoom.roomCode, guestId: guestId);
      var room = await mockDb.startGame(
        createdRoom.roomCode,
        GameDifficulty.easy,
        gameService,
      );

      // Match all pairs with scores
      var cards = List<GameCard>.from(room.cards);
      for (var i = 0; i < cards.length; i++) {
        cards[i] = cards[i].copyWith(isMatched: true, isFlipped: true);
      }
      room = await mockDb.updateCards(room.roomCode, cards);
      room = await mockDb.updateScore(room.roomCode, hostId, 1);
      room = await mockDb.updateScore(room.roomCode, guestId, 1);

      // End game
      room = await mockDb.endGame(room.roomCode);

      hostPlayer.syncWithRoom(room);
      guestPlayer.syncWithRoom(room);

      // Verify game ended
      expect(room.status, GameRoomStatus.finished);
      expect(room.finishedAt, isNotNull);

      // Verify final scores
      expect(room.scores[hostId], 1);
      expect(room.scores[guestId], 1);

      // Both players see same final state
      expect(hostPlayer.room?.status, GameRoomStatus.finished);
      expect(guestPlayer.room?.status, GameRoomStatus.finished);
      expect(hostPlayer.room?.scores, guestPlayer.room?.scores);
    });

    test('Full end-to-end multiplayer game simulation', () async {
      // ============ STEP 1: Host creates room ============
      print('\n=== STEP 1: Host creates room ===');
      var room = await mockDb.createRoom(
        hostId: hostId,
        difficulty: GameDifficulty.easy,
      );
      final roomCode = room.roomCode;
      print('Room created with code: $roomCode');
      print('Host: $hostId');
      expect(room.status, GameRoomStatus.waiting);

      // ============ STEP 2: Guest joins room ============
      print('\n=== STEP 2: Guest joins room ===');
      room = await mockDb.joinRoom(roomCode: roomCode, guestId: guestId);
      print('Guest joined: $guestId');
      expect(room.isFull, true);
      hostPlayer.syncWithRoom(room);
      guestPlayer.syncWithRoom(room);

      // ============ STEP 3: Game starts ============
      print('\n=== STEP 3: Game starts ===');
      room = await mockDb.startGame(roomCode, GameDifficulty.easy, gameService);
      print('Game started with ${room.cards.length} cards');
      print('Cards: ${room.cards.map((c) => c.symbol).toList()}');
      expect(room.status, GameRoomStatus.playing);
      hostPlayer.syncWithRoom(room);
      guestPlayer.syncWithRoom(room);

      // ============ STEP 4-7: Play the game ============
      print('\n=== PLAYING THE GAME ===');
      var cards = List<GameCard>.from(room.cards);
      var currentPlayerId = room.currentTurn;
      var hostScore = 0;
      var guestScore = 0;
      var turnCount = 0;

      // Find all pairs
      final symbolToIndices = <String, List<int>>{};
      for (var i = 0; i < cards.length; i++) {
        symbolToIndices.putIfAbsent(cards[i].symbol, () => []).add(i);
      }
      final pairs = symbolToIndices.values.where((v) => v.length >= 2).toList();

      for (final pair in pairs) {
        turnCount++;
        final playerName = currentPlayerId == hostId ? 'Host' : 'Guest';
        print(
          '\nTurn $turnCount: $playerName picks cards at ${pair[0]} and ${pair[1]}',
        );

        // Flip cards
        cards[pair[0]] = cards[pair[0]].flip();
        cards[pair[1]] = cards[pair[1]].flip();

        // Check match
        final isMatch = gameService.checkMatch(cards[pair[0]], cards[pair[1]]);
        print(
          '  Cards: ${cards[pair[0]].symbol} and ${cards[pair[1]].symbol} - Match: $isMatch',
        );

        if (isMatch) {
          // Mark matched
          cards = gameService.markAsMatched(
            cards,
            cards[pair[0]],
            cards[pair[1]],
          );
          room = await mockDb.updateCards(roomCode, cards);

          // Update score
          if (currentPlayerId == hostId) {
            hostScore++;
            room = await mockDb.updateScore(roomCode, hostId, hostScore);
            print('  Host scores! Total: $hostScore');
          } else {
            guestScore++;
            room = await mockDb.updateScore(roomCode, guestId, guestScore);
            print('  Guest scores! Total: $guestScore');
          }
        } else {
          // Reset cards and switch turn
          cards = gameService.resetFlippedCards(cards);
          room = await mockDb.updateCards(roomCode, cards);
          currentPlayerId = currentPlayerId == hostId ? guestId : hostId;
          room = await mockDb.updateTurn(roomCode, currentPlayerId);
          print(
            '  No match - switching to ${currentPlayerId == hostId ? "Host" : "Guest"}',
          );
        }

        // Sync both players
        hostPlayer.syncWithRoom(room);
        guestPlayer.syncWithRoom(room);

        // Verify sync
        expect(hostPlayer.localCards.length, guestPlayer.localCards.length);
        for (var i = 0; i < cards.length; i++) {
          expect(
            hostPlayer.localCards[i].isMatched,
            guestPlayer.localCards[i].isMatched,
          );
        }
      }

      // ============ STEP 8: Game ends ============
      print('\n=== STEP 8: Game ends ===');
      expect(room.isComplete, true);
      room = await mockDb.endGame(roomCode);
      hostPlayer.syncWithRoom(room);
      guestPlayer.syncWithRoom(room);

      print('Final Status: ${room.status}');
      print('Host Score: ${room.scores[hostId]}');
      print('Guest Score: ${room.scores[guestId]}');

      // Final assertions
      expect(room.status, GameRoomStatus.finished);
      expect(room.finishedAt, isNotNull);
      expect(hostPlayer.room?.status, GameRoomStatus.finished);
      expect(guestPlayer.room?.status, GameRoomStatus.finished);

      // Determine winner
      final hostFinalScore = room.scores[hostId]!;
      final guestFinalScore = room.scores[guestId]!;
      if (hostFinalScore > guestFinalScore) {
        print('Winner: Host!');
      } else if (guestFinalScore > hostFinalScore) {
        print('Winner: Guest!');
      } else {
        print('Result: Tie!');
      }

      print('\n=== TEST COMPLETE ===\n');
    });
  });

  group('Edge Cases and Error Handling', () {
    late MockFirebaseDatabase mockDb;
    late GameService gameService;

    setUp(() {
      mockDb = MockFirebaseDatabase();
      gameService = GameService();
    });

    test('Cannot join non-existent room', () async {
      expect(
        () => mockDb.joinRoom(roomCode: '0000', guestId: 'guest'),
        throwsException,
      );
    });

    test('Cannot join own room', () async {
      const userId = 'same-user';
      final room = await mockDb.createRoom(
        hostId: userId,
        difficulty: GameDifficulty.easy,
      );

      expect(
        () => mockDb.joinRoom(roomCode: room.roomCode, guestId: userId),
        throwsException,
      );
    });

    test('Cannot join full room', () async {
      final room = await mockDb.createRoom(
        hostId: 'host1',
        difficulty: GameDifficulty.easy,
      );
      await mockDb.joinRoom(roomCode: room.roomCode, guestId: 'guest1');

      expect(
        () => mockDb.joinRoom(roomCode: room.roomCode, guestId: 'guest2'),
        throwsException,
      );
    });

    test('Room state persists through multiple operations', () async {
      var room = await mockDb.createRoom(
        hostId: 'persist-host',
        difficulty: GameDifficulty.medium,
      );
      final roomCode = room.roomCode;

      room = await mockDb.joinRoom(
        roomCode: roomCode,
        guestId: 'persist-guest',
      );
      room = await mockDb.startGame(
        roomCode,
        GameDifficulty.medium,
        gameService,
      );
      room = await mockDb.updateScore(roomCode, 'persist-host', 5);
      room = await mockDb.updateScore(roomCode, 'persist-guest', 3);
      room = await mockDb.endGame(roomCode);

      final finalRoom = mockDb.getRoom(roomCode);
      expect(finalRoom?.status, GameRoomStatus.finished);
      expect(finalRoom?.scores['persist-host'], 5);
      expect(finalRoom?.scores['persist-guest'], 3);
    });

    test('Medium difficulty generates correct card count', () async {
      final room = await mockDb.createRoom(
        hostId: 'medium-host',
        difficulty: GameDifficulty.medium,
      );
      await mockDb.joinRoom(roomCode: room.roomCode, guestId: 'medium-guest');
      final playingRoom = await mockDb.startGame(
        room.roomCode,
        GameDifficulty.medium,
        gameService,
      );

      // Medium = 4x4 grid = 16 cards = 8 pairs
      expect(playingRoom.cards.length, 16);
      expect(playingRoom.totalPairs, 8);
    });

    test('Hard difficulty generates correct card count', () async {
      final room = await mockDb.createRoom(
        hostId: 'hard-host',
        difficulty: GameDifficulty.hard,
      );
      await mockDb.joinRoom(roomCode: room.roomCode, guestId: 'hard-guest');
      final playingRoom = await mockDb.startGame(
        room.roomCode,
        GameDifficulty.hard,
        gameService,
      );

      // Hard = 6x6 grid = 36 cards = 18 pairs
      expect(playingRoom.cards.length, 36);
      expect(playingRoom.totalPairs, 18);
    });
  });

  group('Data Synchronization Tests', () {
    late MockFirebaseDatabase mockDb;
    late GameService gameService;
    late PlayerState host;
    late PlayerState guest;

    setUp(() {
      mockDb = MockFirebaseDatabase();
      gameService = GameService();
      host = PlayerState('sync-host');
      guest = PlayerState('sync-guest');
    });

    test('Both players see identical card order', () async {
      final room = await mockDb.createRoom(
        hostId: 'sync-host',
        difficulty: GameDifficulty.easy,
      );
      await mockDb.joinRoom(roomCode: room.roomCode, guestId: 'sync-guest');
      final playingRoom = await mockDb.startGame(
        room.roomCode,
        GameDifficulty.easy,
        gameService,
      );

      host.syncWithRoom(playingRoom);
      guest.syncWithRoom(playingRoom);

      // Verify identical card order
      for (var i = 0; i < playingRoom.cards.length; i++) {
        expect(host.localCards[i].id, guest.localCards[i].id);
        expect(host.localCards[i].symbol, guest.localCards[i].symbol);
        expect(host.localCards[i].position, guest.localCards[i].position);
      }
    });

    test('Score updates sync to both players', () async {
      var room = await mockDb.createRoom(
        hostId: 'sync-host',
        difficulty: GameDifficulty.easy,
      );
      await mockDb.joinRoom(roomCode: room.roomCode, guestId: 'sync-guest');
      room = await mockDb.startGame(
        room.roomCode,
        GameDifficulty.easy,
        gameService,
      );

      // Host scores
      room = await mockDb.updateScore(room.roomCode, 'sync-host', 2);
      host.syncWithRoom(room);
      guest.syncWithRoom(room);

      expect(host.room?.scores['sync-host'], 2);
      expect(guest.room?.scores['sync-host'], 2);

      // Guest scores
      room = await mockDb.updateScore(room.roomCode, 'sync-guest', 1);
      host.syncWithRoom(room);
      guest.syncWithRoom(room);

      expect(host.room?.scores['sync-guest'], 1);
      expect(guest.room?.scores['sync-guest'], 1);
    });

    test('Turn changes sync to both players', () async {
      var room = await mockDb.createRoom(
        hostId: 'sync-host',
        difficulty: GameDifficulty.easy,
      );
      await mockDb.joinRoom(roomCode: room.roomCode, guestId: 'sync-guest');
      room = await mockDb.startGame(
        room.roomCode,
        GameDifficulty.easy,
        gameService,
      );

      host.syncWithRoom(room);
      guest.syncWithRoom(room);

      expect(host.isMyTurn, true);
      expect(guest.isMyTurn, false);

      // Switch turn
      room = await mockDb.updateTurn(room.roomCode, 'sync-guest');
      host.syncWithRoom(room);
      guest.syncWithRoom(room);

      expect(host.isMyTurn, false);
      expect(guest.isMyTurn, true);
    });
  });
}
