/// Shopping List Game Provider
///
/// Manages shopping list game state with real-time sync.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/shopping_list_service.dart';

class ShoppingListProvider extends ChangeNotifier {
  final ShoppingListService _service = ShoppingListService();

  String? _currentUserId;
  ShoppingGameRoom? _room;
  bool _isLoading = false;
  String? _error;

  Timer? _phaseTimer;
  int _timeRemaining = 0;

  StreamSubscription<ShoppingGameRoom?>? _roomSubscription;

  // Getters
  ShoppingGameRoom? get room => _room;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isHost => _room?.hostId == _currentUserId;
  bool get isInRoom => _room != null;
  int get timeRemaining => _timeRemaining;

  ShoppingGamePhase get phase => _room?.phase ?? ShoppingGamePhase.waiting;
  List<ShoppingItem> get targetItems => _room?.targetItems ?? [];
  List<ShoppingItem> get allItems => _room?.allItems ?? [];
  int get score => _room?.score ?? 0;
  Map<String, int> get playerScores => _room?.playerScores ?? {};

  /// Initializes with user ID
  void init(String userId) {
    _currentUserId = userId;
  }

  /// Creates a new game room
  Future<String?> createRoom({
    int targetItemCount = 8,
    int totalItemCount = 20,
    int memorizeTimeSeconds = 30,
    int selectionTimeSeconds = 60,
  }) async {
    if (_currentUserId == null) {
      _error = 'Not logged in';
      notifyListeners();
      return null;
    }

    _setLoading(true);
    _clearError();

    try {
      _room = await _service.createRoom(
        hostId: _currentUserId!,
        targetItemCount: targetItemCount,
        totalItemCount: totalItemCount,
        memorizeTimeSeconds: memorizeTimeSeconds,
        selectionTimeSeconds: selectionTimeSeconds,
      );

      _startWatchingRoom(_room!.roomCode);
      notifyListeners();
      return _room!.roomCode;
    } catch (e) {
      _error = 'Failed to create room: ${e.toString()}';
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Joins an existing room
  Future<bool> joinRoom(String roomCode) async {
    if (_currentUserId == null) {
      _error = 'Not logged in';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      _room = await _service.joinRoom(
        roomCode: roomCode,
        guestId: _currentUserId!,
      );

      _startWatchingRoom(roomCode);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Starts watching room changes
  void _startWatchingRoom(String roomCode) {
    _roomSubscription?.cancel();
    _roomSubscription = _service.watchRoom(roomCode).listen((room) {
      final previousPhase = _room?.phase;
      _room = room;

      // Handle phase transitions
      if (room != null && previousPhase != room.phase) {
        _handlePhaseChange(room.phase, room);
      }

      notifyListeners();
    });
  }

  /// Handles phase transitions
  void _handlePhaseChange(ShoppingGamePhase newPhase, ShoppingGameRoom room) {
    _phaseTimer?.cancel();

    switch (newPhase) {
      case ShoppingGamePhase.memorize:
        _startCountdown(room.memorizeTimeSeconds, () async {
          if (isHost) {
            await _service.startSelectionPhase(room.roomCode);
          }
        });
        break;
      case ShoppingGamePhase.selection:
        _startCountdown(room.selectionTimeSeconds, () async {
          if (isHost) {
            await _service.showResults(room.roomCode);
          }
        });
        break;
      case ShoppingGamePhase.results:
        _timeRemaining = 0;
        break;
      default:
        _timeRemaining = 0;
    }
  }

  /// Starts countdown timer
  void _startCountdown(int seconds, VoidCallback onComplete) {
    _timeRemaining = seconds;
    notifyListeners();

    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeRemaining--;
      notifyListeners();

      if (_timeRemaining <= 0) {
        timer.cancel();
        onComplete();
      }
    });
  }

  /// Starts the game (host only)
  Future<void> startGame() async {
    if (_room == null || !isHost) return;

    _setLoading(true);
    try {
      await _service.startMemorizePhase(_room!.roomCode);
    } catch (e) {
      _error = 'Failed to start game: ${e.toString()}';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Selects an item
  Future<void> selectItem(String itemId) async {
    if (_room == null || _currentUserId == null) return;
    if (phase != ShoppingGamePhase.selection) return;

    try {
      await _service.selectItem(
        roomCode: _room!.roomCode,
        itemId: itemId,
        userId: _currentUserId!,
      );
    } catch (e) {
      _error = 'Failed to select item: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Deselects an item
  Future<void> deselectItem(String itemId) async {
    if (_room == null || _currentUserId == null) return;
    if (phase != ShoppingGamePhase.selection) return;

    try {
      await _service.deselectItem(
        roomCode: _room!.roomCode,
        itemId: itemId,
        userId: _currentUserId!,
      );
    } catch (e) {
      _error = 'Failed to deselect item: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Toggles item selection
  Future<void> toggleItem(String itemId) async {
    final item = allItems.firstWhere(
      (i) => i.id == itemId,
      orElse: () => throw Exception('Item not found'),
    );

    if (item.isSelected && item.selectedBy == _currentUserId) {
      await deselectItem(itemId);
    } else if (!item.isSelected) {
      await selectItem(itemId);
    }
  }

  /// Gets final score breakdown
  Map<String, dynamic> getFinalScore() {
    if (_room == null) return {};
    return _service.calculateFinalScore(_room!);
  }

  /// Ends the game and returns to results
  Future<void> finishGame() async {
    if (_room == null || !isHost) return;

    try {
      await _service.endGame(_room!.roomCode);
    } catch (e) {
      _error = 'Failed to end game: ${e.toString()}';
      notifyListeners();
    }
  }

  /// Leaves the current room
  Future<void> leaveRoom() async {
    _phaseTimer?.cancel();
    _roomSubscription?.cancel();

    if (_room != null && isHost) {
      await _service.deleteRoom(_room!.roomCode);
    }

    _room = null;
    _timeRemaining = 0;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _roomSubscription?.cancel();
    super.dispose();
  }
}
