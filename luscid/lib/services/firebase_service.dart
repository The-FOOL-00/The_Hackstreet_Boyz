/// Firebase service for multiplayer game rooms
///
/// Handles room creation, joining, and real-time game state synchronization.
library;

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/game_room_model.dart';
import '../models/game_card_model.dart';
import '../core/constants/game_icons.dart';
import '../core/utils/helpers.dart';
import 'game_service.dart';

class FirebaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GameService _gameService = GameService();

  /// Reference to game rooms
  DatabaseReference get _roomsRef => _database.ref('game_rooms');

  /// Gets a reference to a specific room
  DatabaseReference _roomRef(String roomCode) => _roomsRef.child(roomCode);

  // ==================== Room Management ====================

  /// Creates a new game room
  Future<GameRoom> createRoom({
    required String hostId,
    required GameDifficulty difficulty,
  }) async {
    // Generate unique room code
    String roomCode;
    bool codeExists = true;

    do {
      roomCode = Helpers.generateRoomCode();
      final snapshot = await _roomRef(roomCode).get();
      codeExists = snapshot.exists;
    } while (codeExists);

    // Create room
    final room = GameRoom.create(
      roomCode: roomCode,
      hostId: hostId,
      difficulty: difficulty,
    );

    // Save to Firebase
    await _roomRef(roomCode).set(room.toJson());

    return room;
  }

  /// Joins an existing room
  Future<GameRoom?> joinRoom({
    required String roomCode,
    required String guestId,
  }) async {
    final snapshot = await _roomRef(roomCode).get();

    if (!snapshot.exists) {
      throw Exception('Room not found. Please check the code and try again.');
    }

    final room = GameRoom.fromJson(
      Map<String, dynamic>.from(snapshot.value as Map),
    );

    if (!room.canJoin) {
      throw Exception('This room is no longer available.');
    }

    if (room.hostId == guestId) {
      throw Exception('You cannot join your own room.');
    }

    // Update room with guest
    final updatedScores = Map<String, int>.from(room.scores);
    updatedScores[guestId] = 0;

    final updatedRoom = room.copyWith(guestId: guestId, scores: updatedScores);

    await _roomRef(
      roomCode,
    ).update({'guestId': guestId, 'scores': updatedScores});

    return updatedRoom;
  }

  /// Starts the game (generates and shuffles cards)
  Future<void> startGame(String roomCode, GameDifficulty difficulty) async {
    final cards = _gameService.generateCards(difficulty);

    await _roomRef(roomCode).update({
      'cards': cards.map((c) => c.toJson()).toList(),
      'status': GameRoomStatus.playing.name,
      'startedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Updates a card's state
  Future<void> updateCard(String roomCode, int cardIndex, GameCard card) async {
    await _roomRef(
      roomCode,
    ).child('cards').child('$cardIndex').update(card.toJson());
  }

  /// Updates multiple cards (for match/reset)
  Future<void> updateCards(String roomCode, List<GameCard> cards) async {
    await _roomRef(
      roomCode,
    ).update({'cards': cards.map((c) => c.toJson()).toList()});
  }

  /// Updates the current turn
  Future<void> updateTurn(String roomCode, String nextPlayerId) async {
    await _roomRef(roomCode).update({'currentTurn': nextPlayerId});
  }

  /// Updates a player's score
  Future<void> updateScore(String roomCode, String playerId, int score) async {
    await _roomRef(roomCode).child('scores').update({playerId: score});
  }

  /// Ends the game
  Future<void> endGame(String roomCode) async {
    await _roomRef(roomCode).update({
      'status': GameRoomStatus.finished.name,
      'finishedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Deletes a room
  Future<void> deleteRoom(String roomCode) async {
    await _roomRef(roomCode).remove();
  }

  // ==================== Real-time Listeners ====================

  /// Listens to room changes
  Stream<GameRoom?> watchRoom(String roomCode) {
    return _roomRef(roomCode).onValue.map((event) {
      if (!event.snapshot.exists) return null;
      return GameRoom.fromJson(
        Map<String, dynamic>.from(event.snapshot.value as Map),
      );
    });
  }

  /// Gets a room once
  Future<GameRoom?> getRoom(String roomCode) async {
    final snapshot = await _roomRef(roomCode).get();
    if (!snapshot.exists) return null;
    return GameRoom.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
  }

  /// Checks if a room exists
  Future<bool> roomExists(String roomCode) async {
    final snapshot = await _roomRef(roomCode).get();
    return snapshot.exists;
  }

  // ==================== Cleanup ====================

  /// Cleans up old/abandoned rooms (older than 1 hour)
  Future<void> cleanupOldRooms() async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    final snapshot = await _roomsRef.get();

    if (!snapshot.exists) return;

    final rooms = Map<String, dynamic>.from(snapshot.value as Map);
    for (final entry in rooms.entries) {
      try {
        final room = GameRoom.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        if (room.createdAt.isBefore(cutoff)) {
          await deleteRoom(entry.key);
        }
      } catch (e) {
        // Skip invalid rooms
      }
    }
  }
}
