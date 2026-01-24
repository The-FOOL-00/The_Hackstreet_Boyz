/// Helper utilities for the app
///
/// Common functions used across the application.
library;

import 'dart:math';

class Helpers {
  // Prevent instantiation
  Helpers._();

  static final Random _random = Random();

  /// Generates a random 4-digit room code
  static String generateRoomCode() {
    return (_random.nextInt(9000) + 1000).toString();
  }

  /// Shuffles a list using Fisher-Yates algorithm
  static List<T> shuffleList<T>(List<T> list) {
    final shuffled = List<T>.from(list);
    for (var i = shuffled.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = temp;
    }
    return shuffled;
  }

  /// Gets a random encouraging message
  static String getEncouragingMessage() {
    const messages = [
      'Great job! 🌟',
      'Well done! 👏',
      'Excellent! ✨',
      'Wonderful! 🎉',
      'Amazing! 💫',
      'Keep it up! 💪',
      'You\'re doing great! 😊',
      'Fantastic! 🌈',
      'Brilliant! 🏆',
      'Superb! ⭐',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Gets a match found message
  static String getMatchMessage() {
    const messages = [
      'Nice match! 🎯',
      'You found a pair! 🎉',
      'Great memory! 🧠',
      'Perfect match! ✨',
      'Well spotted! 👀',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Gets a game complete message
  static String getGameCompleteMessage() {
    const messages = [
      'Congratulations! You completed the game! 🎉',
      'Amazing work! All pairs found! 🏆',
      'Well done! Your memory is great! 🧠',
      'Wonderful! You did it! 🌟',
      'Fantastic job! Game complete! ✨',
    ];
    return messages[_random.nextInt(messages.length)];
  }

  /// Formats a date to a friendly string
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Gets time of day greeting
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Delays execution (useful for animations)
  static Future<void> delay([int milliseconds = 500]) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  /// Formats a duration to a readable string (e.g., "2:30")
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '0:${seconds.toString().padLeft(2, '0')}';
  }

  /// Alias for getEncouragingMessage for backward compatibility
  static String getEncouragementMessage() => getEncouragingMessage();
}
