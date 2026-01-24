/// Activity model for daily checklist
///
/// Tracks daily activities for elderly wellness.
library;

class ActivityModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime date; // The date this activity is for

  const ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isCompleted = false,
    this.completedAt,
    required this.date,
  });

  /// Creates a copy with updated fields
  ActivityModel copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? date,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      date: date ?? this.date,
    );
  }

  /// Marks the activity as completed
  ActivityModel markComplete() {
    return copyWith(isCompleted: true, completedAt: DateTime.now());
  }

  /// Resets the activity (for new day)
  ActivityModel reset(DateTime newDate) {
    return copyWith(isCompleted: false, completedAt: null, date: newDate);
  }

  /// Serializes to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'date': date.millisecondsSinceEpoch,
    };
  }

  /// Deserializes from JSON
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int)
          : null,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
    );
  }

  @override
  String toString() {
    return 'ActivityModel(id: $id, title: $title, completed: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityModel && other.id == id && other.date == date;
  }

  @override
  int get hashCode => Object.hash(id, date);
}

/// Default daily activities for elderly users
class DailyActivities {
  // Prevent instantiation
  DailyActivities._();

  /// Gets the default activities for a given date
  static List<ActivityModel> getDefaultActivities(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return [
      ActivityModel(
        id: 'play_game',
        title: 'Play a Memory Game',
        description: 'Exercise your brain with one memory game today',
        icon: '🧠',
        date: dateOnly,
      ),
      ActivityModel(
        id: 'drink_water',
        title: 'Drink Water',
        description: 'Stay hydrated - have a glass of water',
        icon: '💧',
        date: dateOnly,
      ),
      ActivityModel(
        id: 'take_walk',
        title: 'Take a Short Walk',
        description: 'Walk for at least 5 minutes',
        icon: '🚶',
        date: dateOnly,
      ),
    ];
  }

  /// Activity IDs for tracking
  static const String playGameId = 'play_game';
  static const String drinkWaterId = 'drink_water';
  static const String takeWalkId = 'take_walk';
}
