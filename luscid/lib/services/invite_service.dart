/// Game Invite Service
///
/// Handles sending, receiving, and managing game invitations.
library;

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

/// Game invite status
enum InviteStatus { pending, accepted, declined, expired, cancelled }

/// Game invite model
class GameInvite {
  final String inviteId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String gameType; // 'memory', 'shopping_list', 'cinema_connect'
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String? roomCode; // Set when accepted
  final Map<String, dynamic>? gameConfig;

  const GameInvite({
    required this.inviteId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.gameType,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    this.roomCode,
    this.gameConfig,
  });

  bool get isPending => status == InviteStatus.pending;
  bool get isAccepted => status == InviteStatus.accepted;
  bool get isDeclined => status == InviteStatus.declined;
  bool get isExpired => status == InviteStatus.expired;

  factory GameInvite.fromJson(Map<String, dynamic> json) {
    return GameInvite(
      inviteId: json['inviteId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String? ?? 'Player',
      receiverId: json['receiverId'] as String,
      gameType: json['gameType'] as String? ?? 'memory',
      status: InviteStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InviteStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      respondedAt: json['respondedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['respondedAt'] as int)
          : null,
      roomCode: json['roomCode'] as String?,
      gameConfig: json['gameConfig'] != null
          ? Map<String, dynamic>.from(json['gameConfig'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'inviteId': inviteId,
    'senderId': senderId,
    'senderName': senderName,
    'receiverId': receiverId,
    'gameType': gameType,
    'status': status.name,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'respondedAt': respondedAt?.millisecondsSinceEpoch,
    'roomCode': roomCode,
    'gameConfig': gameConfig,
  };

  GameInvite copyWith({
    String? inviteId,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? gameType,
    InviteStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? roomCode,
    Map<String, dynamic>? gameConfig,
  }) {
    return GameInvite(
      inviteId: inviteId ?? this.inviteId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      gameType: gameType ?? this.gameType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      roomCode: roomCode ?? this.roomCode,
      gameConfig: gameConfig ?? this.gameConfig,
    );
  }
}

class InviteService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Reference to invites in Firebase
  DatabaseReference get _invitesRef => _database.ref('invites');

  /// Invite timeout duration (30 seconds)
  static const Duration inviteTimeout = Duration(seconds: 30);

  /// Sends a game invite to a buddy
  Future<GameInvite> sendInvite({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String gameType,
    Map<String, dynamic>? gameConfig,
  }) async {
    final inviteId = _invitesRef.push().key!;
    final now = DateTime.now();

    final invite = GameInvite(
      inviteId: inviteId,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      gameType: gameType,
      status: InviteStatus.pending,
      createdAt: now,
      gameConfig: gameConfig,
    );

    // Save invite to sender's outgoing and receiver's incoming
    await Future.wait([
      _invitesRef.child('outgoing/$senderId/$inviteId').set(invite.toJson()),
      _invitesRef.child('incoming/$receiverId/$inviteId').set(invite.toJson()),
    ]);

    return invite;
  }

  /// Accepts a game invite
  Future<GameInvite> acceptInvite({
    required String inviteId,
    required String receiverId,
    required String roomCode,
  }) async {
    final now = DateTime.now();

    // Get the invite first
    final snapshot = await _invitesRef
        .child('incoming/$receiverId/$inviteId')
        .get();
    if (!snapshot.exists) {
      throw Exception('Invite not found');
    }

    final invite = GameInvite.fromJson(
      Map<String, dynamic>.from(snapshot.value as Map),
    );

    if (invite.status != InviteStatus.pending) {
      throw Exception('Invite is no longer valid');
    }

    final updatedInvite = invite.copyWith(
      status: InviteStatus.accepted,
      respondedAt: now,
      roomCode: roomCode,
    );

    // Update both sender's and receiver's copies
    await Future.wait([
      _invitesRef
          .child('outgoing/${invite.senderId}/$inviteId')
          .update(updatedInvite.toJson()),
      _invitesRef
          .child('incoming/$receiverId/$inviteId')
          .update(updatedInvite.toJson()),
    ]);

    return updatedInvite;
  }

  /// Declines a game invite
  Future<void> declineInvite({
    required String inviteId,
    required String receiverId,
  }) async {
    final now = DateTime.now();

    // Get the invite first
    final snapshot = await _invitesRef
        .child('incoming/$receiverId/$inviteId')
        .get();
    if (!snapshot.exists) {
      return; // Already deleted or doesn't exist
    }

    final invite = GameInvite.fromJson(
      Map<String, dynamic>.from(snapshot.value as Map),
    );

    final updates = {
      'status': InviteStatus.declined.name,
      'respondedAt': now.millisecondsSinceEpoch,
    };

    // Update both copies
    await Future.wait([
      _invitesRef
          .child('outgoing/${invite.senderId}/$inviteId')
          .update(updates),
      _invitesRef.child('incoming/$receiverId/$inviteId').update(updates),
    ]);
  }

  /// Cancels a sent invite
  Future<void> cancelInvite({
    required String inviteId,
    required String senderId,
  }) async {
    // Get the invite first
    final snapshot = await _invitesRef
        .child('outgoing/$senderId/$inviteId')
        .get();
    if (!snapshot.exists) {
      return;
    }

    final invite = GameInvite.fromJson(
      Map<String, dynamic>.from(snapshot.value as Map),
    );

    // Remove both copies
    await Future.wait([
      _invitesRef.child('outgoing/$senderId/$inviteId').remove(),
      _invitesRef.child('incoming/${invite.receiverId}/$inviteId').remove(),
    ]);
  }

  /// Watches for incoming invites
  Stream<List<GameInvite>> watchIncomingInvites(String userId) {
    return _invitesRef.child('incoming/$userId').onValue.map((event) {
      if (!event.snapshot.exists) {
        return <GameInvite>[];
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final invites = <GameInvite>[];

      data.forEach((key, value) {
        final invite = GameInvite.fromJson(
          Map<String, dynamic>.from(value as Map),
        );
        // Only include pending invites that haven't expired
        if (invite.isPending && !_isExpired(invite)) {
          invites.add(invite);
        }
      });

      // Sort by most recent
      invites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return invites;
    });
  }

  /// Watches a specific invite for status changes
  Stream<GameInvite?> watchInvite({
    required String inviteId,
    required String userId,
    required bool isOutgoing,
  }) {
    final path = isOutgoing
        ? 'outgoing/$userId/$inviteId'
        : 'incoming/$userId/$inviteId';

    return _invitesRef.child(path).onValue.map((event) {
      if (!event.snapshot.exists) {
        return null;
      }
      return GameInvite.fromJson(
        Map<String, dynamic>.from(event.snapshot.value as Map),
      );
    });
  }

  /// Checks if an invite has expired
  bool _isExpired(GameInvite invite) {
    return DateTime.now().difference(invite.createdAt) > inviteTimeout;
  }

  /// Cleans up expired invites for a user
  Future<void> cleanupExpiredInvites(String userId) async {
    final snapshot = await _invitesRef.child('incoming/$userId').get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    for (final entry in data.entries) {
      final invite = GameInvite.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );

      if (_isExpired(invite)) {
        await Future.wait([
          _invitesRef.child('incoming/$userId/${invite.inviteId}').remove(),
          _invitesRef
              .child('outgoing/${invite.senderId}/${invite.inviteId}')
              .remove(),
        ]);
      }
    }
  }

  /// Gets pending outgoing invite to a specific user
  Future<GameInvite?> getPendingInviteTo(
    String senderId,
    String receiverId,
  ) async {
    final snapshot = await _invitesRef.child('outgoing/$senderId').get();
    if (!snapshot.exists) return null;

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    for (final entry in data.entries) {
      final invite = GameInvite.fromJson(
        Map<String, dynamic>.from(entry.value as Map),
      );
      if (invite.receiverId == receiverId &&
          invite.isPending &&
          !_isExpired(invite)) {
        return invite;
      }
    }

    return null;
  }
}
