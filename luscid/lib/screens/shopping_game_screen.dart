/// Shopping List Game Screen
///
/// Co-op memory game where players memorize and find shopping items.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../providers/shopping_list_provider.dart';
import '../services/shopping_list_service.dart';
import '../voice_chat/voice_chat_service.dart';

class ShoppingGameScreen extends StatefulWidget {
  const ShoppingGameScreen({super.key});

  @override
  State<ShoppingGameScreen> createState() => _ShoppingGameScreenState();
}

class _ShoppingGameScreenState extends State<ShoppingGameScreen> {
  VoiceChatService? _voiceChat;
  bool _voiceChatInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
      _tryInitVoiceChat();
    });
  }

  void _initializeGame() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final roomCode = args?['roomCode'] as String?;

    if (roomCode != null) {
      // Join existing room
      context.read<ShoppingListProvider>().joinRoom(roomCode);
    }
  }

  void _tryInitVoiceChat() {
    if (_voiceChatInitialized) return;
    
    final provider = context.read<ShoppingListProvider>();
    final room = provider.room;
    final currentUserId = provider.currentUserId;
    
    // Check if this is a multiplayer game (has guest) or we're waiting for guest
    final isMultiplayerRoom = room != null && room.guestId != null;
    
    debugPrint('[ShoppingGame] Voice chat try init: hasRoom=${room != null}, hasGuest=${room?.guestId != null}, userId=$currentUserId');
    
    if (isMultiplayerRoom && currentUserId != null) {
      _voiceChat = VoiceChatService(
        roomId: 'shopping_${room.roomCode}',
        userId: currentUserId,
        userName: 'Player',
      );
      _voiceChat!.joinRoom();
      _voiceChat!.addListener(_onVoiceChatChanged);
      _voiceChatInitialized = true;
      debugPrint('[ShoppingGame] Voice chat service created and joined!');
    } else {
      debugPrint('[ShoppingGame] Voice chat NOT initialized yet - waiting for multiplayer conditions');
    }
  }

  void _onVoiceChatChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _voiceChat?.removeListener(_onVoiceChatChanged);
    _voiceChat?.leaveRoom();
    _voiceChat?.dispose();
    super.dispose();
  }

  Widget _buildVoiceChatButton() {
    final isConnected = _voiceChat?.isConnected ?? false;
    final isMuted = _voiceChat?.isMuted ?? true;

    // Larger, accessible floating mic button for seniors
    return SizedBox(
      width: 72,
      height: 72,
      child: ElevatedButton(
        onPressed: isConnected ? () => _voiceChat?.toggleMute() : null,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: !isConnected
              ? AppColors.backgroundWhite
              : isMuted
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFE8F5E9),
          elevation: 8,
          padding: EdgeInsets.zero,
        ),
        child: Icon(
          isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          size: 36,
          color: !isConnected
              ? AppColors.textSecondary
              : isMuted
                  ? const Color(0xFFE53935)
                  : const Color(0xFF4CAF50),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Consumer<ShoppingListProvider>(
        builder: (context, provider, child) {
          // Try to init voice chat when provider updates (guest joins)
          if (!_voiceChatInitialized && provider.room?.guestId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _tryInitVoiceChat();
            });
          }
          
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          if (provider.error != null) {
            return _buildErrorState(provider);
          }

          // Wrap content in Stack to add close button
          Widget phaseContent;
          switch (provider.phase) {
            case ShoppingGamePhase.waiting:
              phaseContent = _WaitingPhase(provider: provider);
              break;
            case ShoppingGamePhase.memorize:
              phaseContent = _MemorizePhase(provider: provider);
              break;
            case ShoppingGamePhase.selection:
              phaseContent = _SelectionPhase(provider: provider);
              break;
            case ShoppingGamePhase.results:
            case ShoppingGamePhase.finished:
              phaseContent = _ResultsPhase(provider: provider);
              break;
          }

          // Don't show exit button on results phase
          if (provider.phase == ShoppingGamePhase.results ||
              provider.phase == ShoppingGamePhase.finished) {
            return phaseContent;
          }

          return Stack(
            children: [
              phaseContent,
              // Exit button positioned at top-left
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderBlue),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowSoft,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textPrimary,
                    onPressed: () => _showExitConfirmation(context, provider),
                  ),
                ),
              ),
              // Voice chat button for multiplayer (bottom center)
              if (provider.isMultiplayer)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 24,
                  child: Center(
                    child: _buildVoiceChatButton(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showExitConfirmation(BuildContext context, ShoppingListProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.backgroundWhite,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🚪', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Text('Leave Game?', style: AppTextStyles.heading4),
          ],
        ),
        content: Text(
          'Are you sure you want to leave? Your progress will be lost.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.borderBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Stay',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    provider.leaveRoom();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Leave',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ShoppingListProvider provider) {
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
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!,
              style: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B9080),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

// Waiting phase widget
class _WaitingPhase extends StatelessWidget {
  final ShoppingListProvider provider;

  const _WaitingPhase({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0ED),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.shopping_cart,
                size: 60,
                color: Color(0xFF6B9080),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Shopping List Challenge',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3B36),
              ),
            ),
            const SizedBox(height: 16),
            if (provider.room != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Room Code',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF5C6B66),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.room!.roomCode,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: const Color(0xFF6B9080),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (provider.room!.guestId != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Partner joined!',
                        style: GoogleFonts.poppins(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (provider.isHost)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => provider.startGame(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B9080),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Start Game',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    'Waiting for host to start...',
                    style: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
                  ),
              ] else ...[
                const CircularProgressIndicator(color: Color(0xFF6B9080)),
                const SizedBox(height: 16),
                Text(
                  'Waiting for partner...',
                  style: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// Memorize phase widget
class _MemorizePhase extends StatelessWidget {
  final ShoppingListProvider provider;

  const _MemorizePhase({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header with timer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFF6B9080)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Memorize the items!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${provider.timeRemaining}s',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Target items grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: provider.targetItems.length,
                itemBuilder: (context, index) {
                  final item = provider.targetItems[index];
                  return _ShoppingItemCard(
                    item: item,
                    showEmoji: true,
                    isSelectable: false,
                    isSelected: false,
                  );
                },
              ),
            ),
          ),

          // Instruction
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFF6B9080)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Remember these ${provider.targetItems.length} items. You\'ll need to find them in the next phase!',
                    style: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Selection phase widget
class _SelectionPhase extends StatelessWidget {
  final ShoppingListProvider provider;

  const _SelectionPhase({required this.provider});

  @override
  Widget build(BuildContext context) {
    final selectedCount = provider.allItems.where((i) => i.isSelected).length;
    final targetCount = provider.targetItems.length;

    return SafeArea(
      child: Column(
        children: [
          // Header with timer and score
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Color(0xFF6B9080)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Find the items!',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: provider.timeRemaining < 10
                            ? Colors.red.withOpacity(0.5)
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${provider.timeRemaining}s',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar
                LinearProgressIndicator(
                  value: selectedCount / targetCount,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected: $selectedCount / $targetCount items',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),

          // Items grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: provider.allItems.length,
                itemBuilder: (context, index) {
                  final item = provider.allItems[index];
                  return _ShoppingItemCard(
                    item: item,
                    showEmoji: true,
                    isSelectable: true,
                    isSelected: item.isSelected,
                    onTap: () => provider.toggleItem(item.id),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Results phase widget
class _ResultsPhase extends StatelessWidget {
  final ShoppingListProvider provider;

  const _ResultsPhase({required this.provider});

  @override
  Widget build(BuildContext context) {
    final scoreData = provider.getFinalScore();
    final correct = scoreData['correct'] as int? ?? 0;
    final incorrect = scoreData['incorrect'] as int? ?? 0;
    final missed = scoreData['missed'] as int? ?? 0;
    final total = scoreData['total'] as int? ?? 0;
    final accuracy = scoreData['accuracy'] as double? ?? 0.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Trophy/result icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: accuracy >= 80
                    ? Colors.green.shade100
                    : accuracy >= 50
                    ? Colors.orange.shade100
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                accuracy >= 80
                    ? Icons.emoji_events
                    : accuracy >= 50
                    ? Icons.thumb_up
                    : Icons.refresh,
                size: 60,
                color: accuracy >= 80
                    ? Colors.green
                    : accuracy >= 50
                    ? Colors.orange
                    : Colors.red,
              ),
            ),

            const SizedBox(height: 24),

            // Result message
            Text(
              accuracy >= 80
                  ? 'Excellent!'
                  : accuracy >= 50
                  ? 'Good Job!'
                  : 'Keep Practicing!',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3B36),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${accuracy.toStringAsFixed(0)}% Accuracy',
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: const Color(0xFF6B9080),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 32),

            // Score breakdown
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  _buildScoreRow(
                    'Correct',
                    '$correct / $total',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  const Divider(height: 24),
                  _buildScoreRow(
                    'Incorrect',
                    '$incorrect',
                    Icons.cancel,
                    Colors.red,
                  ),
                  const Divider(height: 24),
                  _buildScoreRow(
                    'Missed',
                    '$missed',
                    Icons.help_outline,
                    Colors.orange,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      provider.leaveRoom();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF6B9080)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Exit',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B9080),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      provider.leaveRoom();
                      Navigator.pushReplacementNamed(context, '/buddy-circle');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B9080),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Play Again',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF5C6B66),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3B36),
          ),
        ),
      ],
    );
  }
}

// Shopping item card widget
class _ShoppingItemCard extends StatelessWidget {
  final ShoppingItem item;
  final bool showEmoji;
  final bool isSelectable;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ShoppingItemCard({
    required this.item,
    required this.showEmoji,
    required this.isSelectable,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelectable ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6B9080).withOpacity(0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6B9080)
                : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6B9080).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.name,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2D3B36),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFF6B9080),
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
