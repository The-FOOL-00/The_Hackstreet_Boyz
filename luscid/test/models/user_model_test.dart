/// Unit tests for UserModel
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:luscid/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('create() generates valid user with all fields', () {
      final user = UserModel.create(
        uid: 'test-uid-123',
        pin: '1234',
        role: UserRole.senior,
        displayName: 'Test User',
      );

      expect(user.uid, 'test-uid-123');
      expect(user.pin, '1234');
      expect(user.role, UserRole.senior);
      expect(user.displayName, 'Test User');
      expect(user.createdAt, isNotNull);
      expect(user.lastActive, isNotNull);
    });

    test('create() works without displayName', () {
      final user = UserModel.create(
        uid: 'test-uid-456',
        pin: '5678',
        role: UserRole.caregiver,
      );

      expect(user.uid, 'test-uid-456');
      expect(user.displayName, isNull);
      expect(user.role, UserRole.caregiver);
    });

    test('copyWith() creates new instance with updated fields', () {
      final original = UserModel.create(
        uid: 'test-uid',
        pin: '1234',
        role: UserRole.senior,
      );

      final updated = original.copyWith(pin: '9999', displayName: 'New Name');

      expect(updated.uid, original.uid); // unchanged
      expect(updated.pin, '9999'); // changed
      expect(updated.displayName, 'New Name'); // changed
      expect(updated.role, original.role); // unchanged
    });

    test('copyWith() preserves original when no changes', () {
      final original = UserModel.create(
        uid: 'test-uid',
        pin: '1234',
        role: UserRole.senior,
        displayName: 'Original',
      );

      final copy = original.copyWith();

      expect(copy.uid, original.uid);
      expect(copy.pin, original.pin);
      expect(copy.role, original.role);
      expect(copy.displayName, original.displayName);
    });

    test('toJson() serializes correctly', () {
      final user = UserModel(
        uid: 'json-test-uid',
        pin: '1111',
        role: UserRole.caregiver,
        createdAt: DateTime(2024, 1, 1, 12, 0),
        lastActive: DateTime(2024, 1, 2, 12, 0),
        displayName: 'JSON User',
      );

      final json = user.toJson();

      expect(json['uid'], 'json-test-uid');
      expect(json['pin'], '1111');
      expect(json['role'], 'caregiver');
      expect(json['displayName'], 'JSON User');
      expect(json['createdAt'], isNotNull);
      expect(json['lastActive'], isNotNull);
    });

    test('fromJson() deserializes correctly', () {
      final json = {
        'uid': 'from-json-uid',
        'pin': '2222',
        'role': 'senior',
        'createdAt': DateTime(2024, 1, 1).millisecondsSinceEpoch,
        'lastActive': DateTime(2024, 1, 2).millisecondsSinceEpoch,
        'displayName': 'From JSON',
      };

      final user = UserModel.fromJson(json);

      expect(user.uid, 'from-json-uid');
      expect(user.pin, '2222');
      expect(user.role, UserRole.senior);
      expect(user.displayName, 'From JSON');
    });

    test('fromJson() handles null displayName', () {
      final json = {
        'uid': 'uid-null-name',
        'pin': '3333',
        'role': 'senior',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'lastActive': DateTime.now().millisecondsSinceEpoch,
      };

      final user = UserModel.fromJson(json);

      expect(user.displayName, isNull);
    });

    test('toJson() and fromJson() are reversible', () {
      final original = UserModel.create(
        uid: 'round-trip-uid',
        pin: '4444',
        role: UserRole.senior,
        displayName: 'Round Trip',
      );

      final json = original.toJson();
      final restored = UserModel.fromJson(json);

      expect(restored.uid, original.uid);
      expect(restored.pin, original.pin);
      expect(restored.role, original.role);
      expect(restored.displayName, original.displayName);
    });
  });

  group('UserRole', () {
    test('parses senior role correctly', () {
      expect(UserRole.values.byName('senior'), UserRole.senior);
    });

    test('parses caregiver role correctly', () {
      expect(UserRole.values.byName('caregiver'), UserRole.caregiver);
    });
  });
}
