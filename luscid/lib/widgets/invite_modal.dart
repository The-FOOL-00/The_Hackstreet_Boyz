/// Invite Modal Widget
///
/// Shows incoming game invitations with accept/decline options.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/invite_service.dart';
import '../services/shopping_list_service.dart';
import '../providers/invite_provider.dart';

class InviteModal extends StatefulWidget {
  final GameInvite invite;

  const InviteModal({super.key, required this.invite});

  @override
  State<InviteModal> createState() => _InviteModalState();
}

class _InviteModalState extends State<InviteModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String get _gameTypeDisplay {
    switch (widget.invite.gameType) {
      case 'memory':
        return 'Memory Match';
      case 'shopping_list':
        return 'Shopping List';
      case 'cinema_connect':
        return 'Cinema Connect';
      default:
        return 'Game';
    }
  }

  IconData get _gameTypeIcon {
    switch (widget.invite.gameType) {
      case 'memory':
        return Icons.grid_view;
      case 'shopping_list':
        return Icons.shopping_cart;
      case 'cinema_connect':
        return Icons.movie;
      default:
        return Icons.games;
    }
  }

  Future<void> _acceptInvite() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final inviteProvider = context.read<InviteProvider>();

      // Create or join room based on game type
      String? roomCode;

      if (widget.invite.gameType == 'shopping_list') {
        final shoppingService = ShoppingListService();
        final room = await shoppingService.joinRoom(
          roomCode: widget.invite.roomCode ?? '',
          guestId: widget.invite.receiverId,
        );
        roomCode = room?.roomCode;
      } else {
        // For other games, use the provided room code
        roomCode =
            widget.invite.roomCode ??
            'GAME${DateTime.now().millisecondsSinceEpoch}';
      }

      if (roomCode != null) {
        final updatedInvite = await inviteProvider.acceptInvite(
          inviteId: widget.invite.inviteId,
          roomCode: roomCode,
        );

        if (mounted && updatedInvite != null) {
          Navigator.pop(context);

          // Navigate to appropriate game screen
          if (widget.invite.gameType == 'shopping_list') {
            Navigator.pushNamed(
              context,
              '/shopping-game',
              arguments: {'roomCode': roomCode},
            );
          } else {
            Navigator.pushNamed(
              context,
              '/multiplayer-setup',
              arguments: {'roomCode': roomCode},
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _declineInvite() async {
    final inviteProvider = context.read<InviteProvider>();
    await inviteProvider.declineInvite(widget.invite.inviteId);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(scale: _scaleAnimation, child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated call indicator
              _buildCallIndicator(),

              const SizedBox(height: 24),

              // Sender name
              Text(
                widget.invite.senderName,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3B36),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Invite message
              Text(
                'is calling you to play',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF5C6B66),
                ),
              ),

              const SizedBox(height: 16),

              // Game type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0ED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _gameTypeIcon,
                      size: 20,
                      color: const Color(0xFF6B9080),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _gameTypeDisplay,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B9080),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  // Decline button
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _declineInvite,
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: Text(
                          'Decline',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Accept button
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _acceptInvite,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check, color: Colors.white),
                        label: Text(
                          'Accept',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B9080),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring
            Container(
              width: 100 + (20 * value),
              height: 100 + (20 * value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6B9080).withOpacity(0.1 * (1 - value)),
              ),
            ),
            // Middle pulse ring
            Container(
              width: 90 + (15 * value),
              height: 90 + (15 * value),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6B9080).withOpacity(0.2 * (1 - value)),
              ),
            ),
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF6B9080),
              child: Text(
                widget.invite.senderName[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            // Phone icon badge
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.videogame_asset,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Quick invite notification banner
class InviteNotificationBanner extends StatelessWidget {
  final GameInvite invite;
  final VoidCallback onTap;

  const InviteNotificationBanner({
    super.key,
    required this.invite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF6B9080),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B9080).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(
                invite.senderName[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${invite.senderName} is calling!',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Tap to respond',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
