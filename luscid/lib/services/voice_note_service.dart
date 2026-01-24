/// Voice Note Service (Walkie-Talkie)
///
/// Handles voice recording, uploading to Firebase Storage, and playback.
library;

import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

/// Voice note metadata
class VoiceNote {
  final String id;
  final String senderId;
  final String senderName;
  final String url;
  final DateTime createdAt;
  final int durationMs;

  const VoiceNote({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.url,
    required this.createdAt,
    required this.durationMs,
  });

  factory VoiceNote.fromJson(Map<String, dynamic> json) {
    return VoiceNote(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String? ?? 'Player',
      url: json['url'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      durationMs: json['durationMs'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'url': url,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'durationMs': durationMs,
  };
}

class VoiceNoteService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  StreamSubscription<VoiceNote?>? _voiceNoteSubscription;

  /// Reference to voice notes in database
  DatabaseReference _voiceNotesRef(String roomCode) =>
      _database.ref('voice_notes/$roomCode');

  /// Checks if recording permission is granted
  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  /// Starts recording audio
  Future<bool> startRecording() async {
    try {
      if (!await hasPermission()) {
        return false;
      }

      // Get temp directory for recording
      final directory = await getTemporaryDirectory();
      _currentRecordingPath =
          '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Configure recording
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _recorder.start(config, path: _currentRecordingPath!);
      _recordingStartTime = DateTime.now();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stops recording and returns the file path
  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      return path;
    } catch (e) {
      return null;
    }
  }

  /// Uploads voice note to Firebase Storage
  Future<String?> uploadVoiceNote({
    required String filePath,
    required String roomCode,
    required String senderId,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final fileName =
          'voice_${senderId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final ref = _storage.ref('voice_notes/$roomCode/$fileName');

      // Upload file
      await ref.putFile(file);

      // Get download URL
      final url = await ref.getDownloadURL();

      // Clean up local file
      await file.delete();

      return url;
    } catch (e) {
      return null;
    }
  }

  /// Sends a voice note to a game room
  Future<VoiceNote?> sendVoiceNote({
    required String roomCode,
    required String senderId,
    required String senderName,
  }) async {
    try {
      // Stop recording
      final filePath = await stopRecording();
      if (filePath == null) {
        return null;
      }

      // Calculate duration
      final durationMs = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!).inMilliseconds
          : 0;

      // Upload to storage
      final url = await uploadVoiceNote(
        filePath: filePath,
        roomCode: roomCode,
        senderId: senderId,
      );

      if (url == null) {
        return null;
      }

      // Save metadata to database
      final noteRef = _voiceNotesRef(roomCode).push();
      final voiceNote = VoiceNote(
        id: noteRef.key!,
        senderId: senderId,
        senderName: senderName,
        url: url,
        createdAt: DateTime.now(),
        durationMs: durationMs,
      );

      await noteRef.set(voiceNote.toJson());

      // Also update the room's latest voice note URL
      await _database.ref('shopping_rooms/$roomCode/voiceNoteUrl').set(url);

      return voiceNote;
    } catch (e) {
      return null;
    }
  }

  /// Plays a voice note from URL
  Future<void> playVoiceNote(String url) async {
    try {
      await _player.stop();
      await _player.play(UrlSource(url));
    } catch (e) {
      // Handle playback error
    }
  }

  /// Stops audio playback
  Future<void> stopPlayback() async {
    await _player.stop();
  }

  /// Checks if audio is currently playing
  bool get isPlaying => _player.state == PlayerState.playing;

  /// Stream of playback state
  Stream<PlayerState> get playbackStateStream => _player.onPlayerStateChanged;

  /// Watches for new voice notes in a room
  Stream<VoiceNote?> watchLatestVoiceNote(String roomCode) {
    return _voiceNotesRef(
      roomCode,
    ).orderByChild('createdAt').limitToLast(1).onChildAdded.map((event) {
      if (event.snapshot.exists) {
        return VoiceNote.fromJson(
          Map<String, dynamic>.from(event.snapshot.value as Map),
        );
      }
      return null;
    });
  }

  /// Auto-plays new voice notes from other players
  void startAutoPlayback({
    required String roomCode,
    required String currentUserId,
  }) {
    _voiceNoteSubscription?.cancel();

    _voiceNoteSubscription = watchLatestVoiceNote(roomCode).listen((voiceNote) {
      if (voiceNote != null && voiceNote.senderId != currentUserId) {
        // Auto-play voice note from other player
        playVoiceNote(voiceNote.url);
      }
    });
  }

  /// Stops auto-playback subscription
  void stopAutoPlayback() {
    _voiceNoteSubscription?.cancel();
    _voiceNoteSubscription = null;
  }

  /// Cleans up resources
  void dispose() {
    stopAutoPlayback();
    _recorder.dispose();
    _player.dispose();
  }

  /// Deletes all voice notes for a room
  Future<void> deleteRoomVoiceNotes(String roomCode) async {
    try {
      // Delete from storage
      final listResult = await _storage.ref('voice_notes/$roomCode').listAll();
      for (final item in listResult.items) {
        await item.delete();
      }

      // Delete from database
      await _voiceNotesRef(roomCode).remove();
    } catch (e) {
      // Handle deletion error
    }
  }
}
