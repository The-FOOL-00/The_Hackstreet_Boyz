/// User model for authentication and profile data
///
/// Supports PIN-based authentication with role selection.
library;

class UserModel {
  final String uid;
  final String pin; // Stored as hash in production
  final UserRole role;
  final DateTime createdAt;
  final DateTime lastActive;
  final String? displayName;

  const UserModel({
    required this.uid,
    required this.pin,
    required this.role,
    required this.createdAt,
    required this.lastActive,
    this.displayName,
  });

  /// Creates a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? pin,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastActive,
    String? displayName,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      pin: pin ?? this.pin,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      displayName: displayName ?? this.displayName,
    );
  }

  /// Serializes to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'pin': pin,
      'role': role.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastActive': lastActive.millisecondsSinceEpoch,
      'displayName': displayName,
    };
  }

  /// Deserializes from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String,
      pin: json['pin'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.senior,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      lastActive: DateTime.fromMillisecondsSinceEpoch(
        json['lastActive'] as int,
      ),
      displayName: json['displayName'] as String?,
    );
  }

  /// Creates a new user with defaults
  factory UserModel.create({
    required String uid,
    required String pin,
    required UserRole role,
    String? displayName,
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      pin: pin,
      role: role,
      createdAt: now,
      lastActive: now,
      displayName: displayName,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, role: $role, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

/// User roles in the app
enum UserRole {
  senior, // Primary user - elderly person
  caregiver, // Family member or caregiver
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.senior:
        return 'Senior User';
      case UserRole.caregiver:
        return 'Family/Caregiver';
    }
  }

  String get description {
    switch (this) {
      case UserRole.senior:
        return 'I want to play and keep my mind active';
      case UserRole.caregiver:
        return 'I want to play with or support a loved one';
    }
  }

  String get emoji {
    switch (this) {
      case UserRole.senior:
        return '👴';
      case UserRole.caregiver:
        return '👨‍👩‍👧';
    }
  }
}
