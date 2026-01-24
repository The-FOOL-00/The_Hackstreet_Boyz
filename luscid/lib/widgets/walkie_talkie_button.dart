/// Walkie-Talkie Widget
///
/// Hold-to-talk button for voice communication during games.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/voice_note_service.dart';

class WalkieTalkieButton extends StatefulWidget {
  final String roomCode;
  final String userId;
  final String userName;
  final bool enabled;

  const WalkieTalkieButton({
    super.key,
    required this.roomCode,
    required this.userId,
    required this.userName,
    this.enabled = true,
  });

  @override
  State<WalkieTalkieButton> createState() => _WalkieTalkieButtonState();
}

class _WalkieTalkieButtonState extends State<WalkieTalkieButton>
    with SingleTickerProviderStateMixin {
  final VoiceNoteService _voiceService = VoiceNoteService();

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasPermission = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _checkPermission();
    _setupAutoPlayback();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceService.stopAutoPlayback();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    _hasPermission = await _voiceService.hasPermission();
    setState(() {});
  }

  void _setupAutoPlayback() {
    _voiceService.startAutoPlayback(
      roomCode: widget.roomCode,
      currentUserId: widget.userId,
    );

    // Listen for playback state
    _voiceService.playbackStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = _voiceService.isPlaying;
        });
      }
    });
  }

  Future<void> _startRecording() async {
    if (!widget.enabled || !_hasPermission) return;

    final started = await _voiceService.startRecording();
    if (started) {
      setState(() {
        _isRecording = true;
      });
      _pulseController.repeat(reverse: true);
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    _pulseController.stop();
    _pulseController.reset();

    setState(() {
      _isRecording = false;
    });

    // Send the voice note
    final voiceNote = await _voiceService.sendVoiceNote(
      roomCode: widget.roomCode,
      senderId: widget.userId,
      senderName: widget.userName,
    );

    if (voiceNote != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice message sent!'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF6B9080),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status indicator
        if (_isRecording || _isPlaying)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red : const Color(0xFF6B9080),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isRecording ? Icons.mic : Icons.volume_up,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _isRecording ? 'Recording...' : 'Playing...',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Main button
        GestureDetector(
          onLongPressStart: (_) => _startRecording(),
          onLongPressEnd: (_) => _stopRecording(),
          onTapDown: (_) => _startRecording(),
          onTapUp: (_) => _stopRecording(),
          onTapCancel: () => _stopRecording(),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isRecording ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording
                    ? Colors.red
                    : _isPlaying
                    ? const Color(0xFF6B9080)
                    : widget.enabled
                    ? const Color(0xFF6B9080)
                    : Colors.grey,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : const Color(0xFF6B9080))
                        .withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: _isRecording ? 5 : 0,
                  ),
                ],
              ),
              child: Icon(
                _isRecording
                    ? Icons.mic
                    : _isPlaying
                    ? Icons.volume_up
                    : Icons.mic_none,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
        ),

        // Label
        const SizedBox(height: 8),
        Text(
          _isRecording
              ? 'Release to send'
              : _hasPermission
              ? 'Hold to talk'
              : 'Tap to enable mic',
          style: GoogleFonts.poppins(
            color: const Color(0xFF5C6B66),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Floating walkie-talkie widget for game screens
class FloatingWalkieTalkie extends StatelessWidget {
  final String roomCode;
  final String userId;
  final String userName;

  const FloatingWalkieTalkie({
    super.key,
    required this.roomCode,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: WalkieTalkieButton(
        roomCode: roomCode,
        userId: userId,
        userName: userName,
      ),
    );
  }
}
