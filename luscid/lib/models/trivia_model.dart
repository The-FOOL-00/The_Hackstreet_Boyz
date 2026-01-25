/// Trivia model for CineRecall movie puzzle game
library;

// ==================== ENUMS (Critical!) ====================

/// Type of hint provided for a movie puzzle
enum HintType { lyric, dialogue, audio, text }

/// Status of the trivia game
enum TriviaStatus {
  waiting,    // Waiting for players
  discussing, // Players are discussing the puzzle
  answering,  // Options are shown, waiting for selection
  revealed,   // Answer has been revealed
  finished,   // Game is complete
}

// ==================== PUZZLE CLASS ====================

class MoviePuzzle {
  final String id;
  final String category;
  final String imageAsset;
  final String answer;
  final List<String> options;
  final String hint;
  final HintType hintType;
  final String? audioAsset;
  bool isRevealed;

  MoviePuzzle({
    required this.id,
    required this.category,
    required this.imageAsset,
    required this.answer,
    required this.options,
    required this.hint,
    required this.hintType,
    this.audioAsset,
    this.isRevealed = false,
  });

  /// Serializes to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'imageAsset': imageAsset,
      'answer': answer,
      'options': options,
      'hint': hint,
      'hintType': hintType.name,
      'audioAsset': audioAsset,
      'isRevealed': isRevealed,
    };
  }

  /// Alias for toJson (Strict Map return)
  Map<String, dynamic> toMap() => toJson();

  /// Deserializes from JSON
  factory MoviePuzzle.fromJson(Map<dynamic, dynamic> json) {
    return MoviePuzzle(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      imageAsset: json['imageAsset']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hint: json['hint']?.toString() ?? '',
      hintType: HintType.values.firstWhere(
        (e) => e.name == json['hintType'],
        orElse: () => HintType.dialogue,
      ),
      audioAsset: json['audioAsset']?.toString(),
      isRevealed: json['isRevealed'] == true,
    );
  }
  
  MoviePuzzle copyWith({
    String? id,
    String? category,
    String? imageAsset,
    String? answer,
    List<String>? options,
    String? hint,
    HintType? hintType,
    String? audioAsset,
    bool? isRevealed,
  }) {
    return MoviePuzzle(
      id: id ?? this.id,
      category: category ?? this.category,
      imageAsset: imageAsset ?? this.imageAsset,
      answer: answer ?? this.answer,
      options: options ?? List.from(this.options),
      hint: hint ?? this.hint,
      hintType: hintType ?? this.hintType,
      audioAsset: audioAsset ?? this.audioAsset,
      isRevealed: isRevealed ?? this.isRevealed,
    );
  }
}

// ==================== ROOM CLASS ====================

class TriviaRoom {
  final String roomCode;
  final String hostId;
  final String? guestId;
  final int currentQuestionIndex;
  final Map<String, int> scores;
  final TriviaStatus status; // Uses the Enum defined above
  final bool showOptions;
  final String? selectedAnswer;
  final String? selectedBy;
  final List<MoviePuzzle> puzzles;
  final DateTime createdAt;
  final DateTime? finishedAt;

  TriviaRoom({
    required this.roomCode,
    required this.hostId,
    this.guestId,
    this.currentQuestionIndex = 0,
    required this.scores,
    required this.status,
    this.showOptions = false,
    this.selectedAnswer,
    this.selectedBy,
    required this.puzzles,
    required this.createdAt,
    this.finishedAt,
  });

  bool get isRoomFull => guestId != null;
  bool get isFinished => status == TriviaStatus.finished;

  MoviePuzzle? get currentPuzzle {
    if (currentQuestionIndex < puzzles.length) {
      return puzzles[currentQuestionIndex];
    }
    return null;
  }
  
  bool get hasMorePuzzles => currentQuestionIndex < puzzles.length - 1;

  /// Serializes to JSON for Firebase (Strict Map)
  Map<String, dynamic> toJson() {
    return {
      'roomCode': roomCode,
      'hostId': hostId,
      'guestId': guestId,
      'currentQuestionIndex': currentQuestionIndex,
      'scores': scores,
      'status': status.name, // Saves enum as string (e.g., "waiting")
      'showOptions': showOptions,
      'selectedAnswer': selectedAnswer,
      'selectedBy': selectedBy,
      'puzzles': puzzles.map((p) => p.toJson()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'finishedAt': finishedAt?.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  /// Deserializes from JSON
  factory TriviaRoom.fromJson(Map<dynamic, dynamic> json) {
    // Parse puzzles safely (Handles both List and Map formats from Firebase)
    List<MoviePuzzle> parsedPuzzles = [];
    final puzzlesData = json['puzzles'];
    
    if (puzzlesData is List) {
      parsedPuzzles = puzzlesData
          .map((p) => MoviePuzzle.fromJson(Map<dynamic, dynamic>.from(p)))
          .toList();
    } else if (puzzlesData is Map) {
      parsedPuzzles = puzzlesData.values
          .map((p) => MoviePuzzle.fromJson(Map<dynamic, dynamic>.from(p)))
          .toList();
    }

    return TriviaRoom(
      roomCode: json['roomCode']?.toString() ?? '',
      hostId: json['hostId']?.toString() ?? '',
      guestId: json['guestId']?.toString(),
      currentQuestionIndex: (json['currentQuestionIndex'] as num?)?.toInt() ?? 0,
      scores: Map<String, int>.from(json['scores'] ?? {}),
      
      // CRITICAL: Parses String back to TriviaStatus Enum
      status: TriviaStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TriviaStatus.waiting,
      ),
      
      showOptions: json['showOptions'] == true,
      selectedAnswer: json['selectedAnswer']?.toString(),
      selectedBy: json['selectedBy']?.toString(),
      puzzles: parsedPuzzles,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          (json['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
      finishedAt: json['finishedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['finishedAt'] as num).toInt())
          : null,
    );
  }
  
  TriviaRoom copyWith({
    String? roomCode,
    String? hostId,
    String? guestId,
    int? currentQuestionIndex,
    Map<String, int>? scores,
    TriviaStatus? status,
    bool? showOptions,
    String? selectedAnswer,
    String? selectedBy,
    List<MoviePuzzle>? puzzles,
    DateTime? createdAt,
    DateTime? finishedAt,
  }) {
    return TriviaRoom(
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      guestId: guestId ?? this.guestId,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      scores: scores ?? Map.from(this.scores),
      status: status ?? this.status,
      showOptions: showOptions ?? this.showOptions,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      selectedBy: selectedBy ?? this.selectedBy,
      puzzles: puzzles ?? this.puzzles,
      createdAt: createdAt ?? this.createdAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }
  
  /// Creates a new room
  factory TriviaRoom.create({
    required String roomCode,
    required String hostId,
    required List<MoviePuzzle> puzzles,
  }) {
    return TriviaRoom(
      roomCode: roomCode,
      hostId: hostId,
      scores: {hostId: 0},
      puzzles: puzzles,
      status: TriviaStatus.waiting,
      createdAt: DateTime.now(),
    );
  }
}