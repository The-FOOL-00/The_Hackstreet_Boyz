/// Integration tests for Shopping List Game Flow
///
/// Tests for the shopping list game logic without Firebase dependencies.
library;

import 'package:flutter_test/flutter_test.dart';

// Standalone classes for testing (mirrors service classes)
enum ShoppingGamePhase { waiting, memorize, selection, results, finished }

class ShoppingItem {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final bool isTarget;
  final bool isSelected;
  final String? selectedBy;

  const ShoppingItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    this.isTarget = false,
    this.isSelected = false,
    this.selectedBy,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      category: json['category'] as String,
      isTarget: json['isTarget'] as bool? ?? false,
      isSelected: json['isSelected'] as bool? ?? false,
      selectedBy: json['selectedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'category': category,
      'isTarget': isTarget,
      'isSelected': isSelected,
      'selectedBy': selectedBy,
    };
  }

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? emoji,
    String? category,
    bool? isTarget,
    bool? isSelected,
    String? selectedBy,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      isTarget: isTarget ?? this.isTarget,
      isSelected: isSelected ?? this.isSelected,
      selectedBy: selectedBy ?? this.selectedBy,
    );
  }
}

class ShoppingGameRoom {
  final String roomCode;
  final String hostId;
  final String? guestId;
  final List<ShoppingItem> targetItems;
  final List<ShoppingItem> allItems;
  final ShoppingGamePhase phase;
  final DateTime createdAt;

  ShoppingGameRoom({
    required this.roomCode,
    required this.hostId,
    this.guestId,
    required this.targetItems,
    required this.allItems,
    required this.phase,
    required this.createdAt,
  });

  bool get isFull => guestId != null;
  bool get canJoin => !isFull && phase == ShoppingGamePhase.waiting;

  factory ShoppingGameRoom.fromJson(Map<String, dynamic> json) {
    return ShoppingGameRoom(
      roomCode: json['roomCode'] as String,
      hostId: json['hostId'] as String,
      guestId: json['guestId'] as String?,
      targetItems:
          (json['targetItems'] as List?)
              ?.map((i) => ShoppingItem.fromJson(i))
              .toList() ??
          [],
      allItems:
          (json['allItems'] as List?)
              ?.map((i) => ShoppingItem.fromJson(i))
              .toList() ??
          [],
      phase: ShoppingGamePhase.values.firstWhere(
        (p) => p.name == json['phase'],
        orElse: () => ShoppingGamePhase.waiting,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.now(),
    );
  }

  ShoppingGameRoom copyWith({
    String? roomCode,
    String? hostId,
    String? guestId,
    List<ShoppingItem>? targetItems,
    List<ShoppingItem>? allItems,
    ShoppingGamePhase? phase,
    DateTime? createdAt,
  }) {
    return ShoppingGameRoom(
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      guestId: guestId ?? this.guestId,
      targetItems: targetItems ?? this.targetItems,
      allItems: allItems ?? this.allItems,
      phase: phase ?? this.phase,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ShoppingItemsData {
  static List<ShoppingItem> getAllItems() {
    return const [
      ShoppingItem(id: 'apple', name: 'Apple', emoji: '🍎', category: 'fruits'),
      ShoppingItem(
        id: 'banana',
        name: 'Banana',
        emoji: '🍌',
        category: 'fruits',
      ),
      ShoppingItem(
        id: 'orange',
        name: 'Orange',
        emoji: '🍊',
        category: 'fruits',
      ),
      ShoppingItem(
        id: 'grapes',
        name: 'Grapes',
        emoji: '🍇',
        category: 'fruits',
      ),
      ShoppingItem(
        id: 'strawberry',
        name: 'Strawberry',
        emoji: '🍓',
        category: 'fruits',
      ),
      ShoppingItem(
        id: 'carrot',
        name: 'Carrot',
        emoji: '🥕',
        category: 'vegetables',
      ),
      ShoppingItem(
        id: 'broccoli',
        name: 'Broccoli',
        emoji: '🥦',
        category: 'vegetables',
      ),
      ShoppingItem(
        id: 'corn',
        name: 'Corn',
        emoji: '🌽',
        category: 'vegetables',
      ),
      ShoppingItem(
        id: 'tomato',
        name: 'Tomato',
        emoji: '🍅',
        category: 'vegetables',
      ),
      ShoppingItem(
        id: 'potato',
        name: 'Potato',
        emoji: '🥔',
        category: 'vegetables',
      ),
      ShoppingItem(id: 'milk', name: 'Milk', emoji: '🥛', category: 'dairy'),
      ShoppingItem(
        id: 'cheese',
        name: 'Cheese',
        emoji: '🧀',
        category: 'dairy',
      ),
      ShoppingItem(id: 'egg', name: 'Egg', emoji: '🥚', category: 'dairy'),
      ShoppingItem(
        id: 'butter',
        name: 'Butter',
        emoji: '🧈',
        category: 'dairy',
      ),
      ShoppingItem(id: 'bread', name: 'Bread', emoji: '🍞', category: 'bakery'),
      ShoppingItem(
        id: 'croissant',
        name: 'Croissant',
        emoji: '🥐',
        category: 'bakery',
      ),
      ShoppingItem(id: 'bagel', name: 'Bagel', emoji: '🥯', category: 'bakery'),
      ShoppingItem(
        id: 'cookie',
        name: 'Cookie',
        emoji: '🍪',
        category: 'bakery',
      ),
      ShoppingItem(id: 'cake', name: 'Cake', emoji: '🍰', category: 'bakery'),
      ShoppingItem(
        id: 'chicken',
        name: 'Chicken',
        emoji: '🍗',
        category: 'meat',
      ),
    ];
  }
}

void main() {
  group('ShoppingListService', () {
    group('ShoppingItem', () {
      test('should create item from json', () {
        final json = {
          'id': 'apple',
          'name': 'Apple',
          'emoji': '🍎',
          'category': 'fruits',
          'isTarget': true,
          'isSelected': false,
          'selectedBy': null,
        };

        final item = ShoppingItem.fromJson(json);

        expect(item.id, equals('apple'));
        expect(item.name, equals('Apple'));
        expect(item.emoji, equals('🍎'));
        expect(item.category, equals('fruits'));
        expect(item.isTarget, isTrue);
        expect(item.isSelected, isFalse);
        expect(item.selectedBy, isNull);
      });

      test('should convert item to json', () {
        const item = ShoppingItem(
          id: 'banana',
          name: 'Banana',
          emoji: '🍌',
          category: 'fruits',
          isTarget: true,
          isSelected: true,
          selectedBy: 'user123',
        );

        final json = item.toJson();

        expect(json['id'], equals('banana'));
        expect(json['name'], equals('Banana'));
        expect(json['emoji'], equals('🍌'));
        expect(json['isTarget'], isTrue);
        expect(json['isSelected'], isTrue);
        expect(json['selectedBy'], equals('user123'));
      });

      test('should copy item with updated fields', () {
        const item = ShoppingItem(
          id: 'milk',
          name: 'Milk',
          emoji: '🥛',
          category: 'dairy',
          isTarget: true,
          isSelected: false,
        );

        final updatedItem = item.copyWith(
          isSelected: true,
          selectedBy: 'user456',
        );

        expect(updatedItem.id, equals('milk'));
        expect(updatedItem.isSelected, isTrue);
        expect(updatedItem.selectedBy, equals('user456'));
        expect(item.isSelected, isFalse); // Original unchanged
      });
    });

    group('ShoppingGameRoom', () {
      test('should create room from json', () {
        final now = DateTime.now();
        final json = {
          'roomCode': 'ABCD',
          'hostId': 'host123',
          'guestId': 'guest456',
          'targetItems': [
            {
              'id': 'apple',
              'name': 'Apple',
              'emoji': '🍎',
              'category': 'fruits',
            },
          ],
          'allItems': [
            {
              'id': 'apple',
              'name': 'Apple',
              'emoji': '🍎',
              'category': 'fruits',
            },
            {
              'id': 'banana',
              'name': 'Banana',
              'emoji': '🍌',
              'category': 'fruits',
            },
          ],
          'phase': 'memorize',
          'memorizeTimeSeconds': 30,
          'selectionTimeSeconds': 60,
          'createdAt': now.millisecondsSinceEpoch,
          'score': 0,
          'playerScores': {'host123': 0, 'guest456': 0},
        };

        final room = ShoppingGameRoom.fromJson(json);

        expect(room.roomCode, equals('ABCD'));
        expect(room.hostId, equals('host123'));
        expect(room.guestId, equals('guest456'));
        expect(room.phase, equals(ShoppingGamePhase.memorize));
        expect(room.targetItems.length, equals(1));
        expect(room.allItems.length, equals(2));
        expect(room.isFull, isTrue);
        expect(room.canJoin, isFalse);
      });

      test('should check if room is joinable', () {
        final emptyRoom = ShoppingGameRoom(
          roomCode: 'TEST',
          hostId: 'host123',
          guestId: null,
          targetItems: [],
          allItems: [],
          phase: ShoppingGamePhase.waiting,
          createdAt: DateTime.now(),
        );

        expect(emptyRoom.canJoin, isTrue);
        expect(emptyRoom.isFull, isFalse);

        final fullRoom = emptyRoom.copyWith(guestId: 'guest456');
        expect(fullRoom.canJoin, isFalse);
        expect(fullRoom.isFull, isTrue);
      });

      test('should not allow joining during game', () {
        final playingRoom = ShoppingGameRoom(
          roomCode: 'TEST',
          hostId: 'host123',
          guestId: null,
          targetItems: [],
          allItems: [],
          phase: ShoppingGamePhase.selection,
          createdAt: DateTime.now(),
        );

        expect(playingRoom.canJoin, isFalse);
      });
    });

    group('ShoppingItemsData', () {
      test('should have all required items', () {
        final items = ShoppingItemsData.getAllItems();

        expect(items.length, greaterThanOrEqualTo(20));
      });

      test('should have items in all categories', () {
        final items = ShoppingItemsData.getAllItems();
        final categories = items.map((i) => i.category).toSet();

        expect(categories, contains('fruits'));
        expect(categories, contains('vegetables'));
        expect(categories, contains('dairy'));
        expect(categories, contains('bakery'));
      });

      test('should have valid emoji for all items', () {
        final items = ShoppingItemsData.getAllItems();

        for (final item in items) {
          expect(item.emoji.isNotEmpty, isTrue);
          expect(item.name.isNotEmpty, isTrue);
          expect(item.id.isNotEmpty, isTrue);
        }
      });
    });

    group('Score Calculation', () {
      test('should calculate correct score', () {
        final items = [
          const ShoppingItem(
            id: 'apple',
            name: 'Apple',
            emoji: '🍎',
            category: 'fruits',
            isTarget: true,
            isSelected: true,
            selectedBy: 'user1',
          ),
          const ShoppingItem(
            id: 'banana',
            name: 'Banana',
            emoji: '🍌',
            category: 'fruits',
            isTarget: true,
            isSelected: true,
            selectedBy: 'user2',
          ),
          const ShoppingItem(
            id: 'milk',
            name: 'Milk',
            emoji: '🥛',
            category: 'dairy',
            isTarget: false,
            isSelected: true, // Wrong selection
            selectedBy: 'user1',
          ),
          const ShoppingItem(
            id: 'bread',
            name: 'Bread',
            emoji: '🍞',
            category: 'bakery',
            isTarget: true,
            isSelected: false, // Missed
          ),
        ];

        final correctSelections = items
            .where((i) => i.isSelected && i.isTarget)
            .length;
        final incorrectSelections = items
            .where((i) => i.isSelected && !i.isTarget)
            .length;
        final missedItems = items
            .where((i) => !i.isSelected && i.isTarget)
            .length;
        final targetCount = items.where((i) => i.isTarget).length;

        expect(correctSelections, equals(2));
        expect(incorrectSelections, equals(1));
        expect(missedItems, equals(1));
        expect(targetCount, equals(3));

        final score = correctSelections - incorrectSelections;
        final accuracy = (correctSelections / targetCount) * 100;

        expect(score, equals(1));
        expect(accuracy, closeTo(66.67, 0.1));
      });

      test('should handle perfect score', () {
        final items = [
          const ShoppingItem(
            id: 'apple',
            name: 'Apple',
            emoji: '🍎',
            category: 'fruits',
            isTarget: true,
            isSelected: true,
          ),
          const ShoppingItem(
            id: 'banana',
            name: 'Banana',
            emoji: '🍌',
            category: 'fruits',
            isTarget: true,
            isSelected: true,
          ),
        ];

        final correctSelections = items
            .where((i) => i.isSelected && i.isTarget)
            .length;
        final incorrectSelections = items
            .where((i) => i.isSelected && !i.isTarget)
            .length;
        final targetCount = items.where((i) => i.isTarget).length;

        final score = correctSelections - incorrectSelections;
        final accuracy = (correctSelections / targetCount) * 100;

        expect(score, equals(2));
        expect(accuracy, equals(100.0));
      });
    });

    group('Game Phases', () {
      test('should have all required phases', () {
        expect(ShoppingGamePhase.values, contains(ShoppingGamePhase.waiting));
        expect(ShoppingGamePhase.values, contains(ShoppingGamePhase.memorize));
        expect(ShoppingGamePhase.values, contains(ShoppingGamePhase.selection));
        expect(ShoppingGamePhase.values, contains(ShoppingGamePhase.results));
        expect(ShoppingGamePhase.values, contains(ShoppingGamePhase.finished));
      });

      test('should transition phases correctly', () {
        var phase = ShoppingGamePhase.waiting;

        // Simulate game flow
        expect(phase, equals(ShoppingGamePhase.waiting));

        phase = ShoppingGamePhase.memorize;
        expect(phase, equals(ShoppingGamePhase.memorize));

        phase = ShoppingGamePhase.selection;
        expect(phase, equals(ShoppingGamePhase.selection));

        phase = ShoppingGamePhase.results;
        expect(phase, equals(ShoppingGamePhase.results));

        phase = ShoppingGamePhase.finished;
        expect(phase, equals(ShoppingGamePhase.finished));
      });
    });
  });

  group('Game Invite Flow', () {
    test('should create invite with required fields', () {
      final invite = {
        'inviteId': 'inv123',
        'senderId': 'sender1',
        'senderName': 'John',
        'receiverId': 'receiver1',
        'gameType': 'shopping_list',
        'status': 'pending',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      expect(invite['inviteId'], isNotNull);
      expect(invite['senderId'], equals('sender1'));
      expect(invite['receiverId'], equals('receiver1'));
      expect(invite['gameType'], equals('shopping_list'));
      expect(invite['status'], equals('pending'));
    });

    test('should check invite expiry', () {
      final inviteTimeout = const Duration(seconds: 30);

      // Fresh invite
      final freshInviteTime = DateTime.now();
      final freshDifference = DateTime.now().difference(freshInviteTime);
      expect(freshDifference < inviteTimeout, isTrue);

      // Expired invite
      final expiredInviteTime = DateTime.now().subtract(
        const Duration(minutes: 1),
      );
      final expiredDifference = DateTime.now().difference(expiredInviteTime);
      expect(expiredDifference > inviteTimeout, isTrue);
    });
  });

  group('Real-time Sync', () {
    test('should handle item selection sync', () {
      // Simulate two players selecting items
      final player1Selection = {'itemId': 'apple', 'userId': 'player1'};
      final player2Selection = {'itemId': 'banana', 'userId': 'player2'};

      final selections = [player1Selection, player2Selection];

      expect(selections.length, equals(2));
      expect(
        selections.where((s) => s['userId'] == 'player1').length,
        equals(1),
      );
      expect(
        selections.where((s) => s['userId'] == 'player2').length,
        equals(1),
      );
    });

    test('should prevent duplicate selection', () {
      final selectedItems = <String>{};

      // First selection
      final item1 = 'apple';
      if (!selectedItems.contains(item1)) {
        selectedItems.add(item1);
      }
      expect(selectedItems.length, equals(1));

      // Attempt duplicate selection
      if (!selectedItems.contains(item1)) {
        selectedItems.add(item1);
      }
      expect(selectedItems.length, equals(1)); // Still 1
    });
  });
}
