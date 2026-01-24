/// Trivia provider for CineRecall game state management
///
/// Manages multiplayer trivia state with Firebase real-time sync.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/trivia_model.dart';

class TriviaProvider extends ChangeNotifier {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Room state
  TriviaRoom? _room;
  StreamSubscription? _roomSubscription;
  String? _currentUserId;

  // UI state
  bool _isLoading = false;
  String? _error;
  String? _feedbackMessage;
  bool? _lastAnswerCorrect;

  // Race condition guards
  bool _isProcessingAction = false;
  bool _isAdvancing = false;
  int _lastProcessedQuestionIndex = -1;

  // Audio player for hints
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingAudio = false;

  // Getters
  TriviaRoom? get room => _room;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get feedbackMessage => _feedbackMessage;
  bool? get lastAnswerCorrect => _lastAnswerCorrect;
  String? get currentUserId => _currentUserId;
  bool get isProcessingAction => _isProcessingAction;
  bool get isPlayingAudio => _isPlayingAudio;

  // Convenience getters
  MoviePuzzle? get currentPuzzle => _room?.currentPuzzle;
  int get currentQuestionIndex => _room?.currentQuestionIndex ?? 0;
  int get totalQuestions => _room?.puzzles.length ?? 0;
  TriviaStatus get status => _room?.status ?? TriviaStatus.waiting;
  bool get showOptions => _room?.showOptions ?? false;
  String? get selectedAnswer => _room?.selectedAnswer;
  String? get selectedBy => _room?.selectedBy;
  Map<String, int> get scores => _room?.scores ?? {};
  bool get isRoomFull => _room?.isRoomFull ?? false;
  bool get isFinished => _room?.isFinished ?? false;
  bool get hasMorePuzzles => _room?.hasMorePuzzles ?? false;

  // Firebase reference
  DatabaseReference get _triviaRoomsRef => _database.ref('trivia_rooms');
  DatabaseReference _roomRef(String roomCode) =>
      _triviaRoomsRef.child(roomCode);

  // ==================== Sample Puzzles ====================

  /// Sample puzzles for CineRecall trivia game
  /// All audio files use .mpeg extension
  static List<MoviePuzzle> get samplePuzzles => [
    // 1. Kaathuvaakula Rendu Kaadhal
    MoviePuzzle(
      id: '1',
      category: 'Modern Romantic Comedy',
      imageAsset: 'assets/trivia/puzzle_kaathu.jpeg',
      audioAsset: 'assets/audio/two_two_two.mpeg',
      answer: 'Kaathuvaakula Rendu Kaadhal',
      options: ['Kaathuvaakula Rendu Kaadhal', 'Naanum Rowdy Dhaan', '96', 'Super Deluxe'],
      hint: 'Rendu laddu thinna aasaiya?',
      hintType: HintType.audio,
    ),

    // 2. Keladi Kanmani
    MoviePuzzle(
      id: '2',
      category: 'Tamil Classic',
      imageAsset: 'assets/trivia/puzzle_keladi.jpeg',
      audioAsset: 'assets/audio/manil intha kadhal.mpeg',
      answer: 'Keladi Kanmani',
      options: ['Keladi Kanmani', 'Pudhu Pudhu Arthangal', 'Mouna Ragam', 'Sindhu Bhairavi'],
      hint: 'Mannil Indha Kaadhal... - The legendary breathless song by SPB!',
      hintType: HintType.audio,
    ),

    // 3. Spider-Man 2
    MoviePuzzle(
      id: '3',
      category: 'Hollywood Action',
      imageAsset: 'assets/trivia/puzzle_spiderman.jpeg',
      audioAsset: 'assets/audio/spider_man.mpeg',
      answer: 'Spider-Man 2',
      options: ['Spider-Man 2', 'Superman', 'Batman Begins', 'Iron Man'],
      hint: 'Spidey Sense is tingling!',
      hintType: HintType.audio,
    ),

    // 4. Madagascar
    MoviePuzzle(
      id: '4',
      category: 'Animated Fun',
      imageAsset: 'assets/trivia/puzzle_madagascar.jpeg',
      audioAsset: 'assets/audio/afro_circus.mpeg',
      answer: 'Madagascar',
      options: ['Madagascar', 'Ice Age', 'The Lion King', 'Kung Fu Panda'],
      hint: 'I like to move it, move it!',
      hintType: HintType.audio,
    ),

    // 5. Maine Pyaar Kyun Kiya
    MoviePuzzle(
      id: '5',
      category: 'Bollywood Comedy',
      imageAsset: 'assets/trivia/puzzle_mainepyaar.jpeg',
      audioAsset: 'assets/audio/chill.mpeg',
      answer: 'Maine Pyaar Kyun Kiya',
      options: ['Maine Pyaar Kyun Kiya', 'Partner', 'No Entry', 'Mujhse Shaadi Karogi'],
      hint: 'Just Chill, Chill, Just Chill!',
      hintType: HintType.audio,
    ),
  ];

  // ==================== Room Management ====================

  /// Sets the current user ID
  void setCurrentUser(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  /// Starts a solo game without Firebase
  /// Creates a local room for single-player practice
  void startSoloGame() {
    _clearError();
    _roomSubscription?.cancel();

    final soloUserId = 'solo_player';
    _currentUserId = soloUserId;

    // Create local room (no Firebase)
    _room = TriviaRoom(
      roomCode: 'solo',
      hostId: soloUserId,
      guestId: 'ai_opponent', // Fake opponent so room is "full"
      scores: {soloUserId: 0, 'ai_opponent': 0},
      puzzles: samplePuzzles,
      status: TriviaStatus.discussing,
      currentQuestionIndex: 0,
      createdAt: DateTime.now(),
    );

    // Reset state
    _lastProcessedQuestionIndex = -1;
    _isProcessingAction = false;
    _isAdvancing = false;
    _feedbackMessage = null;
    _lastAnswerCorrect = null;

    notifyListeners();
  }

  /// Creates a new trivia room
  /// Returns roomCode on success, null on failure
  Future<String?> createRoom(String hostId) async {
    _setLoading(true);
    _clearError();

    try {
      // Generate unique room code
      String roomCode;
      bool codeExists = true;

      do {
        roomCode = _generateRoomCode();
        final snapshot = await _roomRef(roomCode).get();
        codeExists = snapshot.exists;
      } while (codeExists);

      // Create room with sample puzzles
      final room = TriviaRoom.create(
        roomCode: roomCode,
        hostId: hostId,
        puzzles: samplePuzzles,
      );

      // Save to Firebase
      await _roomRef(roomCode).set(room.toJson());

      // Set current user and listen to room
      _currentUserId = hostId;
      _listenToRoom(roomCode);

      _setLoading(false);
      return roomCode;
    } catch (e) {
      _setError('Failed to create room: $e');
      _setLoading(false);
      return null;
    }
  }

  /// Joins an existing trivia room
  /// Returns roomCode on success, null on failure
  Future<String?> joinRoom(String roomCode, String guestId) async {
    _setLoading(true);
    _clearError();

    try {
      final snapshot = await _roomRef(roomCode).get();

      if (!snapshot.exists) {
        throw Exception('Room not found. Please check the code.');
      }

      final room = TriviaRoom.fromJson(
        Map<String, dynamic>.from(snapshot.value as Map),
      );

      if (room.isRoomFull) {
        throw Exception('This room is already full.');
      }

      if (room.hostId == guestId) {
        throw Exception('You cannot join your own room.');
      }

      // Update room with guest
      final updatedScores = Map<String, int>.from(room.scores);
      updatedScores[guestId] = 0;

      await _roomRef(roomCode).update({
        'guestId': guestId,
        'scores': updatedScores,
        'status': TriviaStatus.discussing.name,
      });

      // Set current user and listen to room
      _currentUserId = guestId;
      _listenToRoom(roomCode);

      _setLoading(false);
      return roomCode;
    } catch (e) {
      _setError('Failed to join room: $e');
      _setLoading(false);
      return null;
    }
  }

  /// Start the game (called by host when guest joins)
  Future<void> startGame() async {
    if (_room == null) return;

    try {
      await _roomRef(
        _room!.roomCode,
      ).update({'status': TriviaStatus.discussing.name});
    } catch (e) {
      _setError('Failed to start game: $e');
    }
  }

  // ==================== Game Actions ====================

  /// Reveals the hint for current puzzle
  Future<void> revealHint() async {
    if (_room == null || currentPuzzle == null) return;

    try {
      final updatedPuzzles = _room!.puzzles.map((p) {
        if (p.id == currentPuzzle!.id) {
          return p.copyWith(isRevealed: true);
        }
        return p;
      }).toList();

      await _roomRef(
        _room!.roomCode,
      ).update({'puzzles': updatedPuzzles.map((p) => p.toJson()).toList()});
    } catch (e) {
      _setError('Failed to reveal hint: $e');
    }
  }

  /// Player indicates they are ready to answer (shows options for both)
  /// Uses Firebase transaction to prevent race conditions when both players tap simultaneously
  Future<void> readyToAnswer() async {
    if (_room == null || _isProcessingAction) return;

    // Guard: Already in answering state (partner may have tapped first)
    if (_room!.status == TriviaStatus.answering || _room!.showOptions) {
      return;
    }

    _isProcessingAction = true;
    notifyListeners();

    try {
      // SOLO MODE: Update local state immediately, no Firebase
      if (_room!.roomCode == 'solo') {
        _room = _room!.copyWith(
          status: TriviaStatus.answering,
          showOptions: true,
        );
        _isProcessingAction = false;
        notifyListeners();
        return;
      }

      // MULTIPLAYER MODE: Use Firebase transaction for atomic update
      final ref = _roomRef(_room!.roomCode);
      await ref.runTransaction((currentData) {
        if (currentData == null) return Transaction.abort();

        final data = Map<String, dynamic>.from(currentData as Map);

        // Check if already transitioned (another player beat us)
        if (data['status'] == TriviaStatus.answering.name ||
            data['showOptions'] == true) {
          return Transaction.abort();
        }

        data['status'] = TriviaStatus.answering.name;
        data['showOptions'] = true;
        return Transaction.success(data);
      });
    } catch (e) {
      _setError('Failed to update status: $e');
    } finally {
      _isProcessingAction = false;
      notifyListeners();
    }
  }

  /// Select an answer (syncs to Firebase instantly)
  /// Guards against selecting when partner already answered
  Future<void> selectAnswer(String answer) async {
    if (_room == null || _currentUserId == null || _isProcessingAction) return;

    // Guard: Answer already selected (by us or partner)
    if (_room!.selectedAnswer != null ||
        _room!.status == TriviaStatus.revealed) {
      return;
    }

    _isProcessingAction = true;
    notifyListeners();

    try {
      final puzzleAnswer = currentPuzzle?.answer;
      final questionIndex = _room!.currentQuestionIndex;
      final isCorrect = answer == puzzleAnswer;

      // SOLO MODE: Update local state immediately, no Firebase
      if (_room!.roomCode == 'solo') {
        final scores = Map<String, int>.from(_room!.scores);
        if (isCorrect) {
          scores[_currentUserId!] = (scores[_currentUserId!] ?? 0) + 1;
        }

        _room = _room!.copyWith(
          selectedAnswer: answer,
          selectedBy: _currentUserId,
          status: TriviaStatus.revealed,
          scores: scores,
        );

        _lastAnswerCorrect = isCorrect;
        _feedbackMessage = isCorrect ? 'சரியான பதில்! 🎉' : 'தவறான பதில் 😔';
        _isProcessingAction = false;
        notifyListeners();

        // Auto-advance after delay
        _scheduleAdvance(questionIndex);
        return;
      }

      // MULTIPLAYER MODE: Use transaction for atomic answer submission

      // Use transaction for atomic answer submission
      final ref = _roomRef(_room!.roomCode);
      final result = await ref.runTransaction((currentData) {
        if (currentData == null) return Transaction.abort();

        final data = Map<String, dynamic>.from(currentData as Map);

        // Check if answer already submitted (partner beat us)
        if (data['selectedAnswer'] != null ||
            data['status'] == TriviaStatus.revealed.name) {
          return Transaction.abort();
        }

        // Verify we're still on the same question
        if (data['currentQuestionIndex'] != questionIndex) {
          return Transaction.abort();
        }

        final isCorrect = answer == puzzleAnswer;
        final scores = Map<String, int>.from(data['scores'] as Map);
        if (isCorrect) {
          scores[_currentUserId!] = (scores[_currentUserId!] ?? 0) + 1;
        }

        data['selectedAnswer'] = answer;
        data['selectedBy'] = _currentUserId;
        data['status'] = TriviaStatus.revealed.name;
        data['scores'] = scores;
        return Transaction.success(data);
      });

      // Only set local feedback if our transaction succeeded
      if (result.committed) {
        final isCorrect = answer == puzzleAnswer;
        _lastAnswerCorrect = isCorrect;
        _feedbackMessage = isCorrect ? 'சரியான பதில்! 🎉' : 'தவறான பதில் 😔';
        notifyListeners();

        // Auto-advance after delay (only the answerer triggers this)
        _scheduleAdvance(questionIndex);
      }
    } catch (e) {
      _setError('Failed to submit answer: $e');
    } finally {
      _isProcessingAction = false;
      notifyListeners();
    }
  }

  /// Schedules advance to next question with guard against double-advance
  void _scheduleAdvance(int questionIndex) {
    Future.delayed(const Duration(seconds: 3), () {
      // Guard: Only advance if we haven't already processed this question
      if (_lastProcessedQuestionIndex != questionIndex) {
        _lastProcessedQuestionIndex = questionIndex;
        _advanceToNextQuestion();
      }
    });
  }

  /// Advances to the next question
  /// Uses transaction to prevent double-advance race condition
  Future<void> _advanceToNextQuestion() async {
    if (_room == null || _isAdvancing) return;

    _isAdvancing = true;

    // Stop any playing audio when advancing
    await stopAudio();

    try {
      final currentIndex = _room!.currentQuestionIndex;
      final hasMore = currentIndex < (_room!.puzzles.length - 1);

      // SOLO MODE: Update local state immediately, no Firebase
      if (_room!.roomCode == 'solo') {
        if (hasMore) {
          _room = _room!.copyWith(
            currentQuestionIndex: currentIndex + 1,
            status: TriviaStatus.discussing,
            showOptions: false,
            selectedAnswer: null,
            selectedBy: null,
          );
        } else {
          _room = _room!.copyWith(
            status: TriviaStatus.finished,
            finishedAt: DateTime.now(),
          );
        }

        // Clear local feedback
        _lastAnswerCorrect = null;
        _feedbackMessage = null;
        _isAdvancing = false;
        notifyListeners();
        return;
      }

      // MULTIPLAYER MODE: Use Firebase transaction
      final ref = _roomRef(_room!.roomCode);

      await ref.runTransaction((currentData) {
        if (currentData == null) return Transaction.abort();

        final data = Map<String, dynamic>.from(currentData as Map);

        // Guard: Check if already advanced past this question
        if (data['currentQuestionIndex'] != currentIndex) {
          return Transaction.abort();
        }

        if (hasMore) {
          data['currentQuestionIndex'] = currentIndex + 1;
          data['status'] = TriviaStatus.discussing.name;
          data['showOptions'] = false;
          data['selectedAnswer'] = null;
          data['selectedBy'] = null;
        } else {
          data['status'] = TriviaStatus.finished.name;
          data['finishedAt'] = DateTime.now().millisecondsSinceEpoch;
        }

        return Transaction.success(data);
      });

      // Clear local feedback
      _lastAnswerCorrect = null;
      _feedbackMessage = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to advance: $e');
    } finally {
      _isAdvancing = false;
    }
  }

  // ==================== Firebase Sync ====================

  /// Listens to room updates from Firebase
  void _listenToRoom(String roomCode) {
    _roomSubscription?.cancel();

    _roomSubscription = _roomRef(roomCode).onValue.listen(
      (event) {
        if (event.snapshot.exists) {
          _room = TriviaRoom.fromJson(
            Map<String, dynamic>.from(event.snapshot.value as Map),
          );

          // Update feedback if another player answered
          if (_room!.status == TriviaStatus.revealed &&
              _room!.selectedBy != null &&
              _room!.selectedBy != _currentUserId) {
            final isCorrect = _room!.selectedAnswer == currentPuzzle?.answer;
            _lastAnswerCorrect = isCorrect;
            _feedbackMessage = isCorrect
                ? 'உங்கள் நண்பர் சரியாக பதிலளித்தார்! 🎉'
                : 'தவறான பதில் 😔';
          }

          notifyListeners();
        }
      },
      onError: (error) {
        _setError('Connection error: $error');
      },
    );
  }

  /// Leaves the current room
  Future<void> leaveRoom() async {
    _roomSubscription?.cancel();
    _roomSubscription = null;
    _room = null;
    _lastAnswerCorrect = null;
    _feedbackMessage = null;
    _isProcessingAction = false;
    _isAdvancing = false;
    _lastProcessedQuestionIndex = -1;
    notifyListeners();
  }

  // ==================== Helpers ====================

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(
      6,
      (index) => chars[(random + index * 7) % chars.length],
    ).join();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearFeedback() {
    _feedbackMessage = null;
    _lastAnswerCorrect = null;
    notifyListeners();
  }

  // ==================== Audio Hint ====================

  /// Plays the audio hint for the current puzzle
  Future<void> playAudioHint() async {
    final audioPath = currentPuzzle?.audioAsset;
    if (audioPath == null) {
      debugPrint('[AudioHint] No audio asset for current puzzle');
      return;
    }

    try {
      // If already playing, stop first
      if (_isPlayingAudio) {
        await stopAudio();
        return;
      }

      _isPlayingAudio = true;
      notifyListeners();

      // Extract path after 'assets/' for AssetSource
      // e.g., 'assets/audio/song.mp3' -> 'audio/song.mp3'
      final assetPath = audioPath.startsWith('assets/')
          ? audioPath.substring(7) // Remove 'assets/' prefix
          : audioPath;

      debugPrint('[AudioHint] Playing: $assetPath (original: $audioPath)');

      await _audioPlayer.play(AssetSource(assetPath));

      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlayingAudio = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('[AudioHint] Error playing audio: $e');
      _isPlayingAudio = false;
      _setError('Failed to play audio: $e');
    }
  }

  /// Stops the currently playing audio
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _isPlayingAudio = false;
      notifyListeners();
    } catch (e) {
      _setError('Failed to stop audio: $e');
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
