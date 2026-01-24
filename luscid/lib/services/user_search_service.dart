/// User Search Service
///
/// Handles searching for users by phone number or display name.
library;

import 'package:firebase_database/firebase_database.dart';

/// User search result model
class UserSearchResult {
  final String uid;
  final String displayName;
  final String phone;
  final String? photoUrl;
  final bool isOnline;

  const UserSearchResult({
    required this.uid,
    required this.displayName,
    required this.phone,
    this.photoUrl,
    this.isOnline = false,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String? ?? 'User',
      phone: json['phone'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      isOnline: json['status'] == 'online',
    );
  }
}

class UserSearchService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Reference to users
  DatabaseReference get _usersRef => _database.ref('users');

  /// Reference to phone index
  DatabaseReference get _phoneIndexRef => _database.ref('phoneIndex');

  /// Normalize phone number for consistent matching
  String _normalizePhone(String phone) {
    String normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Add country code if missing (default to +91 India)
    if (!normalized.startsWith('+')) {
      if (normalized.length == 10) {
        normalized = '+91$normalized';
      } else if (normalized.startsWith('91') && normalized.length == 12) {
        normalized = '+$normalized';
      }
    }

    return normalized;
  }

  /// Search users by phone number
  Future<UserSearchResult?> searchByPhone(
    String phone, {
    String? excludeUid,
  }) async {
    final normalizedPhone = _normalizePhone(phone);

    // First check phone index
    final phoneKey = normalizedPhone.replaceAll('+', '');
    final indexSnapshot = await _phoneIndexRef.child(phoneKey).get();

    if (indexSnapshot.exists) {
      final userId = indexSnapshot.value as String;
      if (userId != excludeUid) {
        return await _getUserById(userId);
      }
    }

    return null;
  }

  /// Search users by display name (partial match)
  Future<List<UserSearchResult>> searchByName(
    String query, {
    String? excludeUid,
    int limit = 20,
  }) async {
    if (query.isEmpty) return [];

    final results = <UserSearchResult>[];
    final queryLower = query.toLowerCase();

    // Get all users and filter by name
    // Note: In production, use Algolia or Firebase extensions for better search
    final snapshot = await _usersRef.limitToFirst(100).get();

    if (!snapshot.exists) return [];

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    data.forEach((uid, userData) {
      if (uid == excludeUid) return;

      final user = Map<String, dynamic>.from(userData as Map);
      final displayName = (user['displayName'] as String? ?? '').toLowerCase();
      final phone = user['phone'] as String? ?? '';

      // Check if name or phone contains query
      if (displayName.contains(queryLower) || phone.contains(query)) {
        results.add(
          UserSearchResult(
            uid: uid,
            displayName: user['displayName'] as String? ?? 'User',
            phone: phone,
            photoUrl: user['photoUrl'] as String?,
            isOnline: user['status'] == 'online',
          ),
        );
      }
    });

    // Sort by online status, then name
    results.sort((a, b) {
      if (a.isOnline && !b.isOnline) return -1;
      if (!a.isOnline && b.isOnline) return 1;
      return a.displayName.compareTo(b.displayName);
    });

    return results.take(limit).toList();
  }

  /// Get user by ID
  Future<UserSearchResult?> _getUserById(String uid) async {
    final snapshot = await _usersRef.child(uid).get();
    if (!snapshot.exists) return null;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    data['uid'] = uid;
    return UserSearchResult.fromJson(data);
  }

  /// Get user profile by ID
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final snapshot = await _usersRef.child(uid).get();
    if (!snapshot.exists) return null;

    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  /// Update user online status
  Future<void> setUserOnline(String uid) async {
    await _usersRef.child(uid).update({
      'status': 'online',
      'lastActive': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Update user offline status
  Future<void> setUserOffline(String uid) async {
    await _usersRef.child(uid).update({
      'status': 'offline',
      'lastActive': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Register phone number in index
  Future<void> registerPhoneNumber(String phone, String uid) async {
    final normalizedPhone = _normalizePhone(phone);
    final phoneKey = normalizedPhone.replaceAll('+', '');

    await _phoneIndexRef.child(phoneKey).set(uid);
  }
}
