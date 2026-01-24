/// Firebase Signaling Service for WebRTC
///
/// Handles offer/answer exchange and ICE candidate signaling via Firebase Realtime Database.
library;

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

/// Signaling message types
enum SignalType { offer, answer, candidate, leave }

/// A signaling message for WebRTC connection setup
class SignalingMessage {
  final String fromUserId;
  final String toUserId;
  final SignalType type;
  final Map<String, dynamic> data;
  final int timestamp;

  SignalingMessage({
    required this.fromUserId,
    required this.toUserId,
    required this.type,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'type': type.name,
        'data': data,
        'timestamp': timestamp,
      };

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    return SignalingMessage(
      fromUserId: json['fromUserId'] as String,
      toUserId: json['toUserId'] as String,
      type: SignalType.values.firstWhere((e) => e.name == json['type']),
      data: Map<String, dynamic>.from(json['data'] as Map),
      timestamp: json['timestamp'] as int,
    );
  }
}

/// Firebase-based signaling service for WebRTC
class SignalingService {
  final String roomId;
  final String userId;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference get _roomRef => _database.ref('voice_rooms/$roomId');
  DatabaseReference get _signalsRef => _roomRef.child('signals');
  DatabaseReference get _participantsRef => _roomRef.child('participants');

  StreamSubscription? _signalSubscription;
  final _messageController = StreamController<SignalingMessage>.broadcast();

  /// Stream of incoming signaling messages for this user
  Stream<SignalingMessage> get onMessage => _messageController.stream;

  SignalingService({
    required this.roomId,
    required this.userId,
  });

  /// Join the signaling room and start listening for messages
  Future<void> join(String userName) async {
    // Register as participant
    await _participantsRef.child(userId).set({
      'name': userName,
      'joinedAt': ServerValue.timestamp,
      'online': true,
    });

    // Set up presence detection
    _participantsRef.child(userId).onDisconnect().remove();

    // Listen for signals directed to this user
    _signalSubscription = _signalsRef
        .orderByChild('toUserId')
        .equalTo(userId)
        .onChildAdded
        .listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final message = SignalingMessage.fromJson(data);
        _messageController.add(message);

        // Delete processed signal
        event.snapshot.ref.remove();
      }
    });

    print('SignalingService: Joined room $roomId as $userId');
  }

  /// Get list of current participants in the room
  Future<List<String>> getParticipants() async {
    try {
      final snapshot = await _participantsRef.get();
      if (!snapshot.exists || snapshot.value == null) return [];
      
      // Handle different data types from Firebase
      final value = snapshot.value;
      if (value is Map) {
        final data = Map<String, dynamic>.from(value);
        return data.keys.where((id) => id != userId).toList();
      }
      return [];
    } catch (e) {
      print('SignalingService: Error getting participants: $e');
      return [];
    }
  }

  /// Listen for new participants joining
  Stream<String> get onParticipantJoined {
    return _participantsRef.onChildAdded
        .where((event) => event.snapshot.key != userId)
        .map((event) => event.snapshot.key!);
  }

  /// Listen for participants leaving
  Stream<String> get onParticipantLeft {
    return _participantsRef.onChildRemoved.map((event) => event.snapshot.key!);
  }

  /// Send a signaling message to a specific user
  Future<void> sendMessage(SignalingMessage message) async {
    await _signalsRef.push().set(message.toJson());
  }

  /// Send an offer to a peer
  Future<void> sendOffer(String toUserId, Map<String, dynamic> sdp) async {
    await sendMessage(SignalingMessage(
      fromUserId: userId,
      toUserId: toUserId,
      type: SignalType.offer,
      data: sdp,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  /// Send an answer to a peer
  Future<void> sendAnswer(String toUserId, Map<String, dynamic> sdp) async {
    await sendMessage(SignalingMessage(
      fromUserId: userId,
      toUserId: toUserId,
      type: SignalType.answer,
      data: sdp,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  /// Send an ICE candidate to a peer
  Future<void> sendCandidate(
      String toUserId, Map<String, dynamic> candidate) async {
    await sendMessage(SignalingMessage(
      fromUserId: userId,
      toUserId: toUserId,
      type: SignalType.candidate,
      data: candidate,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  /// Notify peers that this user is leaving
  Future<void> sendLeave() async {
    final participants = await getParticipants();
    for (final peerId in participants) {
      await sendMessage(SignalingMessage(
        fromUserId: userId,
        toUserId: peerId,
        type: SignalType.leave,
        data: {},
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  /// Leave the signaling room
  Future<void> leave() async {
    await sendLeave();
    await _signalSubscription?.cancel();
    await _participantsRef.child(userId).remove();
    await _messageController.close();
    print('SignalingService: Left room $roomId');
  }

  /// Dispose resources
  void dispose() {
    _signalSubscription?.cancel();
    if (!_messageController.isClosed) {
      _messageController.close();
    }
  }
}
