/// Voice Chat Overlay Widget - Stitch Design Floating Controls
///
/// Large, accessible controls for seniors with Stitch design theme.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import 'voice_chat_service.dart';

/// Floating voice chat overlay for game screens - Stitch Design
class VoiceChatOverlay extends StatelessWidget {
  /// Position in the Stack
  final Alignment position;

  /// Padding from screen edges
  final EdgeInsets padding;

  const VoiceChatOverlay({
    super.key,
    this.position = Alignment.bottomRight,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceChatService>(
      builder: (context, voiceChat, child) {
        return Align(
          alignment: position,
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Connection status indicator
                _buildStatusIndicator(voiceChat),
                const SizedBox(height: 12),
                // Mute/Unmute button
                _buildMuteButton(context, voiceChat),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(VoiceChatService voiceChat) {
    final isConnected = voiceChat.isConnected;
    final peerCount = voiceChat.peerCount;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isConnected
            ? AppColors.accentGreen.withOpacity(0.95)
            : AppColors.textSecondary.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? AppColors.accentGreen.withOpacity(0.3)
              : Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isConnected
                ? AppColors.accentGreen.withOpacity(0.25)
                : Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isConnected ? '$peerCount connected' : 'Disconnected',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuteButton(BuildContext context, VoiceChatService voiceChat) {
    final isMuted = voiceChat.isMuted;
    final isConnected = voiceChat.isConnected;

    return GestureDetector(
      onTap: isConnected ? voiceChat.toggleMute : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: !isConnected
              ? null
              : LinearGradient(
                  colors: isMuted
                      ? [AppColors.error, AppColors.error.withOpacity(0.8)]
                      : [AppColors.accentGreen, const Color(0xFF6FCF97)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: !isConnected ? AppColors.textSecondary.withOpacity(0.6) : null,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: !isConnected
                  ? Colors.black.withOpacity(0.15)
                  : isMuted
                      ? AppColors.error.withOpacity(0.35)
                      : AppColors.accentGreen.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              isMuted ? 'Muted' : 'On',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stitch Design - Compact inline mic button for header areas
class StitchMicButton extends StatelessWidget {
  final VoiceChatService voiceChat;
  final double size;

  const StitchMicButton({
    super.key,
    required this.voiceChat,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isMuted = voiceChat.isMuted;
    final isConnected = voiceChat.isConnected;

    return GestureDetector(
      onTap: isConnected ? voiceChat.toggleMute : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: !isConnected
              ? null
              : LinearGradient(
                  colors: isMuted
                      ? [AppColors.error, AppColors.error.withOpacity(0.8)]
                      : [AppColors.accentGreen, const Color(0xFF6FCF97)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: !isConnected ? AppColors.borderBlue : null,
          border: Border.all(
            color: !isConnected
                ? AppColors.borderBlue
                : Colors.white.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: !isConnected
                  ? AppColors.shadowSoft
                  : isMuted
                      ? AppColors.error.withOpacity(0.25)
                      : AppColors.accentGreen.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          !isConnected
              ? Icons.mic_off_rounded
              : isMuted
                  ? Icons.mic_off_rounded
                  : Icons.mic_rounded,
          color: !isConnected ? AppColors.textSecondary : Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}

/// Stitch Design - Full voice chat card for settings/lobby
class VoiceChatCard extends StatelessWidget {
  final VoiceChatService voiceChat;

  const VoiceChatCard({super.key, required this.voiceChat});

  @override
  Widget build(BuildContext context) {
    final isConnected = voiceChat.isConnected;
    final isMuted = voiceChat.isMuted;
    final state = voiceChat.state;
    final peerCount = voiceChat.peerCount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderBlue),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isConnected
                      ? AppColors.accentGreen.withOpacity(0.12)
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isConnected
                      ? Icons.headset_mic_rounded
                      : Icons.headset_rounded,
                  color:
                      isConnected ? AppColors.accentGreen : AppColors.primaryBlue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice Chat',
                      style: AppTextStyles.cardTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isConnected
                            ? AppColors.accentGreen.withOpacity(0.1)
                            : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isConnected
                            ? '$peerCount peer${peerCount != 1 ? 's' : ''} connected'
                            : 'Not connected',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isConnected
                              ? AppColors.accentGreen
                              : AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Connect/Disconnect button
              _buildConnectButton(context, state, isConnected),
            ],
          ),
          // Mic control row when connected
          if (isConnected) ...[
            const SizedBox(height: 20),
            Container(height: 1, color: AppColors.borderBlue),
            const SizedBox(height: 20),
            _buildMicToggle(isMuted),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectButton(
      BuildContext context, VoiceChatState state, bool isConnected) {
    final isLoading = state == VoiceChatState.connecting;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () {
              if (isConnected) {
                voiceChat.leaveRoom();
              } else {
                voiceChat.joinRoom();
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: isConnected
              ? null
              : const LinearGradient(
                  colors: [AppColors.primaryBlue, Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isConnected ? AppColors.error.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(14),
          border: isConnected
              ? Border.all(color: AppColors.error.withOpacity(0.3))
              : null,
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    isConnected ? AppColors.error : Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isConnected ? Icons.call_end_rounded : Icons.call_rounded,
                    color: isConnected ? AppColors.error : Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? 'Leave' : 'Join',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isConnected ? AppColors.error : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMicToggle(bool isMuted) {
    return GestureDetector(
      onTap: voiceChat.toggleMute,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: isMuted
              ? null
              : LinearGradient(
                  colors: [AppColors.accentGreen, const Color(0xFF6FCF97)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isMuted ? AppColors.error.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(16),
          border: isMuted
              ? Border.all(color: AppColors.error.withOpacity(0.3))
              : Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: isMuted
                  ? AppColors.error.withOpacity(0.15)
                  : AppColors.accentGreen.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isMuted
                    ? AppColors.error.withOpacity(0.15)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                color: isMuted ? AppColors.error : Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              isMuted ? 'Tap to Unmute' : 'Microphone On',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isMuted ? AppColors.error : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              isMuted ? Icons.touch_app_rounded : Icons.volume_up_rounded,
              color: isMuted
                  ? AppColors.error.withOpacity(0.6)
                  : Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Stitch Design - Compact voice chat button for smaller spaces
class VoiceChatButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const VoiceChatButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceChatService>(
      builder: (context, voiceChat, child) {
        final isMuted = voiceChat.isMuted;
        final isConnected = voiceChat.isConnected;

        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: !isConnected
                ? AppColors.backgroundWhite
                : isMuted
                    ? AppColors.error.withOpacity(0.1)
                    : AppColors.accentGreen.withOpacity(0.1),
            border: Border.all(
              color: !isConnected
                  ? AppColors.borderBlue
                  : isMuted
                      ? AppColors.error.withOpacity(0.3)
                      : AppColors.accentGreen.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            onPressed: isConnected ? voiceChat.toggleMute : null,
            icon: Icon(
              isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: !isConnected
                  ? AppColors.textSecondary
                  : isMuted
                      ? AppColors.error
                      : AppColors.accentGreen,
            ),
            iconSize: 24,
            tooltip: isMuted ? 'Unmute' : 'Mute',
          ),
        );
      },
    );
  }
}

/// Voice chat connection button - Stitch Design
class VoiceChatConnectButton extends StatelessWidget {
  const VoiceChatConnectButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceChatService>(
      builder: (context, voiceChat, child) {
        final state = voiceChat.state;
        final isConnected = voiceChat.isConnected;
        final isLoading = state == VoiceChatState.connecting;

        return GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  if (isConnected) {
                    voiceChat.leaveRoom();
                  } else {
                    voiceChat.joinRoom();
                  }
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: isConnected
                  ? null
                  : const LinearGradient(
                      colors: [AppColors.primaryBlue, Color(0xFF60A5FA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: isConnected ? AppColors.error.withOpacity(0.1) : null,
              borderRadius: BorderRadius.circular(16),
              border: isConnected
                  ? Border.all(color: AppColors.error.withOpacity(0.3))
                  : null,
              boxShadow: [
                BoxShadow(
                  color: isConnected
                      ? AppColors.error.withOpacity(0.15)
                      : AppColors.primaryBlue.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        isConnected ? AppColors.error : Colors.white,
                      ),
                    ),
                  )
                else
                  Icon(
                    isConnected ? Icons.call_end_rounded : Icons.call_rounded,
                    color: isConnected ? AppColors.error : Colors.white,
                    size: 22,
                  ),
                const SizedBox(width: 10),
                Text(
                  isLoading
                      ? 'Connecting...'
                      : isConnected
                          ? 'Leave Chat'
                          : 'Join Voice Chat',
                  style: AppTextStyles.buttonMedium.copyWith(
                    color: isConnected ? AppColors.error : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
