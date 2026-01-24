/// Game icons and symbols for memory cards
///
/// High-contrast emojis that are easily distinguishable for elderly users.
/// Categories: fruits, animals, shapes, objects
library;

class GameIcons {
  // Prevent instantiation
  GameIcons._();

  // Fruit symbols (Easy to recognize)
  static const List<String> fruits = [
    '🍎', // Apple
    '🍊', // Orange
    '🍋', // Lemon
    '🍇', // Grapes
    '🍓', // Strawberry
    '🍌', // Banana
    '🍉', // Watermelon
    '🍒', // Cherry
    '🥭', // Mango
    '🍑', // Peach
  ];

  // Animal symbols
  static const List<String> animals = [
    '🐶', // Dog
    '🐱', // Cat
    '🐦', // Bird
    '🐰', // Rabbit
    '🐻', // Bear
    '🦋', // Butterfly
    '🐢', // Turtle
    '🐠', // Fish
    '🦁', // Lion
    '🐘', // Elephant
  ];

  // Shape/Object symbols
  static const List<String> objects = [
    '⭐', // Star
    '❤️', // Heart
    '🌙', // Moon
    '☀️', // Sun
    '🌸', // Flower
    '🏠', // House
    '🚗', // Car
    '✈️', // Airplane
    '⚽', // Ball
    '🎵', // Music
  ];

  // Combined list for larger grids
  static List<String> get allSymbols => [...fruits, ...animals, ...objects];

  /// Get symbols for a specific difficulty level
  /// Easy: 2 pairs (4 cards), Medium: 8 pairs (16 cards), Hard: 18 pairs (36 cards)
  static List<String> getSymbolsForDifficulty(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return fruits.take(2).toList();
      case GameDifficulty.medium:
        return fruits.take(8).toList();
      case GameDifficulty.hard:
        return allSymbols.take(18).toList();
    }
  }

  /// Get grid size for difficulty
  static int getGridSize(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return 2; // 2x2 grid
      case GameDifficulty.medium:
        return 4; // 4x4 grid
      case GameDifficulty.hard:
        return 6; // 6x6 grid
    }
  }

  /// Get total cards for difficulty
  static int getTotalCards(GameDifficulty difficulty) {
    final size = getGridSize(difficulty);
    return size * size;
  }

  /// Get number of pairs for difficulty
  static int getPairs(GameDifficulty difficulty) {
    return getTotalCards(difficulty) ~/ 2;
  }

  /// Get random symbols from all available symbols
  static List<String> getRandomSymbols(int count) {
    final all = List<String>.from(allSymbols);
    all.shuffle();
    return all.take(count).toList();
  }
}

/// Game difficulty levels
enum GameDifficulty {
  easy, // 2x2 grid (4 cards, 2 pairs)
  medium, // 4x4 grid (16 cards, 8 pairs)
  hard, // 6x6 grid (36 cards, 18 pairs)
}

extension GameDifficultyExtension on GameDifficulty {
  String get displayName {
    switch (this) {
      case GameDifficulty.easy:
        return 'Easy';
      case GameDifficulty.medium:
        return 'Medium';
      case GameDifficulty.hard:
        return 'Hard';
    }
  }

  String get description {
    switch (this) {
      case GameDifficulty.easy:
        return '2×2 Grid • 2 Pairs';
      case GameDifficulty.medium:
        return '4×4 Grid • 8 Pairs';
      case GameDifficulty.hard:
        return '6×6 Grid • 18 Pairs';
    }
  }

  String get emoji {
    switch (this) {
      case GameDifficulty.easy:
        return '😊';
      case GameDifficulty.medium:
        return '🤔';
      case GameDifficulty.hard:
        return '💪';
    }
  }
}
