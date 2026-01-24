/// Game service for memory match game logic
///
/// Handles card generation, shuffling, match detection, and game state.
library;

import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import '../models/game_card_model.dart';
import '../core/constants/game_icons.dart';
import '../core/utils/helpers.dart';

class GameService {
  final Uuid _uuid = const Uuid();

  /// Generates cards for a given difficulty
  List<GameCard> generateCards(GameDifficulty difficulty) {
    final symbols = GameIcons.getSymbolsForDifficulty(difficulty);
    final cards = <GameCard>[];

    // Create pairs of cards
    for (var i = 0; i < symbols.length; i++) {
      // First card of pair
      cards.add(
        GameCard(id: _uuid.v4(), symbol: symbols[i], position: cards.length),
      );
      // Second card of pair
      cards.add(
        GameCard(id: _uuid.v4(), symbol: symbols[i], position: cards.length),
      );
    }

    // Shuffle the cards
    return shuffleCards(cards);
  }

  /// Shuffles cards using Fisher-Yates algorithm
  List<GameCard> shuffleCards(List<GameCard> cards) {
    final shuffled = Helpers.shuffleList(cards);
    // Update positions after shuffle
    return shuffled.asMap().entries.map((entry) {
      return entry.value.copyWith(position: entry.key);
    }).toList();
  }

  /// Flips a card at the given index
  List<GameCard> flipCard(List<GameCard> cards, int index) {
    if (index < 0 || index >= cards.length) return cards;
    if (cards[index].isMatched) return cards; // Can't flip matched cards

    final newCards = List<GameCard>.from(cards);
    newCards[index] = newCards[index].flip();
    return newCards;
  }

  /// Gets currently flipped (but not matched) cards
  List<GameCard> getFlippedCards(List<GameCard> cards) {
    return cards.where((c) => c.isFlipped && !c.isMatched).toList();
  }

  /// Checks if two cards match
  bool checkMatch(GameCard card1, GameCard card2) {
    return card1.symbol == card2.symbol && card1.id != card2.id;
  }

  /// Marks two cards as matched
  List<GameCard> markAsMatched(
    List<GameCard> cards,
    GameCard card1,
    GameCard card2,
  ) {
    final newCards = List<GameCard>.from(cards);

    final index1 = newCards.indexWhere((c) => c.id == card1.id);
    final index2 = newCards.indexWhere((c) => c.id == card2.id);

    if (index1 != -1) {
      newCards[index1] = newCards[index1].match();
    }
    if (index2 != -1) {
      newCards[index2] = newCards[index2].match();
    }

    return newCards;
  }

  /// Resets flipped cards (that are not matched)
  List<GameCard> resetFlippedCards(List<GameCard> cards) {
    return cards.map((c) => c.reset()).toList();
  }

  /// Checks if all cards are matched
  bool isGameComplete(List<GameCard> cards) {
    if (cards.isEmpty) return false;
    return cards.every((c) => c.isMatched);
  }

  /// Gets the number of matched pairs
  int getMatchedPairs(List<GameCard> cards) {
    return cards.where((c) => c.isMatched).length ~/ 2;
  }

  /// Gets the total number of pairs
  int getTotalPairs(List<GameCard> cards) {
    return cards.length ~/ 2;
  }

  /// Gets the grid size for a list of cards
  int getGridSize(List<GameCard> cards) {
    final total = cards.length;
    if (total == 4) return 2;
    if (total == 16) return 4;
    if (total == 36) return 6;
    // Default calculation
    return math.sqrt(total.toDouble()).ceil();
  }

  /// Gets difficulty from card count
  GameDifficulty getDifficultyFromCards(List<GameCard> cards) {
    final total = cards.length;
    if (total <= 4) return GameDifficulty.easy;
    if (total <= 16) return GameDifficulty.medium;
    return GameDifficulty.hard;
  }

  /// Validates a game state
  bool validateGameState(List<GameCard> cards) {
    if (cards.isEmpty) return false;
    if (cards.length % 2 != 0) return false; // Must have pairs

    // Check all cards have valid data
    for (final card in cards) {
      if (card.id.isEmpty || card.symbol.isEmpty) return false;
    }

    return true;
  }
}
