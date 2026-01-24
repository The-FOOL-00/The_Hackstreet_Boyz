/// Game room model for multiplayer sessions
///
/// Manages the state of a multiplayer game room in Firebase.
library;

import 'game_card_model.dart';
import '../core/constants/game_icons.dart';

class GameRoom {
  final String roomCode;
  final String hostId;
  final String? guestId;
  final int gridSize;
  final List<GameCard> cards;
  final String currentTurn; // userId of current player
  final Map<String, int> scores; // userId -> match count
  final GameRoomStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  const GameRoom({
    required this.roomCode,
    required this.hostId,
    this.guestId,
    required this.gridSize,
    required this.cards,
    required this.currentTurn,
    required this.scores,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.finishedAt,
  });

  /// Creates a copy with updated fields
  GameRoom copyWith({
    String? roomCode,
    String? hostId,
    String? guestId,
    int? gridSize,
    List<GameCard>? cards,
    String? currentTurn,
    Map<String, int>? scores,
    GameRoomStatus? status,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? finishedAt,
  }) {
    return GameRoom(
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      guestId: guestId ?? this.guestId,
      gridSize: gridSize ?? this.gridSize,
      cards: cards ?? this.cards,
      currentTurn: currentTurn ?? this.currentTurn,
      scores: scores ?? this.scores,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  /// Serializes to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'roomCode': roomCode,
      'hostId': hostId,
      'guestId': guestId,
      'gridSize': gridSize,
      'cards': cards.map((c) => c.toJson()).toList(),
      'currentTurn': currentTurn,
      'scores': scores,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'startedAt': startedAt?.millisecondsSinceEpoch,
      'finishedAt': finishedAt?.millisecondsSinceEpoch,
    };
  }

  /// Deserializes from JSON
  factory GameRoom.fromJson(Map<String, dynamic> json) {
    return GameRoom(
      roomCode: json['roomCode'] as String,
      hostId: json['hostId'] as String,
      guestId: json['guestId'] as String?,
      gridSize: json['gridSize'] as int,
      cards: (json['cards'] as List)
          .map((c) => GameCard.fromJson(c as Map<String, dynamic>))
          .toList(),
      currentTurn: json['currentTurn'] as String,
      scores: Map<String, int>.from(json['scores'] as Map),
      status: GameRoomStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GameRoomStatus.waiting,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      startedAt: json['startedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startedAt'] as int)
          : null,
      finishedAt: json['finishedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['finishedAt'] as int)
          : null,
    );
  }

  /// Creates a new room with host
  factory GameRoom.create({
    required String roomCode,
    required String hostId,
    required GameDifficulty difficulty,
  }) {
    return GameRoom(
      roomCode: roomCode,
      hostId: hostId,
      guestId: null,
      gridSize: GameIcons.getGridSize(difficulty),
      cards: [], // Cards generated when game starts
      currentTurn: hostId,
      scores: {hostId: 0},
      status: GameRoomStatus.waiting,
      createdAt: DateTime.now(),
    );
  }

  /// Checks if the room is full (has both players)
  bool get isFull => guestId != null;

  /// Checks if the room can accept more players
  bool get canJoin => !isFull && status == GameRoomStatus.waiting;

  /// Gets the total number of matched pairs
  int get totalMatches => cards.where((c) => c.isMatched).length ~/ 2;

  /// Gets the total number of pairs
  int get totalPairs => cards.length ~/ 2;

  /// Checks if all pairs are matched
  bool get isComplete => totalMatches == totalPairs && cards.isNotEmpty;

  /// Gets the other player's ID
  String? getOpponentId(String playerId) {
    if (playerId == hostId) return guestId;
    if (playerId == guestId) return hostId;
    return null;
  }

  /// Gets the score for a player
  int getScore(String playerId) => scores[playerId] ?? 0;

  @override
  String toString() {
    return 'GameRoom(code: $roomCode, status: $status, host: $hostId, guest: $guestId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameRoom && other.roomCode == roomCode;
  }

  @override
  int get hashCode => roomCode.hashCode;
}

/// Game room status
enum GameRoomStatus {
  waiting, // Waiting for guest to join
  playing, // Game in progress
  finished, // Game completed
}

extension GameRoomStatusExtension on GameRoomStatus {
  String get displayName {
    switch (this) {
      case GameRoomStatus.waiting:
        return 'Waiting for player...';
      case GameRoomStatus.playing:
        return 'Game in progress';
      case GameRoomStatus.finished:
        return 'Game finished';
    }
  }
}
