/// WebRTC Manager - Handles P2P audio connections
///
/// Manages multiple peer connections for multiplayer voice chat.
library;

import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Debug logger for WebRTC
class _VoiceLog {
  static const String _tag = '🎙️ VoiceChat';

  static void info(String message) {
    print('$_tag [INFO] $message');
  }

  static void debug(String message) {
    print('$_tag [DEBUG] $message');
  }

  static void error(String message, [Object? error]) {
    print('$_tag [ERROR] $message${error != null ? ': $error' : ''}');
  }

  static void ice(String peerId, String message) {
    print('$_tag [ICE:$peerId] $message');
  }

  static void peer(String peerId, String message) {
    print('$_tag [PEER:$peerId] $message');
  }

  static void audio(String message) {
    print('$_tag [AUDIO] $message');
  }
}

/// Configuration for WebRTC connections
class WebRTCConfig {
  /// STUN/TURN servers for NAT traversal
  /// Using free public TURN servers for better connectivity
  static const Map<String, dynamic> configuration = {
    'iceServers': [
      // Google STUN servers
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
      // OpenRelay TURN servers (free, public)
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
    'sdpSemantics': 'unified-plan',
    'iceCandidatePoolSize': 10,
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
    'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': false},
    'optional': [],
  };
}

/// Represents a peer connection with another user
class PeerConnection {
  final String peerId;
  final RTCPeerConnection connection;
  bool isConnected = false;

  PeerConnection({required this.peerId, required this.connection});
}

/// Callback types for WebRTC events
typedef OnIceCandidateCallback =
    void Function(String peerId, RTCIceCandidate candidate);
typedef OnConnectionStateCallback =
    void Function(String peerId, RTCPeerConnectionState state);
typedef OnTrackCallback = void Function(String peerId, MediaStream stream);

/// Manages WebRTC peer connections for voice chat
class WebRTCManager {
  final Map<String, PeerConnection> _peers = {};
  final Map<String, List<RTCIceCandidate>> _pendingCandidates = {};
  final Map<String, MediaStream> _remoteStreams = {}; // Store remote streams
  MediaStream? _localStream;
  bool _isMuted = false;
  bool _isSpeakerOn = true;

  /// Callbacks
  OnIceCandidateCallback? onIceCandidate;
  OnConnectionStateCallback? onConnectionState;
  OnTrackCallback? onRemoteTrack;

  /// Whether the local microphone is muted
  bool get isMuted => _isMuted;

  /// Whether speaker is on
  bool get isSpeakerOn => _isSpeakerOn;

  /// Whether local stream is initialized
  bool get isInitialized => _localStream != null;

  /// List of connected peer IDs
  List<String> get connectedPeers => _peers.entries
      .where((e) => e.value.isConnected)
      .map((e) => e.key)
      .toList();

  /// Initialize local audio stream
  Future<void> initialize() async {
    if (_localStream != null) {
      _VoiceLog.info('Already initialized, skipping');
      return;
    }

    _VoiceLog.info('Initializing local audio stream...');
    try {
      _localStream = await navigator.mediaDevices.getUserMedia(
        WebRTCConfig.mediaConstraints,
      );

      final audioTracks = _localStream!.getAudioTracks();
      _VoiceLog.audio('Got ${audioTracks.length} audio track(s)');
      for (final track in audioTracks) {
        _VoiceLog.audio(
          'Track: id=${track.id}, enabled=${track.enabled}, muted=${track.muted}',
        );
      }

      // Enable speakerphone by default for group voice chat
      await Helper.setSpeakerphoneOn(true);
      _isSpeakerOn = true;

      _VoiceLog.info('✅ Local audio stream initialized, speaker ON');
    } catch (e) {
      _VoiceLog.error('Failed to get user media', e);
      rethrow;
    }
  }

  /// Toggle speakerphone
  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    await Helper.setSpeakerphoneOn(_isSpeakerOn);
    _VoiceLog.audio('Speaker ${_isSpeakerOn ? "ON 🔊" : "OFF 🔇"}');
  }

  /// Set speakerphone state
  Future<void> setSpeaker(bool enabled) async {
    _isSpeakerOn = enabled;
    await Helper.setSpeakerphoneOn(_isSpeakerOn);
    _VoiceLog.audio('Speaker set to ${enabled ? "ON" : "OFF"}');
  }

  /// Create a peer connection for a specific user
  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    _VoiceLog.peer(peerId, 'Creating peer connection...');

    final pc = await createPeerConnection(WebRTCConfig.configuration);
    _VoiceLog.peer(peerId, 'Peer connection created');

    // Add local stream tracks
    if (_localStream != null) {
      final tracks = _localStream!.getTracks();
      _VoiceLog.peer(peerId, 'Adding ${tracks.length} local track(s)');
      for (final track in tracks) {
        await pc.addTrack(track, _localStream!);
        _VoiceLog.peer(
          peerId,
          'Added track: ${track.kind}, enabled=${track.enabled}',
        );
      }
    } else {
      _VoiceLog.error(
        'No local stream available when creating peer connection!',
      );
    }

    // Handle ICE candidates
    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        final candidateStr = candidate.candidate!;
        final isRelay = candidateStr.contains('relay');
        final isHost = candidateStr.contains('host');
        final isSrflx = candidateStr.contains('srflx');
        _VoiceLog.ice(
          peerId,
          'Generated: ${isRelay
              ? "RELAY(TURN)"
              : isHost
              ? "HOST"
              : isSrflx
              ? "SRFLX(STUN)"
              : "OTHER"}',
        );
        onIceCandidate?.call(peerId, candidate);
      }
    };

    // Handle ICE connection state
    pc.onIceConnectionState = (state) {
      _VoiceLog.ice(peerId, 'ICE connection state: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _VoiceLog.error('ICE connection failed - may need TURN server');
      }
    };

    // Handle ICE gathering state
    pc.onIceGatheringState = (state) {
      _VoiceLog.ice(peerId, 'ICE gathering state: $state');
    };

    // Handle connection state changes
    pc.onConnectionState = (state) {
      final emoji = switch (state) {
        RTCPeerConnectionState.RTCPeerConnectionStateConnected => '✅',
        RTCPeerConnectionState.RTCPeerConnectionStateFailed => '❌',
        RTCPeerConnectionState.RTCPeerConnectionStateDisconnected => '⚠️',
        RTCPeerConnectionState.RTCPeerConnectionStateClosed => '🔒',
        _ => '🔄',
      };
      _VoiceLog.peer(peerId, '$emoji Connection state: $state');
      _peers[peerId]?.isConnected =
          state == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
      onConnectionState?.call(peerId, state);
    };

    // Handle signaling state
    pc.onSignalingState = (state) {
      _VoiceLog.peer(peerId, 'Signaling state: $state');
    };

    // Handle remote tracks - THIS IS WHERE AUDIO COMES IN
    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        final stream = event.streams[0];
        final audioTracks = stream.getAudioTracks();
        _VoiceLog.audio(
          '📥 Received ${audioTracks.length} remote audio track(s) from $peerId',
        );

        // Store the remote stream
        _remoteStreams[peerId] = stream;

        // IMPORTANT: Enable all audio tracks for playback
        for (final track in audioTracks) {
          track.enabled = true; // Make sure track is enabled
          _VoiceLog.audio(
            'Remote track: id=${track.id}, enabled=${track.enabled}, muted=${track.muted}',
          );
        }

        // Ensure speaker is on for remote audio
        Helper.setSpeakerphoneOn(_isSpeakerOn);
        _VoiceLog.audio(
          '🔊 Audio playback enabled for $peerId, speaker: $_isSpeakerOn',
        );

        onRemoteTrack?.call(peerId, stream);
      } else {
        _VoiceLog.error('Received track event but no streams!');
      }
    };

    // Handle remote stream added (legacy) - also enable audio here
    pc.onAddStream = (stream) {
      _VoiceLog.audio('📥 [Legacy] Remote stream added from $peerId');
      _remoteStreams[peerId] = stream;
      for (final track in stream.getAudioTracks()) {
        track.enabled = true;
      }
      Helper.setSpeakerphoneOn(_isSpeakerOn);
    };

    _peers[peerId] = PeerConnection(peerId: peerId, connection: pc);
    _VoiceLog.peer(peerId, 'Peer connection setup complete');

    // Process any pending ICE candidates
    if (_pendingCandidates.containsKey(peerId)) {
      _VoiceLog.ice(
        peerId,
        'Processing ${_pendingCandidates[peerId]!.length} pending candidates',
      );
      for (final candidate in _pendingCandidates[peerId]!) {
        await pc.addCandidate(candidate);
      }
      _pendingCandidates.remove(peerId);
    }

    return pc;
  }

  /// Create an offer to connect to a peer
  Future<RTCSessionDescription> createOffer(String peerId) async {
    _VoiceLog.info('Creating offer for $peerId...');
    final pc = await _createPeerConnection(peerId);
    final offer = await pc.createOffer(WebRTCConfig.offerSdpConstraints);
    await pc.setLocalDescription(offer);
    _VoiceLog.info('✅ Created and set local offer for $peerId');
    return offer;
  }

  /// Handle an incoming offer and create an answer
  Future<RTCSessionDescription> handleOffer(
    String peerId,
    RTCSessionDescription offer,
  ) async {
    _VoiceLog.info('Handling offer from $peerId...');
    final pc = await _createPeerConnection(peerId);
    await pc.setRemoteDescription(offer);
    _VoiceLog.peer(peerId, 'Remote description set');
    final answer = await pc.createAnswer(WebRTCConfig.offerSdpConstraints);
    await pc.setLocalDescription(answer);
    _VoiceLog.info('✅ Created answer for $peerId');
    return answer;
  }

  /// Handle an incoming answer
  Future<void> handleAnswer(String peerId, RTCSessionDescription answer) async {
    _VoiceLog.info('Handling answer from $peerId...');
    final peer = _peers[peerId];
    if (peer == null) {
      _VoiceLog.error('No peer connection for $peerId when handling answer!');
      return;
    }
    await peer.connection.setRemoteDescription(answer);
    _VoiceLog.peer(peerId, '✅ Remote description set from answer');
  }

  /// Add an ICE candidate from a peer
  Future<void> addIceCandidate(String peerId, RTCIceCandidate candidate) async {
    final peer = _peers[peerId];
    if (peer == null) {
      // Queue the candidate for later
      _VoiceLog.ice(peerId, 'Queuing ICE candidate (peer not ready)');
      _pendingCandidates.putIfAbsent(peerId, () => []);
      _pendingCandidates[peerId]!.add(candidate);
      return;
    }

    final candidateStr = candidate.candidate ?? '';
    final isRelay = candidateStr.contains('relay');
    _VoiceLog.ice(
      peerId,
      'Adding remote candidate: ${isRelay ? "RELAY" : "NON-RELAY"}',
    );
    await peer.connection.addCandidate(candidate);
  }

  /// Toggle mute state
  void toggleMute() {
    _isMuted = !_isMuted;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
    _VoiceLog.audio('Mute: ${_isMuted ? "ON 🔇" : "OFF 🎙️"}');
  }

  /// Set mute state
  void setMute(bool muted) {
    _isMuted = muted;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
    _VoiceLog.audio('Mute set to: $muted');
  }

  /// Close connection with a specific peer
  Future<void> closePeer(String peerId) async {
    final peer = _peers.remove(peerId);
    _pendingCandidates.remove(peerId);
    _remoteStreams.remove(peerId); // Clean up remote stream
    if (peer != null) {
      await peer.connection.close();
      _VoiceLog.peer(peerId, '🔒 Connection closed');
    }
  }

  /// Close all connections and release resources
  Future<void> dispose() async {
    _VoiceLog.info('Disposing WebRTCManager...');

    // Close all peer connections
    for (final peer in _peers.values) {
      await peer.connection.close();
      _VoiceLog.peer(peer.peerId, 'Connection closed');
    }
    _peers.clear();
    _pendingCandidates.clear();

    // Clean up remote streams
    for (final stream in _remoteStreams.values) {
      stream.getTracks().forEach((track) => track.stop());
      stream.dispose();
    }
    _remoteStreams.clear();

    // Stop local stream
    _localStream?.getTracks().forEach((track) {
      track.stop();
    });
    _localStream?.dispose();
    _localStream = null;

    _VoiceLog.info('✅ WebRTCManager disposed');
  }

  /// Get debug info about current state
  Map<String, dynamic> getDebugInfo() {
    return {
      'initialized': isInitialized,
      'muted': _isMuted,
      'speakerOn': _isSpeakerOn,
      'localTracks': _localStream?.getAudioTracks().length ?? 0,
      'peers': _peers.map(
        (id, peer) => MapEntry(id, {'connected': peer.isConnected}),
      ),
      'pendingCandidates': _pendingCandidates.map(
        (id, candidates) => MapEntry(id, candidates.length),
      ),
    };
  }
}
