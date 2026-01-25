/// Multiplayer setup screen
///
/// Allows users to create or join a multiplayer room.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/constants/game_icons.dart';
import '../models/game_room_model.dart';
import '../providers/game_provider.dart';
import '../widgets/large_button.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/loading_overlay.dart';
import 'difficulty_select_screen.dart';
import 'game_screen.dart';

class MultiplayerSetupScreen extends StatefulWidget {
  const MultiplayerSetupScreen({super.key});

  @override
  State<MultiplayerSetupScreen> createState() => _MultiplayerSetupScreenState();
}

class _MultiplayerSetupScreenState extends State<MultiplayerSetupScreen> {
  bool _isCreating = true;
  String _roomCode = '';
  String? _error;
  String? _createdRoomCode;
  bool _hasJoined = false; // Track if guest has successfully joined
  bool _navigationScheduled = false; // Prevent duplicate navigation
  bool _isDisposed = false; // Track if widget is disposed

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final room = gameProvider.room;
        debugPrint(
          '[MultiplayerSetup] Build: room=${room?.roomCode}, status=${room?.status}, cards=${room?.cards.length ?? 0}',
        );

        // Navigate to game when room is playing and has cards
        if (room != null &&
            room.status == GameRoomStatus.playing &&
            room.cards.isNotEmpty &&
            !_navigationScheduled) {
          _navigationScheduled = true;
          debugPrint('[MultiplayerSetup] Scheduling navigation to GameScreen!');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_isDisposed) {
              debugPrint('[MultiplayerSetup] Navigating now!');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const GameScreen()),
              );
            }
          });
        }

        return LoadingOverlay(
          isLoading: gameProvider.isLoading,
          message: _isCreating ? 'Creating room...' : 'Joining room...',
          child: Scaffold(
            backgroundColor: AppColors.backgroundBeige,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  gameProvider.leaveRoom();
                  Navigator.of(context).pop();
                },
              ),
              title: Text('Play Together', style: AppTextStyles.heading4),
            ),
            body: SafeArea(
              child: _shouldShowWaitingScreen(gameProvider)
                  ? _buildWaitingScreen(gameProvider)
                  : _buildSetup(gameProvider),
            ),
          ),
        );
      },
    );
  }

  bool _shouldShowWaitingScreen(GameProvider gameProvider) {
    // Show waiting screen if:
    // 1. We have explicitly set _createdRoomCode (host created room)
    // 2. We have joined as guest (_hasJoined)
    // 3. Provider has a room in waiting status and we haven't joined (handles race condition)
    final room = gameProvider.room;
    final hasRoomInWaiting = room != null && 
                             room.status == GameRoomStatus.waiting && 
                             !_hasJoined; // If not joined, we must be the host
    
    final result = _createdRoomCode != null || _hasJoined || hasRoomInWaiting;
    debugPrint('[MultiplayerSetup] _shouldShowWaitingScreen: result=$result, _createdRoomCode=$_createdRoomCode, _hasJoined=$_hasJoined, hasRoomInWaiting=$hasRoomInWaiting, room.code=${room?.roomCode}, room.status=${room?.status}');
    return result;
  }

  Widget _buildSetup(GameProvider gameProvider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Toggle buttons
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isCreating = true;
                      _roomCode = '';
                      _error = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _isCreating
                            ? AppColors.primaryBlue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Create Room',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: _isCreating
                              ? AppColors.textOnPrimary
                              : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _isCreating = false;
                      _roomCode = '';
                      _error = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: !_isCreating
                            ? AppColors.primaryBlue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Join Room',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: !_isCreating
                              ? AppColors.textOnPrimary
                              : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Content
          Expanded(
            child: _isCreating
                ? _buildCreateRoom(gameProvider)
                : _buildJoinRoom(gameProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateRoom(GameProvider gameProvider) {
    return Column(
      children: [
        const Text('👥', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 24),
        Text(
          'Invite Someone to Play',
          style: AppTextStyles.heading3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Create a room and share the code with a friend or family member.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(),
        LargeButton(
          text: 'Create Room',
          emoji: '🎮',
          onPressed: () => _createRoom(gameProvider),
        ),
      ],
    );
  }

  Widget _buildJoinRoom(GameProvider gameProvider) {
    return Column(
      children: [
        Text(
          'Enter Room Code',
          style: AppTextStyles.heading3,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Ask your friend for the 4-digit room code.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Error message
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error),
            ),
            child: Text(
              _error!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Room code input
        NumericKeypad(
          currentValue: _roomCode,
          onDigitPressed: (digit) {
            if (_roomCode.length < 4) {
              setState(() {
                _roomCode += digit;
                _error = null;
              });
              if (_roomCode.length == 4) {
                _joinRoom(gameProvider);
              }
            }
          },
          onBackspace: () {
            if (_roomCode.isNotEmpty) {
              setState(() {
                _roomCode = _roomCode.substring(0, _roomCode.length - 1);
                _error = null;
              });
            }
          },
          onClear: () {
            setState(() {
              _roomCode = '';
              _error = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildWaitingScreen(GameProvider gameProvider) {
    final room = gameProvider.room;
    // Use local room code if set, otherwise use provider's room code (handles race condition)
    final displayRoomCode = _createdRoomCode ?? room?.roomCode;
    // We're the host if we have a room code and we haven't joined someone else's room
    final isHost = displayRoomCode != null && !_hasJoined;
    final hasGuest = room?.guestId != null;

    // Determine waiting message
    String waitingText;
    String subText;
    if (isHost && !hasGuest) {
      waitingText = 'Waiting for Player...';
      subText = 'Share this code with your friend!';
    } else if (isHost && hasGuest) {
      waitingText = 'Player Joined!';
      subText = 'Starting game...';
    } else {
      waitingText = 'Joined Room!';
      subText = 'Waiting for host to start the game...';
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(hasGuest ? '🎮' : '⏳', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(
            waitingText,
            style: AppTextStyles.heading3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Room code display (for host)
          if (isHost)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Room Code',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(displayRoomCode, style: AppTextStyles.roomCode),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: displayRoomCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Code'),
                  ),
                ],
              ),
            ),
          // Room info for guest
          if (_hasJoined && !isHost)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Room ${room?.roomCode ?? _roomCode}',
                    style: AppTextStyles.heading4,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text(
            subText,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          // Start Game button (host only, when guest joined)
          if (isHost && hasGuest)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: LargeButton(
                text: 'Start Game',
                emoji: '🚀',
                onPressed: () async {
                  await gameProvider.startMultiplayerGame();
                },
              ),
            ),
          LargeButton(
            text: 'Cancel',
            isPrimary: false,
            onPressed: () {
              gameProvider.leaveRoom();
              setState(() {
                _createdRoomCode = null;
                _hasJoined = false;
                _roomCode = '';
                _navigationScheduled = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createRoom(GameProvider gameProvider) async {
    debugPrint('[MultiplayerSetup] _createRoom: Starting...');
    // First select difficulty
    final difficulty = await Navigator.of(context).push<GameDifficulty>(
      MaterialPageRoute(
        builder: (_) => const DifficultySelectScreen(isMultiplayer: true),
      ),
    );

    debugPrint('[MultiplayerSetup] _createRoom: Returned from difficulty selection, difficulty=$difficulty');
    if (difficulty == null) {
      debugPrint('[MultiplayerSetup] _createRoom: User cancelled');
      return;
    }

    debugPrint('[MultiplayerSetup] _createRoom: Calling gameProvider.createRoom...');
    final roomCode = await gameProvider.createRoom(difficulty);
    debugPrint('[MultiplayerSetup] _createRoom: createRoom returned, roomCode=$roomCode, provider.room=${gameProvider.room?.roomCode}');

    if (roomCode != null) {
      if (mounted) {
        debugPrint('[MultiplayerSetup] _createRoom: SUCCESS, setting _createdRoomCode=$roomCode');
        setState(() {
          _createdRoomCode = roomCode;
        });
        debugPrint('[MultiplayerSetup] _createRoom: setState complete');
      } else {
        debugPrint('[MultiplayerSetup] _createRoom: Widget not mounted');
      }
    } else {
      if (mounted) {
        debugPrint('[MultiplayerSetup] _createRoom: FAILED, error=${gameProvider.error}');
        setState(() {
          _error = gameProvider.error ?? 'Failed to create room';
        });
      } else {
        debugPrint('[MultiplayerSetup] _createRoom: Widget not mounted (error case)');
      }
    }
  }

  Future<void> _joinRoom(GameProvider gameProvider) async {
    final success = await gameProvider.joinRoom(_roomCode);

    if (success) {
      setState(() {
        _hasJoined = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = gameProvider.error ?? 'Failed to join room';
        _roomCode = '';
      });
    }
  }
}
