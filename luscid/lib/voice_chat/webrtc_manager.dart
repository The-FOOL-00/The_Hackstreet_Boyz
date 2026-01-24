/// WebRTC Manager - Handles P2P audio connections
///
/// Manages multiple peer connections for multiplayer voice chat.
library;

import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Configuration for WebRTC connections
class WebRTCConfig {
  /// STUN/TURN servers for NAT traversal
  static const Map<String, dynamic> configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  /// Constraints for audio-only stream
  static const Map<String, dynamic> mediaConstraints = {
    'audio': {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
    },
    'video': false,
  };

  /// Offer/Answer constraints
  static const Map<String, dynamic> offerSdpConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': false,
    },
    'optional': [],
  };
}

/// Represents a peer connection with another user
class PeerConnection {
  final String peerId;
  final RTCPeerConnection connection;
  bool isConnected = false;

  PeerConnection({
    required this.peerId,
    required this.connection,
  });
}

/// Callback types for WebRTC events
typedef OnIceCandidateCallback = void Function(
    String peerId, RTCIceCandidate candidate);
typedef OnConnectionStateCallback = void Function(
    String peerId, RTCPeerConnectionState state);
typedef OnTrackCallback = void Function(String peerId, MediaStream stream);

/// Manages WebRTC peer connections for voice chat
class WebRTCManager {
  final Map<String, PeerConnection> _peers = {};
  MediaStream? _localStream;
  bool _isMuted = false;

  /// Callbacks
  OnIceCandidateCallback? onIceCandidate;
  OnConnectionStateCallback? onConnectionState;
  OnTrackCallback? onRemoteTrack;

  /// Whether the local microphone is muted
  bool get isMuted => _isMuted;

  /// Whether local stream is initialized
  bool get isInitialized => _localStream != null;

  /// List of connected peer IDs
  List<String> get connectedPeers =>
      _peers.entries.where((e) => e.value.isConnected).map((e) => e.key).toList();

  /// Initialize local audio stream
  Future<void> initialize() async {
    if (_localStream != null) return;

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(
        WebRTCConfig.mediaConstraints,
      );
      print('WebRTCManager: Local audio stream initialized');
    } catch (e) {
      print('WebRTCManager: Failed to get user media: $e');
      rethrow;
    }
  }

  /// Create a peer connection for a specific user
  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    final pc = await createPeerConnection(WebRTCConfig.configuration);

    // Add local stream tracks
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    // Handle ICE candidates
    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        onIceCandidate?.call(peerId, candidate);
      }
    };

    // Handle connection state changes
    pc.onConnectionState = (state) {
      print('WebRTCManager: Connection state with $peerId: $state');
      _peers[peerId]?.isConnected =
          state == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
      onConnectionState?.call(peerId, state);
    };

    // Handle remote tracks
    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        print('WebRTCManager: Received remote track from $peerId');
        onRemoteTrack?.call(peerId, event.streams[0]);
      }
    };

    _peers[peerId] = PeerConnection(peerId: peerId, connection: pc);
    return pc;
  }

  /// Create an offer to connect to a peer
  Future<RTCSessionDescription> createOffer(String peerId) async {
    final pc = await _createPeerConnection(peerId);
    final offer = await pc.createOffer(WebRTCConfig.offerSdpConstraints);
    await pc.setLocalDescription(offer);
    print('WebRTCManager: Created offer for $peerId');
    return offer;
  }

  /// Handle an incoming offer and create an answer
  Future<RTCSessionDescription> handleOffer(
      String peerId, RTCSessionDescription offer) async {
    final pc = await _createPeerConnection(peerId);
    await pc.setRemoteDescription(offer);
    final answer = await pc.createAnswer(WebRTCConfig.offerSdpConstraints);
    await pc.setLocalDescription(answer);
    print('WebRTCManager: Created answer for $peerId');
    return answer;
  }

  /// Handle an incoming answer
  Future<void> handleAnswer(
      String peerId, RTCSessionDescription answer) async {
    final peer = _peers[peerId];
    if (peer == null) {
      print('WebRTCManager: No peer connection for $peerId');
      return;
    }
    await peer.connection.setRemoteDescription(answer);
    print('WebRTCManager: Set remote description for $peerId');
  }

  /// Add an ICE candidate from a peer
  Future<void> addIceCandidate(String peerId, RTCIceCandidate candidate) async {
    final peer = _peers[peerId];
    if (peer == null) {
      print('WebRTCManager: No peer connection for $peerId');
      return;
    }
    await peer.connection.addCandidate(candidate);
  }

  /// Toggle mute state
  void toggleMute() {
    _isMuted = !_isMuted;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
    print('WebRTCManager: Mute state: $_isMuted');
  }

  /// Set mute state
  void setMute(bool muted) {
    _isMuted = muted;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
  }

  /// Close connection with a specific peer
  Future<void> closePeer(String peerId) async {
    final peer = _peers.remove(peerId);
    if (peer != null) {
      await peer.connection.close();
      print('WebRTCManager: Closed connection with $peerId');
    }
  }

  /// Close all connections and release resources
  Future<void> dispose() async {
    // Close all peer connections
    for (final peer in _peers.values) {
      await peer.connection.close();
    }
    _peers.clear();

    // Stop local stream
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream?.dispose();
    _localStream = null;

    print('WebRTCManager: Disposed');
  }
}
