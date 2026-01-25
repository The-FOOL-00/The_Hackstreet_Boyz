/// Buddy Circle Screen
///
/// Displays matched contacts with online status for game invitations.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/buddy_list_provider.dart';
import '../providers/invite_provider.dart';
import '../services/contact_service.dart';
import '../widgets/invite_modal.dart';
import 'user_search_screen.dart';

class BuddyCircleScreen extends StatefulWidget {
  const BuddyCircleScreen({super.key});

  @override
  State<BuddyCircleScreen> createState() => _BuddyCircleScreenState();
}

class _BuddyCircleScreenState extends State<BuddyCircleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BuddyListProvider>().loadBuddies();
    });
  }

  void _showGameTypeDialog(Buddy buddy) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _GameTypeSelector(
        buddy: buddy,
        onGameSelected: (gameType) {
          Navigator.pop(context);
          _sendInvite(buddy, gameType);
        },
      ),
    );
  }

  Future<void> _sendInvite(Buddy buddy, String gameType) async {
    final inviteProvider = context.read<InviteProvider>();

    final invite = await inviteProvider.sendInvite(
      receiverId: buddy.uid,
      gameType: gameType,
    );

    if (invite != null && mounted) {
      _showWaitingDialog(buddy, invite.inviteId);
    }
  }

  void _showWaitingDialog(Buddy buddy, String inviteId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _WaitingForResponseDialog(
        buddy: buddy,
        inviteId: inviteId,
        onCancel: () {
          context.read<InviteProvider>().cancelInvite();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Buddy Circle',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3B36),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3B36)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Add search button
          IconButton(
            icon: const Icon(Icons.person_add, color: Color(0xFF6B9080)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserSearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6B9080)),
            onPressed: () {
              context.read<BuddyListProvider>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<BuddyListProvider>(
        builder: (context, buddyProvider, child) {
          // Check for incoming invites
          _checkIncomingInvites();

          if (buddyProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B9080)),
            );
          }

          if (!buddyProvider.hasPermission) {
            return _buildPermissionRequest(buddyProvider);
          }

          if (buddyProvider.error != null) {
            return _buildErrorState(buddyProvider);
          }

          if (!buddyProvider.hasBuddies) {
            return _buildEmptyState();
          }

          return _buildBuddyList(buddyProvider);
        },
      ),
    );
  }

  void _checkIncomingInvites() {
    final inviteProvider = context.read<InviteProvider>();
    if (inviteProvider.currentInvite != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              InviteModal(invite: inviteProvider.currentInvite!),
        );
      });
    }
  }

  Widget _buildPermissionRequest(BuddyListProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0ED),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.contacts,
                size: 50,
                color: Color(0xFF6B9080),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Access Your Contacts',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3B36),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To find friends who also use Luscid, we need access to your contacts.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF5C6B66),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final granted = await provider.requestPermission();
                  if (granted) {
                    provider.loadBuddies();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B9080),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Allow Access',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuddyListProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3B36),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              style: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                provider.clearError();
                provider.loadBuddies();
              },
              child: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF6B9080),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0ED),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.people_outline,
                size: 50,
                color: Color(0xFF6B9080),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No Buddies Yet',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3B36),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'None of your contacts are using Luscid yet. Invite them to join!',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF5C6B66),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Share app invite
                },
                icon: const Icon(Icons.share),
                label: Text(
                  'Invite Friends',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6B9080),
                  side: const BorderSide(color: Color(0xFF6B9080), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuddyList(BuddyListProvider provider) {
    final onlineBuddies = provider.onlineBuddies;
    final offlineBuddies = provider.offlineBuddies;

    return RefreshIndicator(
      onRefresh: provider.refresh,
      color: const Color(0xFF6B9080),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Online section
          if (onlineBuddies.isNotEmpty) ...[
            _buildSectionHeader('Online Now', onlineBuddies.length),
            const SizedBox(height: 12),
            ...onlineBuddies.map((buddy) => _buildBuddyCard(buddy, true)),
            const SizedBox(height: 24),
          ],

          // Offline section
          if (offlineBuddies.isNotEmpty) ...[
            _buildSectionHeader('Offline', offlineBuddies.length),
            const SizedBox(height: 12),
            ...offlineBuddies.map((buddy) => _buildBuddyCard(buddy, false)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: title == 'Online Now' ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5C6B66),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0ED),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B9080),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBuddyCard(Buddy buddy, bool isOnline) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isOnline ? () => _showGameTypeDialog(buddy) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar with status indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE8F0ED),
                    backgroundImage: buddy.photoUrl != null
                        ? NetworkImage(buddy.photoUrl!)
                        : null,
                    child: buddy.photoUrl == null
                        ? Text(
                            buddy.displayName[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6B9080),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Name and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buddy.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D3B36),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOnline
                          ? 'Available to play'
                          : _getLastActiveText(buddy.lastActive),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isOnline
                            ? Colors.green.shade700
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),

              // Play button
              if (isOnline)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B9080),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                )
              else
                Icon(Icons.access_time, color: Colors.grey.shade400, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _getLastActiveText(DateTime lastActive) {
    final difference = DateTime.now().difference(lastActive);

    if (difference.inMinutes < 5) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'Long time ago';
    }
  }
}

// Game type selector bottom sheet
class _GameTypeSelector extends StatelessWidget {
  final Buddy buddy;
  final Function(String) onGameSelected;

  const _GameTypeSelector({required this.buddy, required this.onGameSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Play with ${buddy.displayName}',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3B36),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a game',
            style: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
          ),
          const SizedBox(height: 24),

          // Game options
          _buildGameOption(
            context,
            icon: Icons.grid_view,
            title: 'Memory Match',
            description: 'Classic card matching game',
            gameType: 'memory',
          ),
          const SizedBox(height: 12),
          _buildGameOption(
            context,
            icon: Icons.shopping_cart,
            title: 'Shopping List',
            description: 'Remember and find items together',
            gameType: 'shopping_list',
          ),
          const SizedBox(height: 12),
          _buildGameOption(
            context,
            icon: Icons.movie,
            title: 'Cinema Connect',
            description: 'Solve movie puzzles together',
            gameType: 'cinema_connect',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGameOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String gameType,
  }) {
    return InkWell(
      onTap: () => onGameSelected(gameType),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5F2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6B9080),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3B36),
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF5C6B66),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF6B9080)),
          ],
        ),
      ),
    );
  }
}

// Waiting for response dialog
class _WaitingForResponseDialog extends StatelessWidget {
  final Buddy buddy;
  final String inviteId;
  final VoidCallback onCancel;

  const _WaitingForResponseDialog({
    required this.buddy,
    required this.inviteId,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<InviteProvider>(
      builder: (context, inviteProvider, child) {
        final invite = inviteProvider.pendingOutgoingInvite;

        // Check if invite was accepted
        if (invite != null && invite.isAccepted && invite.roomCode != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pop(context);
            // Navigate to game
            Navigator.pushNamed(
              context,
              '/shopping-game',
              arguments: {'roomCode': invite.roomCode},
            );
          });
        }

        // Check if invite was declined
        if (invite != null && invite.isDeclined) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${buddy.displayName} declined the invite'),
                backgroundColor: Colors.orange,
              ),
            );
          });
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const CircularProgressIndicator(color: Color(0xFF6B9080)),
              const SizedBox(height: 24),
              Text(
                'Calling ${buddy.displayName}...',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3B36),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Waiting for response',
                style: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
