/// Shopping Multiplayer Setup Screen
///
/// Create or join shopping list game room with difficulty selection.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import 'shopping_game_screen.dart';
import 'game_mode_screen.dart';

class ShoppingMultiplayerSetupScreen extends StatefulWidget {
  const ShoppingMultiplayerSetupScreen({super.key});

  @override
  State<ShoppingMultiplayerSetupScreen> createState() =>
      _ShoppingMultiplayerSetupScreenState();
}

class _ShoppingMultiplayerSetupScreenState
    extends State<ShoppingMultiplayerSetupScreen> {
  bool _isCreating = true;
  String _roomCode = '';
  String? _error;
  String? _createdRoomCode;
  ShoppingDifficulty _selectedDifficulty = ShoppingDifficulty.medium;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      context.read<ShoppingListProvider>().init(userId);
    });
  }

  Map<String, int> _getDifficultySettings(ShoppingDifficulty difficulty) {
    switch (difficulty) {
      case ShoppingDifficulty.easy:
        return {'items': 6, 'memorizeTime': 45, 'selectionTime': 90};
      case ShoppingDifficulty.medium:
        return {'items': 8, 'memorizeTime': 30, 'selectionTime': 60};
      case ShoppingDifficulty.hard:
        return {'items': 12, 'memorizeTime': 20, 'selectionTime': 45};
    }
  }

  Future<void> _createRoom() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<ShoppingListProvider>();
    final settings = _getDifficultySettings(_selectedDifficulty);

    final roomCode = await provider.createRoom(
      targetItemCount: settings['items']!,
      memorizeTimeSeconds: settings['memorizeTime']!,
      selectionTimeSeconds: settings['selectionTime']!,
    );

    setState(() => _isLoading = false);

    if (roomCode != null) {
      setState(() => _createdRoomCode = roomCode);
    } else {
      setState(() => _error = provider.error ?? 'Failed to create room');
    }
  }

  Future<void> _joinRoom() async {
    final code = _roomCode.trim().toUpperCase();
    if (code.isEmpty || code.length != 4) {
      setState(() => _error = 'Please enter a valid 4-character room code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final provider = context.read<ShoppingListProvider>();
    final success = await provider.joinRoom(code);

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ShoppingGameScreen()),
      );
    } else {
      setState(() => _error = provider.error ?? 'Failed to join room');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3B36)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Shopping List - Multiplayer',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3B36),
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ShoppingListProvider>(
        builder: (context, provider, _) {
          // Check if game should start
          if (provider.room != null &&
              provider.room!.guestId != null &&
              _createdRoomCode != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ShoppingGameScreen()),
                );
              }
            });
          }

          if (_createdRoomCode != null) {
            return _buildWaitingScreen(provider);
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Toggle buttons
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton('Create Room', _isCreating, () {
                          setState(() {
                            _isCreating = true;
                            _roomCode = '';
                            _error = null;
                          });
                        }),
                        _buildTabButton('Join Room', !_isCreating, () {
                          setState(() {
                            _isCreating = false;
                            _roomCode = '';
                            _error = null;
                          });
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: GoogleFonts.poppins(
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Content
                  if (_isCreating)
                    _buildCreateSection()
                  else
                    _buildJoinSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6B9080) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF5C6B66),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateSection() {
    return Column(
      children: [
        const Text('🛒', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(
          'Create a Game Room',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3B36),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose difficulty and share the code with your friend',
          style: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Difficulty selection
        Text(
          'Select Difficulty',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3B36),
          ),
        ),
        const SizedBox(height: 16),
        _buildDifficultyOption(
          ShoppingDifficulty.easy,
          'Easy',
          '6 Items • 45s',
          '😊',
        ),
        const SizedBox(height: 12),
        _buildDifficultyOption(
          ShoppingDifficulty.medium,
          'Medium',
          '8 Items • 30s',
          '🤔',
        ),
        const SizedBox(height: 12),
        _buildDifficultyOption(
          ShoppingDifficulty.hard,
          'Hard',
          '12 Items • 20s',
          '😤',
        ),
        const SizedBox(height: 32),

        // Create button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createRoom,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B9080),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Create Room',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyOption(
    ShoppingDifficulty difficulty,
    String title,
    String subtitle,
    String emoji,
  ) {
    final isSelected = _selectedDifficulty == difficulty;
    return GestureDetector(
      onTap: () => setState(() => _selectedDifficulty = difficulty),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F0ED) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B9080) : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
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
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF5C6B66),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF6B9080)),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinSection() {
    return Column(
      children: [
        const Text('🔗', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(
          'Join a Game',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3B36),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 4-character room code',
          style: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
        ),
        const SizedBox(height: 32),

        // Room code input
        TextField(
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          maxLength: 4,
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 12,
          ),
          onChanged: (value) => setState(() {
            _roomCode = value;
            _error = null;
          }),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'ABCD',
            hintStyle: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 12,
              color: Colors.grey.shade300,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Join button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading || _roomCode.length != 4 ? null : _joinRoom,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B9080),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Join Room',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingScreen(ShoppingListProvider provider) {
    final room = provider.room;
    final hasGuest = room?.guestId != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(hasGuest ? '🎮' : '⏳', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text(
              hasGuest ? 'Player Joined!' : 'Waiting for Player...',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3B36),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasGuest
                  ? 'Starting game...'
                  : 'Share this code with your friend',
              style: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
            ),
            const SizedBox(height: 32),

            // Room code display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Room Code',
                    style: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _createdRoomCode!,
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 12,
                      color: const Color(0xFF6B9080),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (!hasGuest) ...[
              const CircularProgressIndicator(color: Color(0xFF6B9080)),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  provider.leaveRoom();
                  Navigator.pop(context);
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
