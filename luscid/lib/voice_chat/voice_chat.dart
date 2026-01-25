/// Voice Chat Module - Real-time P2P Audio for Multiplayer Games
///
/// This module provides WebRTC-based voice chat using Firebase for signaling.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:luscid/voice_chat/voice_chat.dart';
///
/// // Create voice chat instance
/// final voiceChat = VoiceChatService(
///   roomId: 'game-room-123',
///   userId: 'user-abc',
///   userName: 'John',
/// );
///
/// // Join voice room
/// await voiceChat.joinRoom();
///
/// // Toggle mute
/// voiceChat.toggleMute();
///
/// // Leave when done
/// await voiceChat.leaveRoom();
/// ```
library;

export 'voice_chat_service.dart';
export 'voice_chat_overlay.dart';
export 'webrtc_manager.dart';
export 'signaling_service.dart';
