/// Voice Chat Service - Main API for P2P voice chat
///
/// Combines WebRTC and Firebase signaling for seamless voice chat.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'signaling_service.dart';
import 'webrtc_manager.dart';

/// Connection state for voice chat
enum VoiceChatState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Voice chat service for multiplayer games
class VoiceChatService extends ChangeNotifier {
  final String roomId;
  final String userId;
  final String userName;

  late final SignalingService _signaling;
  late final WebRTCManager _webrtc;

  VoiceChatState _state = VoiceChatState.disconnected;
  String? _errorMessage;
  final Set<String> _connectedPeers = {};

  StreamSubscription? _messageSubscription;
  StreamSubscription? _joinSubscription;
  StreamSubscription? _leaveSubscription;

  /// Current connection state
  VoiceChatState get state => _state;

  /// Error message if state is error
  String? get errorMessage => _errorMessage;

  /// Whether currently connected to voice chat
  bool get isConnected => _state == VoiceChatState.connected;

  /// Whether microphone is muted
  bool get isMuted => _webrtc.isMuted;

  /// Number of connected peers
  int get peerCount => _connectedPeers.length;

  /// List of connected peer IDs
  List<String> get connectedPeers => _connectedPeers.toList();

  VoiceChatService({
    required this.roomId,
    required this.userId,
    required this.userName,
  }) {
    _signaling = SignalingService(roomId: roomId, userId: userId);
    _webrtc = WebRTCManager();
  }

  /// Request microphone permission
  Future<bool> _requestPermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _state = VoiceChatState.error;
      _errorMessage = 'Microphone permission denied';
      notifyListeners();
      return false;
    }
    return true;
  }

  /// Join the voice chat room
  Future<bool> joinRoom() async {
    if (_state == VoiceChatState.connecting ||
        _state == VoiceChatState.connected) {
      return true;
    }

    _state = VoiceChatState.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      // Request microphone permission
      if (!await _requestPermission()) {
        return false;
      }

      // Initialize WebRTC
      await _webrtc.initialize();

      // Set up WebRTC callbacks
      _webrtc.onIceCandidate = _onIceCandidate;
      _webrtc.onConnectionState = _onConnectionState;
      _webrtc.onRemoteTrack = _onRemoteTrack;

      // Join signaling room
      await _signaling.join(userName);

      // Listen for signaling messages
      _messageSubscription = _signaling.onMessage.listen(_handleSignalingMessage);

      // Listen for new participants
      _joinSubscription = _signaling.onParticipantJoined.listen(_onParticipantJoined);
      _leaveSubscription = _signaling.onParticipantLeft.listen(_onParticipantLeft);

      // Connect to existing participants
      final existingPeers = await _signaling.getParticipants();
      for (final peerId in existingPeers) {
        await _connectToPeer(peerId);
      }

      _state = VoiceChatState.connected;
      notifyListeners();
      print('VoiceChatService: Joined room $roomId');
      return true;
    } catch (e) {
      _state = VoiceChatState.error;
      _errorMessage = 'Failed to join voice chat: $e';
      notifyListeners();
      print('VoiceChatService: Error joining room: $e');
      return false;
    }
  }

  /// Connect to a peer by creating an offer
  Future<void> _connectToPeer(String peerId) async {
    try {
      final offer = await _webrtc.createOffer(peerId);
      await _signaling.sendOffer(peerId, offer.toMap());
      print('VoiceChatService: Sent offer to $peerId');
    } catch (e) {
      print('VoiceChatService: Error connecting to peer $peerId: $e');
    }
  }

  /// Handle incoming signaling messages
  Future<void> _handleSignalingMessage(SignalingMessage message) async {
    switch (message.type) {
      case SignalType.offer:
        await _handleOffer(message);
        break;
      case SignalType.answer:
        await _handleAnswer(message);
        break;
      case SignalType.candidate:
        await _handleCandidate(message);
        break;
      case SignalType.leave:
        await _handleLeave(message);
        break;
    }
  }

  /// Handle incoming offer
  Future<void> _handleOffer(SignalingMessage message) async {
    try {
      final offer = RTCSessionDescription(
        message.data['sdp'] as String,
        message.data['type'] as String,
      );
      final answer = await _webrtc.handleOffer(message.fromUserId, offer);
      await _signaling.sendAnswer(message.fromUserId, answer.toMap());
      print('VoiceChatService: Handled offer from ${message.fromUserId}');
    } catch (e) {
      print('VoiceChatService: Error handling offer: $e');
    }
  }

  /// Handle incoming answer
  Future<void> _handleAnswer(SignalingMessage message) async {
    try {
      final answer = RTCSessionDescription(
        message.data['sdp'] as String,
        message.data['type'] as String,
      );
      await _webrtc.handleAnswer(message.fromUserId, answer);
      print('VoiceChatService: Handled answer from ${message.fromUserId}');
    } catch (e) {
      print('VoiceChatService: Error handling answer: $e');
    }
  }

  /// Handle incoming ICE candidate
  Future<void> _handleCandidate(SignalingMessage message) async {
    try {
      final candidate = RTCIceCandidate(
        message.data['candidate'] as String,
        message.data['sdpMid'] as String?,
        message.data['sdpMLineIndex'] as int?,
      );
      await _webrtc.addIceCandidate(message.fromUserId, candidate);
    } catch (e) {
      print('VoiceChatService: Error handling ICE candidate: $e');
    }
  }

  /// Handle peer leaving
  Future<void> _handleLeave(SignalingMessage message) async {
    await _webrtc.closePeer(message.fromUserId);
    _connectedPeers.remove(message.fromUserId);
    notifyListeners();
  }

  /// Called when a new participant joins
  void _onParticipantJoined(String peerId) {
    // The new participant will send us an offer, so we just wait
    print('VoiceChatService: Participant joined: $peerId');
  }

  /// Called when a participant leaves
  void _onParticipantLeft(String peerId) {
    _webrtc.closePeer(peerId);
    _connectedPeers.remove(peerId);
    notifyListeners();
    print('VoiceChatService: Participant left: $peerId');
  }

  /// Called when we have an ICE candidate to send
  void _onIceCandidate(String peerId, RTCIceCandidate candidate) {
    _signaling.sendCandidate(peerId, candidate.toMap());
  }

  /// Called when connection state changes
  void _onConnectionState(String peerId, RTCPeerConnectionState state) {
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      _connectedPeers.add(peerId);
    } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
        state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
        state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
      _connectedPeers.remove(peerId);
    }
    notifyListeners();
  }

  /// Called when we receive a remote audio track
  void _onRemoteTrack(String peerId, MediaStream stream) {
    // Audio plays automatically, no action needed
    print('VoiceChatService: Receiving audio from $peerId');
  }

  /// Toggle mute state
  void toggleMute() {
    _webrtc.toggleMute();
    notifyListeners();
  }

  /// Set mute state
  void setMute(bool muted) {
    _webrtc.setMute(muted);
    notifyListeners();
  }

  /// Leave the voice chat room
  Future<void> leaveRoom() async {
    await _messageSubscription?.cancel();
    await _joinSubscription?.cancel();
    await _leaveSubscription?.cancel();
    await _signaling.leave();
    await _webrtc.dispose();

    _connectedPeers.clear();
    _state = VoiceChatState.disconnected;
    notifyListeners();

    print('VoiceChatService: Left room $roomId');
  }

  @override
  void dispose() {
    leaveRoom();
    _signaling.dispose();
    super.dispose();
  }
}
