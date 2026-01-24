/// Trivia model for CineRecall movie puzzle game
///
/// Manages movie puzzle data for the multiplayer trivia experience.
library;

/// Type of hint provided for a movie puzzle
enum HintType { lyric, dialogue, audio }

/// Represents a movie puzzle with rebus-style images
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

  /// Creates a copy with updated fields
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

  /// Deserializes from JSON
  factory MoviePuzzle.fromJson(Map<String, dynamic> json) {
    return MoviePuzzle(
      id: json['id'] as String,
      category: json['category'] as String,
      imageAsset: json['imageAsset'] as String,
      answer: json['answer'] as String,
      options: List<String>.from(json['options'] as List),
      hint: json['hint'] as String,
      hintType: HintType.values.firstWhere(
        (e) => e.name == json['hintType'],
        orElse: () => HintType.dialogue,
      ),
      audioAsset: json['audioAsset'] as String?,
      isRevealed: json['isRevealed'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'MoviePuzzle(id: $id, category: $category, answer: $answer)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoviePuzzle && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Trivia game room state for multiplayer synchronization
class TriviaRoom {
  final String roomCode;
  final String hostId;
  final String? guestId;
  final int currentQuestionIndex;
  final Map<String, int> scores;
  final TriviaStatus status;
  final bool showOptions;
  final String? selectedAnswer;
  final String? selectedBy;
  final List<MoviePuzzle> puzzles;
  final DateTime createdAt;
  final DateTime? finishedAt;

  const TriviaRoom({
    required this.roomCode,
    required this.hostId,
    this.guestId,
    this.currentQuestionIndex = 0,
    required this.scores,
    this.status = TriviaStatus.waiting,
    this.showOptions = false,
    this.selectedAnswer,
    this.selectedBy,
    required this.puzzles,
    required this.createdAt,
    this.finishedAt,
  });

  /// Check if both players are in the room
  bool get isRoomFull => guestId != null;

  /// Check if the game is finished
  bool get isFinished => status == TriviaStatus.finished;

  /// Get current puzzle
  MoviePuzzle? get currentPuzzle {
    if (currentQuestionIndex < puzzles.length) {
      return puzzles[currentQuestionIndex];
    }
    return null;
  }

  /// Check if there are more puzzles
  bool get hasMorePuzzles => currentQuestionIndex < puzzles.length - 1;

  /// Creates a copy with updated fields
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
      selectedAnswer: selectedAnswer,
      selectedBy: selectedBy,
      puzzles: puzzles ?? this.puzzles,
      createdAt: createdAt ?? this.createdAt,
      finishedAt: finishedAt ?? this.finishedAt,
    );
  }

  /// Serializes to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'roomCode': roomCode,
      'hostId': hostId,
      'guestId': guestId,
      'currentQuestionIndex': currentQuestionIndex,
      'scores': scores,
      'status': status.name,
      'showOptions': showOptions,
      'selectedAnswer': selectedAnswer,
      'selectedBy': selectedBy,
      'puzzles': puzzles.map((p) => p.toJson()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'finishedAt': finishedAt?.millisecondsSinceEpoch,
    };
  }

  /// Deserializes from JSON
  factory TriviaRoom.fromJson(Map<String, dynamic> json) {
    return TriviaRoom(
      roomCode: json['roomCode'] as String,
      hostId: json['hostId'] as String,
      guestId: json['guestId'] as String?,
      currentQuestionIndex: json['currentQuestionIndex'] as int? ?? 0,
      scores: Map<String, int>.from(json['scores'] as Map? ?? {}),
      status: TriviaStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TriviaStatus.waiting,
      ),
      showOptions: json['showOptions'] as bool? ?? false,
      selectedAnswer: json['selectedAnswer'] as String?,
      selectedBy: json['selectedBy'] as String?,
      puzzles:
          (json['puzzles'] as List?)
              ?.map(
                (p) =>
                    MoviePuzzle.fromJson(Map<String, dynamic>.from(p as Map)),
              )
              .toList() ??
          [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      finishedAt: json['finishedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['finishedAt'] as int)
          : null,
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
      createdAt: DateTime.now(),
    );
  }
}

/// Status of the trivia game
enum TriviaStatus {
  waiting, // Waiting for players
  discussing, // Players are discussing the puzzle
  answering, // Options are shown, waiting for selection
  revealed, // Answer has been revealed
  finished, // Game is complete
}
