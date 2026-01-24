/// Game card model for memory match game
///
/// Represents a single card in the memory game with flip and match states.
library;

class GameCard {
  final String id;
  final String symbol; // Emoji or icon
  final int position;
  final bool isFlipped;
  final bool isMatched;

  const GameCard({
    required this.id,
    required this.symbol,
    required this.position,
    this.isFlipped = false,
    this.isMatched = false,
  });

  /// Creates a copy with updated fields
  GameCard copyWith({
    String? id,
    String? symbol,
    int? position,
    bool? isFlipped,
    bool? isMatched,
  }) {
    return GameCard(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      position: position ?? this.position,
      isFlipped: isFlipped ?? this.isFlipped,
      isMatched: isMatched ?? this.isMatched,
    );
  }

  /// Serializes to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'position': position,
      'isFlipped': isFlipped,
      'isMatched': isMatched,
    };
  }

  /// Deserializes from JSON
  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      id: json['id'] as String,
      symbol: json['symbol'] as String,
      position: json['position'] as int,
      isFlipped: json['isFlipped'] as bool? ?? false,
      isMatched: json['isMatched'] as bool? ?? false,
    );
  }

  /// Flips the card (toggles isFlipped state)
  GameCard flip() {
    return copyWith(isFlipped: !isFlipped);
  }

  /// Marks the card as matched
  GameCard match() {
    return copyWith(isMatched: true, isFlipped: true);
  }

  /// Resets the card to face-down (if not matched)
  GameCard reset() {
    if (isMatched) return this;
    return copyWith(isFlipped: false);
  }

  /// Checks if this card matches another card
  bool matches(GameCard other) {
    return symbol == other.symbol && id != other.id;
  }

  @override
  String toString() {
    return 'GameCard(id: $id, symbol: $symbol, position: $position, flipped: $isFlipped, matched: $isMatched)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameCard && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
