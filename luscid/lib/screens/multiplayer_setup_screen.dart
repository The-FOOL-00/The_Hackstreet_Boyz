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

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        // If room is ready and has both players, start the game
        if (gameProvider.room != null &&
            gameProvider.room!.isFull &&
            gameProvider.room!.status.name == 'playing') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const GameScreen()),
            );
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
              child: _createdRoomCode != null
                  ? _buildWaitingForPlayer(gameProvider)
                  : _buildSetup(gameProvider),
            ),
          ),
        );
      },
    );
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

  Widget _buildWaitingForPlayer(GameProvider gameProvider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⏳', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          Text(
            'Waiting for Player...',
            style: AppTextStyles.heading3,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Room code display
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                Text(_createdRoomCode ?? '', style: AppTextStyles.roomCode),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _createdRoomCode!));
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
          const SizedBox(height: 24),
          Text(
            'Share this code with your friend!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          LargeButton(
            text: 'Cancel',
            isPrimary: false,
            onPressed: () {
              gameProvider.leaveRoom();
              setState(() {
                _createdRoomCode = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _createRoom(GameProvider gameProvider) async {
    // First select difficulty
    final difficulty = await Navigator.of(context).push<GameDifficulty>(
      MaterialPageRoute(
        builder: (_) => const DifficultySelectScreen(isMultiplayer: true),
      ),
    );

    if (difficulty == null) return;

    final roomCode = await gameProvider.createRoom(difficulty);

    if (roomCode != null) {
      setState(() {
        _createdRoomCode = roomCode;
      });
    } else {
      setState(() {
        _error = gameProvider.error ?? 'Failed to create room';
      });
    }
  }

  void _onRoomUpdate() {
    // No longer needed - GameProvider handles the subscription
  }

  Future<void> _joinRoom(GameProvider gameProvider) async {
    final success = await gameProvider.joinRoom(_roomCode);

    if (!success) {
      setState(() {
        _error = gameProvider.error ?? 'Failed to join room';
        _roomCode = '';
      });
    }
    // If successful, the game will start automatically via the subscription
  }
}
