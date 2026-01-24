/// Unit tests for GameRoom model
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:luscid/models/game_room_model.dart';
import 'package:luscid/models/game_card_model.dart';

void main() {
  group('GameRoom', () {
    test('creates room with required fields', () {
      final room = GameRoom(
        roomCode: '1234',
        hostId: 'host-uid',
        gridSize: 2,
        cards: [],
        scores: {},
        currentTurn: 'host-uid',
        status: GameRoomStatus.waiting,
        createdAt: DateTime.now(),
      );

      expect(room.roomCode, '1234');
      expect(room.hostId, 'host-uid');
      expect(room.status, GameRoomStatus.waiting);
    });

    test('creates room with guest', () {
      final room = GameRoom(
        roomCode: '5678',
        hostId: 'host-uid',
        guestId: 'guest-uid',
        gridSize: 4,
        cards: [],
        scores: {'host-uid': 0, 'guest-uid': 0},
        currentTurn: 'host-uid',
        status: GameRoomStatus.playing,
        createdAt: DateTime.now(),
      );

      expect(room.guestId, 'guest-uid');
      expect(room.status, GameRoomStatus.playing);
    });

    test('guestId is set when guest joins', () {
      final room = GameRoom(
        roomCode: '1111',
        hostId: 'host',
        guestId: 'guest',
        gridSize: 2,
        cards: [],
        scores: {},
        currentTurn: 'host',
        status: GameRoomStatus.waiting,
        createdAt: DateTime.now(),
      );

      expect(room.guestId, isNotNull);
      expect(room.guestId, 'guest');
    });

    test('guestId is null when no guest', () {
      final room = GameRoom(
        roomCode: '2222',
        hostId: 'host',
        gridSize: 2,
        cards: [],
        scores: {},
        currentTurn: 'host',
        status: GameRoomStatus.waiting,
        createdAt: DateTime.now(),
      );

      expect(room.guestId, isNull);
    });

    test('can determine opponent from host and guest ids', () {
      final room = GameRoom(
        roomCode: '3333',
        hostId: 'host-id',
        guestId: 'guest-id',
        gridSize: 2,
        cards: [],
        scores: {},
        currentTurn: 'host-id',
        status: GameRoomStatus.playing,
        createdAt: DateTime.now(),
      );

      // Can get opponent manually
      final opponentForHost = room.guestId;
      expect(opponentForHost, 'guest-id');
    });

    test('scores track both players', () {
      final room = GameRoom(
        roomCode: '4444',
        hostId: 'host-id',
        guestId: 'guest-id',
        gridSize: 2,
        cards: [],
        scores: {'host-id': 3, 'guest-id': 2},
        currentTurn: 'guest-id',
        status: GameRoomStatus.playing,
        createdAt: DateTime.now(),
      );

      expect(room.scores['host-id'], 3);
      expect(room.scores['guest-id'], 2);
    });

    test('copyWith creates new instance with changes', () {
      final original = GameRoom(
        roomCode: '5555',
        hostId: 'host',
        gridSize: 2,
        cards: [],
        scores: {},
        currentTurn: 'host',
        status: GameRoomStatus.waiting,
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(
        guestId: 'new-guest',
        status: GameRoomStatus.playing,
      );

      expect(updated.roomCode, original.roomCode);
      expect(updated.guestId, 'new-guest');
      expect(updated.status, GameRoomStatus.playing);
    });

    test('toJson serializes correctly', () {
      final room = GameRoom(
        roomCode: '6666',
        hostId: 'host-json',
        gridSize: 4,
        cards: [GameCard(id: 'c1', symbol: '🍎', position: 0)],
        scores: {'host-json': 3},
        currentTurn: 'host-json',
        status: GameRoomStatus.playing,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = room.toJson();

      expect(json['roomCode'], '6666');
      expect(json['hostId'], 'host-json');
      expect(json['gridSize'], 4);
      expect(json['status'], 'playing');
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'roomCode': '7777',
        'hostId': 'from-json-host',
        'gridSize': 6,
        'cards': <Map<String, dynamic>>[],
        'scores': <String, dynamic>{},
        'currentTurn': 'from-json-host',
        'status': 'waiting',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      final room = GameRoom.fromJson(json);

      expect(room.roomCode, '7777');
      expect(room.hostId, 'from-json-host');
      expect(room.gridSize, 6);
      expect(room.status, GameRoomStatus.waiting);
    });
  });

  group('GameRoomStatus', () {
    test('all statuses have string values', () {
      expect(GameRoomStatus.waiting.name, isNotEmpty);
      expect(GameRoomStatus.playing.name, isNotEmpty);
      expect(GameRoomStatus.finished.name, isNotEmpty);
    });
  });
}
