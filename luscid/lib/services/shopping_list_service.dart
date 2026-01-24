/// Shopping List Game Service
///
/// Handles the co-op shopping list memory game with real-time sync.
library;

import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

/// Shopping item model
class ShoppingItem {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final bool isTarget; // Is this item in the list to memorize?
  final bool isSelected; // Has this item been selected?
  final String? selectedBy; // User ID who selected this item

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
      category: json['category'] as String? ?? 'other',
      isTarget: json['isTarget'] as bool? ?? false,
      isSelected: json['isSelected'] as bool? ?? false,
      selectedBy: json['selectedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'category': category,
    'isTarget': isTarget,
    'isSelected': isSelected,
    'selectedBy': selectedBy,
  };

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

/// Shopping list game phase
enum ShoppingGamePhase {
  waiting, // Waiting for players
  memorize, // Players memorizing the target list
  selection, // Players selecting items
  results, // Showing results
  finished, // Game complete
}

/// Shopping list game room
class ShoppingGameRoom {
  final String roomCode;
  final String hostId;
  final String? guestId;
  final List<ShoppingItem> targetItems; // Items to memorize
  final List<ShoppingItem> allItems; // All items for selection
  final ShoppingGamePhase phase;
  final int memorizeTimeSeconds;
  final int selectionTimeSeconds;
  final DateTime createdAt;
  final DateTime? memorizeStartedAt;
  final DateTime? selectionStartedAt;
  final DateTime? finishedAt;
  final int score;
  final Map<String, int> playerScores;
  final String? voiceNoteUrl;

  const ShoppingGameRoom({
    required this.roomCode,
    required this.hostId,
    this.guestId,
    required this.targetItems,
    required this.allItems,
    required this.phase,
    this.memorizeTimeSeconds = 30,
    this.selectionTimeSeconds = 60,
    required this.createdAt,
    this.memorizeStartedAt,
    this.selectionStartedAt,
    this.finishedAt,
    this.score = 0,
    this.playerScores = const {},
    this.voiceNoteUrl,
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
              ?.map(
                (e) =>
                    ShoppingItem.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          [],
      allItems:
          (json['allItems'] as List?)
              ?.map(
                (e) =>
                    ShoppingItem.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList() ??
          [],
      phase: ShoppingGamePhase.values.firstWhere(
        (e) => e.name == json['phase'],
        orElse: () => ShoppingGamePhase.waiting,
      ),
      memorizeTimeSeconds: json['memorizeTimeSeconds'] as int? ?? 30,
      selectionTimeSeconds: json['selectionTimeSeconds'] as int? ?? 60,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      memorizeStartedAt: json['memorizeStartedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['memorizeStartedAt'] as int,
            )
          : null,
      selectionStartedAt: json['selectionStartedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['selectionStartedAt'] as int,
            )
          : null,
      finishedAt: json['finishedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['finishedAt'] as int)
          : null,
      score: json['score'] as int? ?? 0,
      playerScores: Map<String, int>.from(json['playerScores'] as Map? ?? {}),
      voiceNoteUrl: json['voiceNoteUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'roomCode': roomCode,
    'hostId': hostId,
    'guestId': guestId,
    'targetItems': targetItems.map((e) => e.toJson()).toList(),
    'allItems': allItems.map((e) => e.toJson()).toList(),
    'phase': phase.name,
    'memorizeTimeSeconds': memorizeTimeSeconds,
    'selectionTimeSeconds': selectionTimeSeconds,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'memorizeStartedAt': memorizeStartedAt?.millisecondsSinceEpoch,
    'selectionStartedAt': selectionStartedAt?.millisecondsSinceEpoch,
    'finishedAt': finishedAt?.millisecondsSinceEpoch,
    'score': score,
    'playerScores': playerScores,
    'voiceNoteUrl': voiceNoteUrl,
  };

  ShoppingGameRoom copyWith({
    String? roomCode,
    String? hostId,
    String? guestId,
    List<ShoppingItem>? targetItems,
    List<ShoppingItem>? allItems,
    ShoppingGamePhase? phase,
    int? memorizeTimeSeconds,
    int? selectionTimeSeconds,
    DateTime? createdAt,
    DateTime? memorizeStartedAt,
    DateTime? selectionStartedAt,
    DateTime? finishedAt,
    int? score,
    Map<String, int>? playerScores,
    String? voiceNoteUrl,
  }) {
    return ShoppingGameRoom(
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      guestId: guestId ?? this.guestId,
      targetItems: targetItems ?? this.targetItems,
      allItems: allItems ?? this.allItems,
      phase: phase ?? this.phase,
      memorizeTimeSeconds: memorizeTimeSeconds ?? this.memorizeTimeSeconds,
      selectionTimeSeconds: selectionTimeSeconds ?? this.selectionTimeSeconds,
      createdAt: createdAt ?? this.createdAt,
      memorizeStartedAt: memorizeStartedAt ?? this.memorizeStartedAt,
      selectionStartedAt: selectionStartedAt ?? this.selectionStartedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      score: score ?? this.score,
      playerScores: playerScores ?? this.playerScores,
      voiceNoteUrl: voiceNoteUrl ?? this.voiceNoteUrl,
    );
  }
}

/// All available shopping items
class ShoppingItemsData {
  static const List<Map<String, String>> items = [
    // Fruits
    {'id': 'apple', 'name': 'Apple', 'emoji': '🍎', 'category': 'fruits'},
    {'id': 'banana', 'name': 'Banana', 'emoji': '🍌', 'category': 'fruits'},
    {'id': 'orange', 'name': 'Orange', 'emoji': '🍊', 'category': 'fruits'},
    {'id': 'grapes', 'name': 'Grapes', 'emoji': '🍇', 'category': 'fruits'},
    {'id': 'mango', 'name': 'Mango', 'emoji': '🥭', 'category': 'fruits'},
    {
      'id': 'watermelon',
      'name': 'Watermelon',
      'emoji': '🍉',
      'category': 'fruits',
    },

    // Vegetables
    {'id': 'carrot', 'name': 'Carrot', 'emoji': '🥕', 'category': 'vegetables'},
    {'id': 'tomato', 'name': 'Tomato', 'emoji': '🍅', 'category': 'vegetables'},
    {'id': 'potato', 'name': 'Potato', 'emoji': '🥔', 'category': 'vegetables'},
    {'id': 'onion', 'name': 'Onion', 'emoji': '🧅', 'category': 'vegetables'},
    {
      'id': 'broccoli',
      'name': 'Broccoli',
      'emoji': '🥦',
      'category': 'vegetables',
    },
    {'id': 'corn', 'name': 'Corn', 'emoji': '🌽', 'category': 'vegetables'},

    // Dairy
    {'id': 'milk', 'name': 'Milk', 'emoji': '🥛', 'category': 'dairy'},
    {'id': 'cheese', 'name': 'Cheese', 'emoji': '🧀', 'category': 'dairy'},
    {'id': 'butter', 'name': 'Butter', 'emoji': '🧈', 'category': 'dairy'},
    {'id': 'egg', 'name': 'Eggs', 'emoji': '🥚', 'category': 'dairy'},

    // Bakery
    {'id': 'bread', 'name': 'Bread', 'emoji': '🍞', 'category': 'bakery'},
    {
      'id': 'croissant',
      'name': 'Croissant',
      'emoji': '🥐',
      'category': 'bakery',
    },
    {'id': 'cake', 'name': 'Cake', 'emoji': '🍰', 'category': 'bakery'},
    {'id': 'cookie', 'name': 'Cookies', 'emoji': '🍪', 'category': 'bakery'},

    // Meat & Fish
    {'id': 'chicken', 'name': 'Chicken', 'emoji': '🍗', 'category': 'meat'},
    {'id': 'fish', 'name': 'Fish', 'emoji': '🐟', 'category': 'meat'},
    {'id': 'shrimp', 'name': 'Shrimp', 'emoji': '🦐', 'category': 'meat'},

    // Beverages
    {'id': 'coffee', 'name': 'Coffee', 'emoji': '☕', 'category': 'beverages'},
    {'id': 'tea', 'name': 'Tea', 'emoji': '🍵', 'category': 'beverages'},
    {'id': 'juice', 'name': 'Juice', 'emoji': '🧃', 'category': 'beverages'},
    {'id': 'water', 'name': 'Water', 'emoji': '💧', 'category': 'beverages'},

    // Other
    {'id': 'rice', 'name': 'Rice', 'emoji': '🍚', 'category': 'grains'},
    {'id': 'honey', 'name': 'Honey', 'emoji': '🍯', 'category': 'other'},
    {'id': 'salt', 'name': 'Salt', 'emoji': '🧂', 'category': 'other'},
  ];

  static List<ShoppingItem> getAllItems() {
    return items
        .map(
          (e) => ShoppingItem(
            id: e['id']!,
            name: e['name']!,
            emoji: e['emoji']!,
            category: e['category']!,
          ),
        )
        .toList();
  }
}

class ShoppingListService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final Random _random = Random();

  /// Reference to shopping game rooms
  DatabaseReference get _roomsRef => _database.ref('shopping_rooms');

  /// Gets a reference to a specific room
  DatabaseReference _roomRef(String roomCode) => _roomsRef.child(roomCode);

  /// Generates a random room code
  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(4, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  /// Creates a new shopping list game room
  Future<ShoppingGameRoom> createRoom({
    required String hostId,
    int targetItemCount = 8,
    int totalItemCount = 20,
    int memorizeTimeSeconds = 30,
    int selectionTimeSeconds = 60,
  }) async {
    // Generate unique room code
    String roomCode;
    bool codeExists = true;

    do {
      roomCode = _generateRoomCode();
      final snapshot = await _roomRef(roomCode).get();
      codeExists = snapshot.exists;
    } while (codeExists);

    // Generate items
    final allAvailableItems = ShoppingItemsData.getAllItems();
    allAvailableItems.shuffle(_random);

    // Take items for the game
    final gameItems = allAvailableItems.take(totalItemCount).toList();

    // Select target items to memorize
    final targetIndices = <int>{};
    while (targetIndices.length < targetItemCount) {
      targetIndices.add(_random.nextInt(totalItemCount));
    }

    final targetItems = <ShoppingItem>[];
    final allItems = <ShoppingItem>[];

    for (int i = 0; i < gameItems.length; i++) {
      final isTarget = targetIndices.contains(i);
      final item = gameItems[i].copyWith(isTarget: isTarget);
      allItems.add(item);
      if (isTarget) {
        targetItems.add(item);
      }
    }

    // Shuffle allItems for selection phase
    allItems.shuffle(_random);

    final room = ShoppingGameRoom(
      roomCode: roomCode,
      hostId: hostId,
      targetItems: targetItems,
      allItems: allItems,
      phase: ShoppingGamePhase.waiting,
      memorizeTimeSeconds: memorizeTimeSeconds,
      selectionTimeSeconds: selectionTimeSeconds,
      createdAt: DateTime.now(),
      playerScores: {hostId: 0},
    );

    await _roomRef(roomCode).set(room.toJson());
    return room;
  }

  /// Joins an existing room
  Future<ShoppingGameRoom?> joinRoom({
    required String roomCode,
    required String guestId,
  }) async {
    final snapshot = await _roomRef(roomCode).get();

    if (!snapshot.exists) {
      throw Exception('Room not found. Please check the code.');
    }

    final room = ShoppingGameRoom.fromJson(
      Map<String, dynamic>.from(snapshot.value as Map),
    );

    if (!room.canJoin) {
      throw Exception('This room is no longer available.');
    }

    if (room.hostId == guestId) {
      throw Exception('You cannot join your own room.');
    }

    final updatedScores = Map<String, int>.from(room.playerScores);
    updatedScores[guestId] = 0;

    await _roomRef(
      roomCode,
    ).update({'guestId': guestId, 'playerScores': updatedScores});

    return room.copyWith(guestId: guestId, playerScores: updatedScores);
  }

  /// Starts the memorize phase
  Future<void> startMemorizePhase(String roomCode) async {
    await _roomRef(roomCode).update({
      'phase': ShoppingGamePhase.memorize.name,
      'memorizeStartedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Starts the selection phase
  Future<void> startSelectionPhase(String roomCode) async {
    await _roomRef(roomCode).update({
      'phase': ShoppingGamePhase.selection.name,
      'selectionStartedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Selects an item (real-time co-op)
  Future<void> selectItem({
    required String roomCode,
    required String itemId,
    required String userId,
  }) async {
    final snapshot = await _roomRef(roomCode).get();
    if (!snapshot.exists) return;

    final room = ShoppingGameRoom.fromJson(
      Map<String, dynamic>.from(snapshot.value as Map),
    );

    final updatedItems = room.allItems.map((item) {
      if (item.id == itemId && !item.isSelected) {
        return item.copyWith(isSelected: true, selectedBy: userId);
      }
      return item;
    }).toList();

    // Calculate current score
    final correctSelections = updatedItems
        .where((i) => i.isSelected && i.isTarget)
        .length;
    final incorrectSelections = updatedItems
        .where((i) => i.isSelected && !i.isTarget)
        .length;
    final newScore = correctSelections - incorrectSelections;

    // Update player scores
    final updatedPlayerScores = Map<String, int>.from(room.playerScores);
    final playerCorrect = updatedItems
        .where((i) => i.isSelected && i.isTarget && i.selectedBy == userId)
        .length;
    updatedPlayerScores[userId] = playerCorrect;

    await _roomRef(roomCode).update({
      'allItems': updatedItems.map((e) => e.toJson()).toList(),
      'score': newScore,
      'playerScores': updatedPlayerScores,
    });
  }

  /// Deselects an item
  Future<void> deselectItem({
    required String roomCode,
    required String itemId,
    required String userId,
  }) async {
    final snapshot = await _roomRef(roomCode).get();
    if (!snapshot.exists) return;

    final room = ShoppingGameRoom.fromJson(
      Map<String, dynamic>.from(snapshot.value as Map),
    );

    final updatedItems = room.allItems.map((item) {
      if (item.id == itemId && item.selectedBy == userId) {
        return item.copyWith(isSelected: false, selectedBy: null);
      }
      return item;
    }).toList();

    // Recalculate scores
    final correctSelections = updatedItems
        .where((i) => i.isSelected && i.isTarget)
        .length;
    final incorrectSelections = updatedItems
        .where((i) => i.isSelected && !i.isTarget)
        .length;
    final newScore = correctSelections - incorrectSelections;

    final updatedPlayerScores = Map<String, int>.from(room.playerScores);
    final playerCorrect = updatedItems
        .where((i) => i.isSelected && i.isTarget && i.selectedBy == userId)
        .length;
    updatedPlayerScores[userId] = playerCorrect;

    await _roomRef(roomCode).update({
      'allItems': updatedItems.map((e) => e.toJson()).toList(),
      'score': newScore,
      'playerScores': updatedPlayerScores,
    });
  }

  /// Shows results
  Future<void> showResults(String roomCode) async {
    await _roomRef(roomCode).update({'phase': ShoppingGamePhase.results.name});
  }

  /// Ends the game
  Future<void> endGame(String roomCode) async {
    await _roomRef(roomCode).update({
      'phase': ShoppingGamePhase.finished.name,
      'finishedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Updates voice note URL
  Future<void> updateVoiceNote(String roomCode, String url) async {
    await _roomRef(roomCode).update({'voiceNoteUrl': url});
  }

  /// Deletes a room
  Future<void> deleteRoom(String roomCode) async {
    await _roomRef(roomCode).remove();
  }

  /// Watches a room for real-time updates
  Stream<ShoppingGameRoom?> watchRoom(String roomCode) {
    return _roomRef(roomCode).onValue.map((event) {
      if (!event.snapshot.exists) return null;
      return ShoppingGameRoom.fromJson(
        Map<String, dynamic>.from(event.snapshot.value as Map),
      );
    });
  }

  /// Gets a room once
  Future<ShoppingGameRoom?> getRoom(String roomCode) async {
    final snapshot = await _roomRef(roomCode).get();
    if (!snapshot.exists) return null;
    return ShoppingGameRoom.fromJson(
      Map<String, dynamic>.from(snapshot.value as Map),
    );
  }

  /// Calculates final score
  Map<String, dynamic> calculateFinalScore(ShoppingGameRoom room) {
    final correctSelections = room.allItems
        .where((i) => i.isSelected && i.isTarget)
        .toList();
    final incorrectSelections = room.allItems
        .where((i) => i.isSelected && !i.isTarget)
        .toList();
    final missedItems = room.allItems
        .where((i) => !i.isSelected && i.isTarget)
        .toList();

    final accuracy = room.targetItems.isEmpty
        ? 0.0
        : (correctSelections.length / room.targetItems.length) * 100;

    return {
      'correct': correctSelections.length,
      'incorrect': incorrectSelections.length,
      'missed': missedItems.length,
      'total': room.targetItems.length,
      'accuracy': accuracy,
      'score': room.score,
      'playerScores': room.playerScores,
    };
  }
}
