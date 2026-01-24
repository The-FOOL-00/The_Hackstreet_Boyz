/// Game provider for memory match game state management
///
/// Manages single-player and multiplayer game state.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/game_card_model.dart';
import '../models/game_room_model.dart';
import '../core/constants/game_icons.dart';
import '../core/utils/helpers.dart';
import '../services/game_service.dart';
import '../services/firebase_service.dart';

enum GameMode { singlePlayer, multiplayer }

enum GameState { idle, playing, paused, completed }

class GameProvider extends ChangeNotifier {
  late final GameService _gameService;
  late final FirebaseService _firebaseService;

  // Game state
  GameMode _mode = GameMode.singlePlayer;
  GameState _state = GameState.idle;
  GameDifficulty _difficulty = GameDifficulty.easy;
  List<GameCard> _cards = [];

  // Selection state
  GameCard? _firstSelectedCard;
  GameCard? _secondSelectedCard;
  bool _isProcessing = false;

  // Stats
  int _matchesFound = 0;
  int _moves = 0;

  // Multiplayer
  GameRoom? _room;
  StreamSubscription? _roomSubscription;
  String? _currentUserId;

  // Loading & errors
  bool _isLoading = false;
  String? _error;
  String? _message;

  GameProvider() {
    _gameService = GameService();
    _firebaseService = FirebaseService();
  }

  // Getters
  GameMode get mode => _mode;
  GameState get state => _state;
  GameDifficulty get difficulty => _difficulty;
  List<GameCard> get cards => _cards;
  GameCard? get firstSelectedCard => _firstSelectedCard;
  GameCard? get secondSelectedCard => _secondSelectedCard;
  bool get isProcessing => _isProcessing;
  int get matchesFound => _matchesFound;
  int get moves => _moves;
  int get totalPairs => _cards.length ~/ 2;
  bool get isGameComplete => _state == GameState.completed;
  GameRoom? get room => _room;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get message => _message;
  bool get isMultiplayer => _mode == GameMode.multiplayer;
  bool get isMyTurn => !isMultiplayer || (_room?.currentTurn == _currentUserId);
  int get gridSize => _gameService.getGridSize(_cards);

  // ==================== Single Player ====================

  /// Starts a new single-player game
  void startSinglePlayerGame(GameDifficulty difficulty) {
    _mode = GameMode.singlePlayer;
    _difficulty = difficulty;
    _cards = _gameService.generateCards(difficulty);
    _resetGameState();
    _state = GameState.playing;
    notifyListeners();
  }

  /// Handles card tap in single-player mode
  Future<void> onCardTap(int index) async {
    if (_state != GameState.playing) return;
    if (_isProcessing) return;
    if (!isMyTurn) return;

    final card = _cards[index];

    // Can't tap matched or already flipped cards
    if (card.isMatched || card.isFlipped) return;

    // Flip the card
    _cards = _gameService.flipCard(_cards, index);
    notifyListeners();

    if (_firstSelectedCard == null) {
      // First card selected
      _firstSelectedCard = _cards[index];
    } else {
      // Second card selected
      _secondSelectedCard = _cards[index];
      _moves++;
      _isProcessing = true;
      notifyListeners();

      // Check for match
      await _checkForMatch();
    }
  }

  Future<void> _checkForMatch() async {
    if (_firstSelectedCard == null || _secondSelectedCard == null) return;

    final isMatch = _gameService.checkMatch(
      _firstSelectedCard!,
      _secondSelectedCard!,
    );

    if (isMatch) {
      // Match found!
      _cards = _gameService.markAsMatched(
        _cards,
        _firstSelectedCard!,
        _secondSelectedCard!,
      );
      _matchesFound++;
      _message = Helpers.getMatchMessage();

      if (isMultiplayer && _room != null) {
        // Update multiplayer state
        await _firebaseService.updateCards(_room!.roomCode, _cards);
        await _firebaseService.updateScore(
          _room!.roomCode,
          _currentUserId!,
          (_room!.scores[_currentUserId] ?? 0) + 1,
        );
      }

      // Check if game is complete
      if (_gameService.isGameComplete(_cards)) {
        _state = GameState.completed;
        _message = Helpers.getGameCompleteMessage();

        if (isMultiplayer && _room != null) {
          await _firebaseService.endGame(_room!.roomCode);
        }
      }
    } else {
      // No match - flip cards back after delay
      await Helpers.delay(1000);
      _cards = _gameService.resetFlippedCards(_cards);

      if (isMultiplayer && _room != null) {
        // Switch turns
        final nextPlayer =
            _room!.getOpponentId(_currentUserId!) ?? _currentUserId!;
        await _firebaseService.updateCards(_room!.roomCode, _cards);
        await _firebaseService.updateTurn(_room!.roomCode, nextPlayer);
      }
    }

    _firstSelectedCard = null;
    _secondSelectedCard = null;
    _isProcessing = false;
    notifyListeners();
  }

  /// Restarts the current game
  void restartGame() {
    if (_mode == GameMode.singlePlayer) {
      startSinglePlayerGame(_difficulty);
    }
  }

  // ==================== Multiplayer ====================

  /// Sets the current user ID for multiplayer
  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  /// Creates a new multiplayer room
  Future<String?> createRoom(GameDifficulty difficulty) async {
    _setLoading(true);
    _clearError();

    try {
      if (_currentUserId == null) {
        throw Exception('User not logged in');
      }

      _room = await _firebaseService.createRoom(
        hostId: _currentUserId!,
        difficulty: difficulty,
      );
      _mode = GameMode.multiplayer;
      _difficulty = difficulty;

      // Start listening to room changes
      _subscribeToRoom(_room!.roomCode);

      _setLoading(false);
      return _room!.roomCode;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  /// Joins an existing room
  Future<bool> joinRoom(String roomCode) async {
    _setLoading(true);
    _clearError();

    try {
      if (_currentUserId == null) {
        throw Exception('User not logged in');
      }

      _room = await _firebaseService.joinRoom(
        roomCode: roomCode,
        guestId: _currentUserId!,
      );

      if (_room == null) {
        throw Exception('Failed to join room');
      }

      _mode = GameMode.multiplayer;

      // Start listening to room changes
      _subscribeToRoom(roomCode);

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Starts the multiplayer game (host only)
  Future<void> startMultiplayerGame() async {
    if (_room == null || _room!.hostId != _currentUserId) return;

    _setLoading(true);
    try {
      await _firebaseService.startGame(_room!.roomCode, _difficulty);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _subscribeToRoom(String roomCode) {
    _roomSubscription?.cancel();
    _roomSubscription = _firebaseService.watchRoom(roomCode).listen((room) {
      if (room == null) {
        _error = 'Room no longer exists';
        _room = null;
        notifyListeners();
        return;
      }

      final wasWaiting = _room?.status == GameRoomStatus.waiting;
      _room = room;
      _cards = room.cards;

      // Auto-start game when room becomes full (host only)
      if (wasWaiting &&
          room.isFull &&
          room.status == GameRoomStatus.waiting &&
          room.hostId == _currentUserId) {
        // Room just became full, start the game
        startMultiplayerGame();
      }

      if (room.status == GameRoomStatus.playing &&
          _state != GameState.playing) {
        _state = GameState.playing;
        _resetGameState();
      } else if (room.status == GameRoomStatus.finished) {
        _state = GameState.completed;
        _message = Helpers.getGameCompleteMessage();
      }

      // Update matches count for current user
      _matchesFound = room.scores[_currentUserId] ?? 0;

      notifyListeners();
    });
  }

  /// Leaves the current room
  Future<void> leaveRoom() async {
    _roomSubscription?.cancel();
    _roomSubscription = null;

    if (_room != null &&
        _room!.hostId == _currentUserId &&
        _room!.status == GameRoomStatus.waiting) {
      // Host leaving waiting room - delete it
      await _firebaseService.deleteRoom(_room!.roomCode);
    }

    _room = null;
    _mode = GameMode.singlePlayer;
    _state = GameState.idle;
    _cards = [];
    notifyListeners();
  }

  // ==================== Helpers ====================

  void _resetGameState() {
    _firstSelectedCard = null;
    _secondSelectedCard = null;
    _isProcessing = false;
    _matchesFound = 0;
    _moves = 0;
    _message = null;
    _error = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    _message = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }

  /// Resets the provider to initial state
  void reset() {
    _roomSubscription?.cancel();
    _roomSubscription = null;
    _room = null;
    _mode = GameMode.singlePlayer;
    _state = GameState.idle;
    _difficulty = GameDifficulty.easy;
    _cards = [];
    _resetGameState();
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }
}
