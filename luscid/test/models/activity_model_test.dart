/// Unit tests for ActivityModel
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:luscid/models/activity_model.dart';

void main() {
  group('ActivityModel', () {
    test('creates activity with required fields', () {
      final activity = ActivityModel(
        id: 'activity-1',
        title: 'Test Activity',
        description: 'Test description',
        icon: '🎯',
        date: DateTime(2024, 1, 15),
      );

      expect(activity.id, 'activity-1');
      expect(activity.title, 'Test Activity');
      expect(activity.description, 'Test description');
      expect(activity.icon, '🎯');
      expect(activity.isCompleted, false);
      expect(activity.completedAt, isNull);
    });

    test('creates completed activity', () {
      final completedTime = DateTime(2024, 1, 15, 14, 30);
      final activity = ActivityModel(
        id: 'activity-2',
        title: 'Completed Activity',
        description: 'Already done',
        icon: '✅',
        date: DateTime(2024, 1, 15),
        isCompleted: true,
        completedAt: completedTime,
      );

      expect(activity.isCompleted, true);
      expect(activity.completedAt, completedTime);
    });

    test('markComplete() returns completed activity', () {
      final activity = ActivityModel(
        id: 'activity-3',
        title: 'To Complete',
        description: 'Need to do this',
        icon: '📋',
        date: DateTime(2024, 1, 15),
      );

      final completed = activity.markComplete();

      expect(completed.isCompleted, true);
      expect(completed.completedAt, isNotNull);
      expect(completed.id, activity.id);
      expect(completed.title, activity.title);
    });

    test('markComplete() on already completed returns same state', () {
      final activity = ActivityModel(
        id: 'activity-4',
        title: 'Already Done',
        description: 'Was done before',
        icon: '✓',
        date: DateTime(2024, 1, 15),
        isCompleted: true,
        completedAt: DateTime(2024, 1, 15, 10, 0),
      );

      final completed = activity.markComplete();

      expect(completed.isCompleted, true);
    });

    test('copyWith() creates new instance with changes', () {
      final original = ActivityModel(
        id: 'activity-5',
        title: 'Original Title',
        description: 'Original description',
        icon: '🔵',
        date: DateTime(2024, 1, 15),
      );

      final copy = original.copyWith(title: 'New Title', isCompleted: true);

      expect(copy.id, original.id);
      expect(copy.title, 'New Title');
      expect(copy.description, original.description);
      expect(copy.isCompleted, true);
    });

    test('toJson() serializes correctly', () {
      final activity = ActivityModel(
        id: 'json-activity',
        title: 'JSON Test',
        description: 'Testing JSON',
        icon: '📝',
        date: DateTime(2024, 1, 15),
        isCompleted: true,
        completedAt: DateTime(2024, 1, 15, 16, 0),
      );

      final json = activity.toJson();

      expect(json['id'], 'json-activity');
      expect(json['title'], 'JSON Test');
      expect(json['description'], 'Testing JSON');
      expect(json['icon'], '📝');
      expect(json['isCompleted'], true);
      expect(json['completedAt'], isNotNull);
    });

    test('fromJson() deserializes correctly', () {
      final json = {
        'id': 'from-json-activity',
        'title': 'From JSON',
        'description': 'Parsed from JSON',
        'icon': '📥',
        'date': DateTime(2024, 1, 15).millisecondsSinceEpoch,
        'isCompleted': false,
      };

      final activity = ActivityModel.fromJson(json);

      expect(activity.id, 'from-json-activity');
      expect(activity.title, 'From JSON');
      expect(activity.isCompleted, false);
    });

    test('fromJson() handles completedAt', () {
      final json = {
        'id': 'completed-json',
        'title': 'Completed From JSON',
        'description': 'Has completedAt',
        'icon': '✅',
        'date': DateTime(2024, 1, 15).millisecondsSinceEpoch,
        'isCompleted': true,
        'completedAt': DateTime(2024, 1, 15, 18, 0).millisecondsSinceEpoch,
      };

      final activity = ActivityModel.fromJson(json);

      expect(activity.isCompleted, true);
      expect(activity.completedAt, isNotNull);
    });
  });

  group('DailyActivities', () {
    test('getDefaultActivities() returns 3 activities', () {
      final activities = DailyActivities.getDefaultActivities(
        DateTime(2024, 1, 15),
      );

      expect(activities.length, 3);
    });

    test('getDefaultActivities() includes play game activity', () {
      final activities = DailyActivities.getDefaultActivities(
        DateTime(2024, 1, 15),
      );

      final gameActivity = activities.firstWhere(
        (a) => a.id == DailyActivities.playGameId,
        orElse: () => throw Exception('Game activity not found'),
      );

      expect(gameActivity.title, contains('Game'));
    });

    test('getDefaultActivities() all activities start incomplete', () {
      final activities = DailyActivities.getDefaultActivities(
        DateTime(2024, 1, 15),
      );

      for (final activity in activities) {
        expect(activity.isCompleted, false);
        expect(activity.completedAt, isNull);
      }
    });

    test('playGameId constant is defined', () {
      expect(DailyActivities.playGameId, isNotEmpty);
    });
  });
}
