/// Shopping Game Setup Screen
///
/// Allows creating or joining a shopping list game room.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import 'shopping_game_screen.dart';

class ShoppingGameSetupScreen extends StatefulWidget {
  const ShoppingGameSetupScreen({super.key});

  @override
  State<ShoppingGameSetupScreen> createState() =>
      _ShoppingGameSetupScreenState();
}

class _ShoppingGameSetupScreenState extends State<ShoppingGameSetupScreen> {
  final _roomCodeController = TextEditingController();
  bool _isCreating = false;
  bool _isJoining = false;
  String? _errorMessage;

  // Game settings
  int _targetItems = 8;
  int _memorizeTime = 30;
  int _selectionTime = 60;

  @override
  void initState() {
    super.initState();
    // Initialize provider with user ID
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      context.read<ShoppingListProvider>().init(userId);
    });
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    final provider = context.read<ShoppingListProvider>();
    final roomCode = await provider.createRoom(
      targetItemCount: _targetItems,
      memorizeTimeSeconds: _memorizeTime,
      selectionTimeSeconds: _selectionTime,
    );

    setState(() => _isCreating = false);

    if (roomCode != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ShoppingGameScreen()),
      );
    } else {
      setState(() {
        _errorMessage = provider.error ?? 'Failed to create room';
      });
    }
  }

  Future<void> _joinRoom() async {
    final code = _roomCodeController.text.trim().toUpperCase();
    if (code.isEmpty || code.length != 4) {
      setState(
        () => _errorMessage = 'Please enter a valid 4-character room code',
      );
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    final provider = context.read<ShoppingListProvider>();
    final success = await provider.joinRoom(code);

    setState(() => _isJoining = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ShoppingGameScreen()),
      );
    } else {
      setState(() {
        _errorMessage = provider.error ?? 'Failed to join room';
      });
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
          'Shopping List Game',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3B36),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game icon and description
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0ED),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: Text('🛒', style: TextStyle(fontSize: 60)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Memory Shopping Challenge',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3B36),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Memorize the shopping list, then find all items!\nPlay solo or with a friend.',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF5C6B66),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
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
                        _errorMessage!,
                        style: GoogleFonts.poppins(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Create Room Section
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_circle, color: Color(0xFF6B9080)),
                      const SizedBox(width: 8),
                      Text(
                        'Create New Game',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3B36),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Game settings
                  Text(
                    'Game Settings',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5C6B66),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Items to memorize
                  _buildSliderSetting(
                    label: 'Items to memorize',
                    value: _targetItems,
                    min: 4,
                    max: 12,
                    onChanged: (v) => setState(() => _targetItems = v.round()),
                  ),

                  // Memorize time
                  _buildSliderSetting(
                    label: 'Memorize time (seconds)',
                    value: _memorizeTime,
                    min: 15,
                    max: 60,
                    onChanged: (v) => setState(() => _memorizeTime = v.round()),
                  ),

                  // Selection time
                  _buildSliderSetting(
                    label: 'Selection time (seconds)',
                    value: _selectionTime,
                    min: 30,
                    max: 120,
                    onChanged: (v) =>
                        setState(() => _selectionTime = v.round()),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B9080),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isCreating
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
              ),
            ),

            const SizedBox(height: 24),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF5C6B66),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 24),

            // Join Room Section
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.login, color: Color(0xFF6B9080)),
                      const SizedBox(width: 8),
                      Text(
                        'Join Game',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3B36),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter 4-character room code',
                    style: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _roomCodeController,
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 4,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'ABCD',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: Colors.grey.shade300,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F5F2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isJoining ? null : _joinRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF6B9080,
                        ).withOpacity(0.1),
                        foregroundColor: const Color(0xFF6B9080),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isJoining
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Color(0xFF6B9080),
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
              ),
            ),

            const SizedBox(height: 24),

            // How to play
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFF6B9080),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How to Play',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3B36),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildHowToPlayItem('1', 'Create a room and share the code'),
                  _buildHowToPlayItem('2', 'Memorize the shopping list items'),
                  _buildHowToPlayItem('3', 'Find all items from memory'),
                  _buildHowToPlayItem('4', 'Work together for the best score!'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSetting({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5C6B66),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B9080).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$value',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6B9080),
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF6B9080),
              inactiveTrackColor: const Color(0xFF6B9080).withOpacity(0.2),
              thumbColor: const Color(0xFF6B9080),
              overlayColor: const Color(0xFF6B9080).withOpacity(0.2),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToPlayItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF6B9080),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(color: const Color(0xFF5C6B66)),
            ),
          ),
        ],
      ),
    );
  }
}
