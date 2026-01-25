/// Avatar Screen
///
/// Main screen for interacting with the AI Avatar "Buddy".
/// Features animated avatar, STT input, and TTS output.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../providers/avatar_provider.dart';

class AvatarScreen extends StatefulWidget {
  final String? initialScenario;
  final Map<String, dynamic>? scenarioData;

  const AvatarScreen({
    super.key,
    this.initialScenario,
    this.scenarioData,
  });

  @override
  State<AvatarScreen> createState() => _AvatarScreenState();
}

class _AvatarScreenState extends State<AvatarScreen> with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _pulseController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;
  
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _showingApiKeyDialog = false;

  @override
  void initState() {
    super.initState();
    
    // Bounce animation for avatar
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Pulse animation for listening indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAvatar();
    });
  }

  Future<void> _initializeAvatar() async {
    final avatar = context.read<AvatarProvider>();
    await avatar.init();
    
    // Check if API key is set
    if (!avatar.isInitialized) {
      _showApiKeyDialog();
      return;
    }

    // Handle initial scenario
    _handleInitialScenario();
  }

  void _handleInitialScenario() {
    final avatar = context.read<AvatarProvider>();
    final scenario = widget.initialScenario;

    switch (scenario) {
      case 'morning':
        avatar.triggerMorningGreeting();
        _addMessage(ChatMessage(
          isUser: false,
          text: 'Good morning! Let\'s plan your day together.',
          timestamp: DateTime.now(),
        ));
        break;
      case 'missed_task':
        final task = widget.scenarioData?['task'] ?? 'your scheduled task';
        final time = widget.scenarioData?['time'] ?? '2:00 PM';
        avatar.triggerMissedTaskReminder(task, time);
        break;
      case 'evening':
        avatar.triggerEveningWrapUp();
        break;
      default:
        // Welcome greeting
        avatar.speak(
          "Hello! I'm Buddy, your memory coach. How can I help you today?",
          mood: AvatarMood.happy,
        );
        _addMessage(ChatMessage(
          isUser: false,
          text: "Hello! I'm Buddy, your memory coach. How can I help you today?",
          timestamp: DateTime.now(),
        ));
    }
  }

  void _showApiKeyDialog() {
    if (_showingApiKeyDialog) return;
    _showingApiKeyDialog = true;
    
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🤖', style: TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            const Text('Setup Buddy'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To enable AI conversations, enter your Gemini API key. '
              'Get one free at ai.google.dev',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AIza...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            Text(
              'You can skip this and use scripted responses.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showingApiKeyDialog = false;
              _handleInitialScenario();
            },
            child: const Text('Skip for Now'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await context.read<AvatarProvider>().saveApiKey(controller.text);
              }
              if (mounted) {
                Navigator.pop(context);
                _showingApiKeyDialog = false;
                _handleInitialScenario();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleUserInput(String input) async {
    if (input.isEmpty) return;

    // Add user message
    _addMessage(ChatMessage(
      isUser: true,
      text: input,
      timestamp: DateTime.now(),
    ));

    // Get AI response
    final avatar = context.read<AvatarProvider>();
    final response = await avatar.chat(input);

    // Add avatar response
    _addMessage(ChatMessage(
      isUser: false,
      text: response,
      timestamp: DateTime.now(),
    ));

    // Speak the response
    await avatar.speak(response);
  }

  Future<void> _startVoiceInput() async {
    final avatar = context.read<AvatarProvider>();
    await avatar.startListening();
  }

  Future<void> _stopVoiceInput() async {
    final avatar = context.read<AvatarProvider>();
    await avatar.stopListening();
    
    // Process the transcript
    final transcript = avatar.userTranscript;
    if (transcript.isNotEmpty) {
      await _handleUserInput(transcript);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -80,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft.withOpacity(0.5),
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildAvatar(),
                Expanded(child: _buildChatArea()),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderBlue),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buddy', style: AppTextStyles.heading4),
                Text(
                  'Your Memory Coach',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Consumer<AvatarProvider>(
            builder: (context, avatar, _) {
              Color statusColor = Colors.grey;
              String statusText = 'Idle';
              
              switch (avatar.state) {
                case AvatarState.speaking:
                  statusColor = AppColors.success;
                  statusText = 'Speaking';
                  break;
                case AvatarState.listening:
                  statusColor = AppColors.error;
                  statusText = 'Listening';
                  break;
                case AvatarState.thinking:
                  statusColor = Colors.orange;
                  statusText = 'Thinking';
                  break;
                case AvatarState.idle:
                  statusColor = Colors.grey;
                  statusText = 'Ready';
              }
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Consumer<AvatarProvider>(
      builder: (context, avatar, _) {
        return AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_bounceAnimation.value),
              child: Container(
                height: 200,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect when speaking
                    if (avatar.isSpeaking)
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, _) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryBlue.withOpacity(0.2),
                              ),
                            ),
                          );
                        },
                      ),
                    
                    // Avatar body
                    _buildAvatarBody(avatar),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvatarBody(AvatarProvider avatar) {
    // Cute puppy pet avatar that elderly can connect with
    return Container(
      width: 140,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Body
          Positioned(
            bottom: 0,
            child: Container(
              width: 100,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFD4A574), // Warm tan/golden color
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          
          // Head
          Positioned(
            top: 0,
            child: Container(
              width: 110,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFD4A574),
                borderRadius: BorderRadius.circular(55),
                boxShadow: [
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Left ear
                  Positioned(
                    top: -8,
                    left: 5,
                    child: Transform.rotate(
                      angle: -0.3,
                      child: Container(
                        width: 30,
                        height: 45,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC49A6C),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  // Right ear
                  Positioned(
                    top: -8,
                    right: 5,
                    child: Transform.rotate(
                      angle: 0.3,
                      child: Container(
                        width: 30,
                        height: 45,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC49A6C),
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  // Face area
                  Positioned(
                    top: 30,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        // Eyes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPetEye(avatar.isListening, avatar.mood),
                            const SizedBox(width: 25),
                            _buildPetEye(avatar.isListening, avatar.mood),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Nose
                        Container(
                          width: 16,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4A3728),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(8),
                              topRight: const Radius.circular(8),
                              bottomLeft: const Radius.circular(10),
                              bottomRight: const Radius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Mouth - animated open/close at 200ms
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: avatar.mouthOpen ? 24 : 30,
                          height: avatar.mouthOpen ? 16 : 6,
                          decoration: BoxDecoration(
                            color: avatar.mouthOpen 
                                ? const Color(0xFFE87D7D) // Pink tongue
                                : const Color(0xFF4A3728), // Brown closed
                            borderRadius: BorderRadius.circular(avatar.mouthOpen ? 12 : 3),
                          ),
                          child: avatar.mouthOpen
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF9999), // Tongue
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                  // Cheeks (blush when happy)
                  if (avatar.mood == AvatarMood.happy || avatar.mood == AvatarMood.celebrating)
                    Positioned(
                      top: 45,
                      left: 12,
                      child: Container(
                        width: 14,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  if (avatar.mood == AvatarMood.happy || avatar.mood == AvatarMood.celebrating)
                    Positioned(
                      top: 45,
                      right: 12,
                      child: Container(
                        width: 14,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Tail (wagging when happy)
          if (avatar.mood == AvatarMood.happy || avatar.mood == AvatarMood.celebrating)
            Positioned(
              bottom: 25,
              right: 5,
              child: Transform.rotate(
                angle: avatar.mouthOpen ? 0.3 : -0.1,
                child: Container(
                  width: 15,
                  height: 35,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC49A6C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPetEye(bool isListening, AvatarMood mood) {
    final isHappy = mood == AvatarMood.happy || mood == AvatarMood.celebrating;
    
    return Container(
      width: 20,
      height: isHappy ? 12 : 20,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: isHappy 
            ? BorderRadius.only(
                bottomLeft: const Radius.circular(10),
                bottomRight: const Radius.circular(10),
              )
            : BorderRadius.circular(10),
      ),
      child: !isHappy
          ? Stack(
              children: [
                // Eye shine
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildChatArea() {
    return Consumer<AvatarProvider>(
      builder: (context, avatar, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderBlue),
          ),
          child: Column(
            children: [
              // Current speech bubble
              if (avatar.currentText.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Text(
                    avatar.currentText,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              // Chat history
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildChatBubble(message);
                  },
                ),
              ),
              
              // Listening indicator
              if (avatar.isListening)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, _) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 12,
                                height: 12 * _pulseAnimation.value * (0.5 + index * 0.25),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        avatar.userTranscript.isEmpty 
                            ? 'Listening...' 
                            : avatar.userTranscript,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primaryBlue : AppColors.primarySoft,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(
                message.text,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('👤', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Consumer<AvatarProvider>(
      builder: (context, avatar, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Text input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderBlue),
                  ),
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: (text) {
                      _handleUserInput(text);
                      _textController.clear();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Voice input button
              GestureDetector(
                onTapDown: (_) => _startVoiceInput(),
                onTapUp: (_) => _stopVoiceInput(),
                onTapCancel: () => _stopVoiceInput(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: avatar.isListening 
                        ? AppColors.error 
                        : AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: (avatar.isListening 
                            ? AppColors.error 
                            : AppColors.primaryBlue).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    avatar.isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              
              // Send button
              const SizedBox(width: 8),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  icon: Icon(Icons.send, color: AppColors.primaryBlue),
                  onPressed: () {
                    _handleUserInput(_textController.text);
                    _textController.clear();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Chat message model
class ChatMessage {
  final bool isUser;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.isUser,
    required this.text,
    required this.timestamp,
  });
}
