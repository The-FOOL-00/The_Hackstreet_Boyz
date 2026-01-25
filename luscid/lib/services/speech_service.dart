/// Speech Service
///
/// Handles Speech-to-Text (STT) and Text-to-Speech (TTS) for the Avatar.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class SpeechService extends ChangeNotifier {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _ttsInitialized = false;
  bool _sttInitialized = false;
  bool _isSpeaking = false;
  bool _isListening = false;
  String _lastWords = '';
  double _confidence = 0.0;

  // Callbacks
  Function(bool)? onSpeakingChanged;
  Function(String)? onSpeechResult;
  Function()? onListeningStarted;
  Function()? onListeningStopped;

  // Getters
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  double get confidence => _confidence;
  bool get isReady => _ttsInitialized;
  bool get canListen => _sttInitialized;

  /// Initialize TTS and STT
  Future<void> init() async {
    await _initTts();
    await _initStt();
  }

  /// Initialize Text-to-Speech
  Future<void> _initTts() async {
    try {
      // Configure TTS for elderly-friendly speech
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45); // Slower for elderly
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Set up callbacks
      _tts.setStartHandler(() {
        _isSpeaking = true;
        onSpeakingChanged?.call(true);
        notifyListeners();
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        onSpeakingChanged?.call(false);
        notifyListeners();
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
        onSpeakingChanged?.call(false);
        notifyListeners();
      });

      _tts.setErrorHandler((message) {
        debugPrint('TTS Error: $message');
        _isSpeaking = false;
        onSpeakingChanged?.call(false);
        notifyListeners();
      });

      _ttsInitialized = true;
      debugPrint('✅ TTS initialized');
    } catch (e) {
      debugPrint('❌ TTS initialization failed: $e');
    }
  }

  /// Initialize Speech-to-Text
  Future<void> _initStt() async {
    try {
      _sttInitialized = await _stt.initialize(
        onError: (error) {
          debugPrint('STT Error: ${error.errorMsg}');
          _isListening = false;
          onListeningStopped?.call();
          notifyListeners();
        },
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
            onListeningStopped?.call();
            notifyListeners();
          }
        },
      );

      if (_sttInitialized) {
        debugPrint('✅ STT initialized');
      } else {
        debugPrint('⚠️ STT not available on this device');
      }
    } catch (e) {
      debugPrint('❌ STT initialization failed: $e');
      _sttInitialized = false;
    }
  }

  /// Speak text with optional callback when done
  Future<void> speak(String text, {VoidCallback? onComplete}) async {
    if (!_ttsInitialized) {
      debugPrint('TTS not initialized');
      return;
    }

    // Stop any ongoing speech
    if (_isSpeaking) {
      await stop();
    }

    // Stop listening if active
    if (_isListening) {
      await stopListening();
    }

    try {
      if (onComplete != null) {
        _tts.setCompletionHandler(() {
          _isSpeaking = false;
          onSpeakingChanged?.call(false);
          notifyListeners();
          onComplete();
        });
      }

      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  /// Stop speaking
  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
      onSpeakingChanged?.call(false);
      notifyListeners();
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  /// Start listening for speech
  Future<void> startListening({
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_sttInitialized) {
      debugPrint('STT not available');
      return;
    }

    // Stop speaking first
    if (_isSpeaking) {
      await stop();
    }

    if (_isListening) {
      return;
    }

    try {
      _lastWords = '';
      _confidence = 0.0;
      _isListening = true;
      onListeningStarted?.call();
      notifyListeners();

      await _stt.listen(
        onResult: _onSpeechResult,
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: pauseFor ?? const Duration(seconds: 3),
        partialResults: true,
        localeId: 'en_US',
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      debugPrint('STT listen error: $e');
      _isListening = false;
      notifyListeners();
    }
  }

  /// Handle speech recognition result
  void _onSpeechResult(SpeechRecognitionResult result) {
    _lastWords = result.recognizedWords;
    _confidence = result.confidence;
    
    if (result.finalResult) {
      onSpeechResult?.call(_lastWords);
      _isListening = false;
      onListeningStopped?.call();
    }
    
    notifyListeners();
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _stt.stop();
      _isListening = false;
      onListeningStopped?.call();
      notifyListeners();
    } catch (e) {
      debugPrint('STT stop error: $e');
    }
  }

  /// Get available voices
  Future<List<dynamic>> getVoices() async {
    try {
      return await _tts.getVoices;
    } catch (e) {
      return [];
    }
  }

  /// Set speech rate (0.0 - 1.0, default 0.45 for elderly)
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  /// Set pitch (0.5 - 2.0)
  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch.clamp(0.5, 2.0));
  }

  /// Set volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    await _tts.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Check if STT is available
  Future<bool> checkSttAvailability() async {
    if (!_sttInitialized) {
      return false;
    }
    return _stt.isAvailable;
  }

  /// Dispose resources
  @override
  void dispose() {
    _tts.stop();
    _stt.stop();
    super.dispose();
  }
}
