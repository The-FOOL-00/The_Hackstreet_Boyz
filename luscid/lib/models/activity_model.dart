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
  final DateTime? scheduledTime; // Optional scheduled time (e.g., medicine at 2 PM)
  final bool isCustom; // User-added via voice/text
  final int? reminderMinutes; // Minutes after scheduled time to remind

  const ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.isCompleted = false,
    this.completedAt,
    required this.date,
    this.scheduledTime,
    this.isCustom = false,
    this.reminderMinutes,
  });

  /// Check if this activity is overdue
  bool get isOverdue {
    if (isCompleted || scheduledTime == null) return false;
    final now = DateTime.now();
    final deadline = scheduledTime!.add(Duration(minutes: reminderMinutes ?? 60));
    return now.isAfter(deadline);
  }

  /// Check if reminder should be sent
  bool get shouldRemind {
    if (isCompleted || scheduledTime == null) return false;
    final now = DateTime.now();
    return now.isAfter(scheduledTime!) && !isCompleted;
  }

  /// Get time remaining until scheduled (or overdue duration)
  String get timeStatus {
    if (scheduledTime == null) return '';
    final now = DateTime.now();
    final diff = scheduledTime!.difference(now);
    if (diff.isNegative) {
      final overdue = now.difference(scheduledTime!);
      if (overdue.inHours > 0) {
        return '${overdue.inHours}h overdue';
      }
      return '${overdue.inMinutes}m overdue';
    }
    if (diff.inHours > 0) {
      return 'in ${diff.inHours}h';
    }
    return 'in ${diff.inMinutes}m';
  }

  /// Creates a copy with updated fields
  ActivityModel copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? date,
    DateTime? scheduledTime,
    bool? isCustom,
    int? reminderMinutes,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      date: date ?? this.date,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isCustom: isCustom ?? this.isCustom,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
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
      'scheduledTime': scheduledTime?.millisecondsSinceEpoch,
      'isCustom': isCustom,
      'reminderMinutes': reminderMinutes,
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
      scheduledTime: json['scheduledTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['scheduledTime'] as int)
          : null,
      isCustom: json['isCustom'] as bool? ?? false,
      reminderMinutes: json['reminderMinutes'] as int?,
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
    
    // Create 2 PM scheduled time for medicine (test case)
    final medicineTime = DateTime(date.year, date.month, date.day, 14, 0); // 2 PM
    
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
      // Medicine reminder test case - scheduled at 2 PM
      ActivityModel(
        id: 'take_medicine',
        title: 'Take Afternoon Medicine',
        description: 'Take your prescribed medication',
        icon: '💊',
        date: dateOnly,
        scheduledTime: medicineTime,
        reminderMinutes: 60, // Remind after 1 hour (3 PM)
      ),
    ];
  }

  /// Activity IDs for tracking
  static const String playGameId = 'play_game';
  static const String drinkWaterId = 'drink_water';
  static const String takeWalkId = 'take_walk';
  static const String takeMedicineId = 'take_medicine';
}
