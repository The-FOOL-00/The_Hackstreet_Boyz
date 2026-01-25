/// Buddy Popup Widget
///
/// A cute floating avatar popup that can be triggered from anywhere in the app.
/// Buddy speaks and user can respond via voice or text.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/avatar_provider.dart';
import '../providers/activity_provider.dart';
import '../models/activity_model.dart';

/// Show Buddy popup from anywhere (legacy - slides up from bottom)
Future<void> showBuddyPopup(BuildContext context, {String? scenario}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Buddy',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return BuddyPopup(scenario: scenario);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
        child: child,
      );
    },
  );
}

/// Show Buddy popup for an overdue task reminder
Future<void> showBuddyReminderPopup(
  BuildContext context, {
  required String activityId,
  String? userName,
}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Buddy Reminder',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return BuddyPopup(
        scenario: 'overdue_reminder',
        overdueActivityId: activityId,
        userName: userName,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final scaleAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.elasticOut,
      );
      
      return ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(scaleAnimation),
        alignment: Alignment.center,
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

/// Show Buddy popup emerging from the FAB position
Future<void> showBuddyPopupFromFab(
  BuildContext context, {
  Offset? fabPosition,
  Size? fabSize,
  String? scenario,
}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Buddy',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return BuddyPopup(scenario: scenario, fabPosition: fabPosition);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Scale and fade animation - popup grows from FAB position
      final scaleAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      
      return ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(scaleAnimation),
        alignment: Alignment.bottomRight, // Emerge from bottom-right where FAB is
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

class BuddyPopup extends StatefulWidget {
  final String? scenario;
  final Offset? fabPosition;
  final String? overdueActivityId;
  final String? userName;

  const BuddyPopup({
    super.key, 
    this.scenario, 
    this.fabPosition,
    this.overdueActivityId,
    this.userName,
  });

  @override
  State<BuddyPopup> createState() => _BuddyPopupState();
}

class _BuddyPopupState extends State<BuddyPopup> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Bounce animation for idle state
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Initialize and greet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndGreet();
    });
  }

  Future<void> _initAndGreet() async {
    final avatar = context.read<AvatarProvider>();
    final activities = context.read<ActivityProvider>();

    // Initialize avatar
    await avatar.init();

    // Build context about the app and activities
    final activitiesContext = _buildActivitiesContext(activities);
    avatar.setAppContext(activitiesContext);

    setState(() => _isInitialized = true);

    // Trigger appropriate greeting based on scenario
    if (widget.scenario != null) {
      _handleScenario(widget.scenario!, avatar);
    } else {
      // Default greeting based on time and activities
      _smartGreeting(avatar, activities);
    }
  }

  String _buildActivitiesContext(ActivityProvider activities) {
    final buffer = StringBuffer();
    buffer.writeln('TODAY\'S SCHEDULE:');

    for (final activity in activities.activities) {
      final status = activity.isCompleted ? '✓ Done' : '○ Pending';
      buffer.writeln('- ${activity.title}: $status');
    }

    buffer.writeln(
      '\nProgress: ${activities.completedCount}/${activities.totalCount} tasks done',
    );

    return buffer.toString();
  }

  void _smartGreeting(AvatarProvider avatar, ActivityProvider activities) {
    final hour = DateTime.now().hour;
    final pendingTasks = activities.activities
        .where((a) => !a.isCompleted)
        .toList();

    String greeting;

    if (hour < 12) {
      // Morning greeting
      if (pendingTasks.isEmpty) {
        greeting =
            "Good morning! You've completed all your tasks. That's amazing!";
      } else {
        final firstTask = pendingTasks.first;
        greeting =
            "Good morning! Ready to start the day? How about we begin with ${firstTask.title.toLowerCase()}?";
      }
    } else if (hour < 17) {
      // Afternoon
      if (activities.completedCount > 0 && pendingTasks.isNotEmpty) {
        greeting =
            "You're doing great! ${activities.completedCount} tasks done. Want to try ${pendingTasks.first.title.toLowerCase()} next?";
      } else if (pendingTasks.isEmpty) {
        greeting =
            "Wonderful afternoon! You've finished everything. Want to play a game for fun?";
      } else {
        greeting =
            "Good afternoon! Let's check on your activities. What would you like to do?";
      }
    } else {
      // Evening
      if (activities.allCompleted) {
        greeting =
            "What a productive day! You completed all ${activities.totalCount} tasks. I'm so proud of you!";
      } else if (activities.completedCount > 0) {
        greeting =
            "Good evening! You did ${activities.completedCount} tasks today. That's wonderful! Ready to relax?";
      } else {
        greeting =
            "Good evening! There's still time to do something nice. How are you feeling?";
      }
    }

    avatar.speak(greeting, mood: AvatarMood.happy);
  }

  void _handleScenario(String scenario, AvatarProvider avatar) {
    switch (scenario) {
      case 'morning':
        avatar.triggerMorningGreeting();
        break;
      case 'game_start':
        avatar.onGameStart();
        break;
      case 'game_success':
        avatar.onGameSuccess();
        break;
      case 'game_failure':
        avatar.onGameFailure();
        break;
      case 'evening':
        avatar.triggerEveningWrapUp();
        break;
      case 'overdue_reminder':
        _handleOverdueReminder(avatar);
        break;
      default:
        _smartGreeting(avatar, context.read<ActivityProvider>());
    }
  }

  // Track if we're in a reminder conversation (waiting for user response)
  bool _isReminderConversation = false;
  String? _pendingReminderActivityId;

  void _handleOverdueReminder(AvatarProvider avatar) {
    final userName = widget.userName ?? 'friend';
    final activityId = widget.overdueActivityId;
    
    // Store the activity we're reminding about for follow-up
    _pendingReminderActivityId = activityId;
    _isReminderConversation = true;
    
    // Start with a gentle, open-ended question
    final message = "Hey $userName! 💙 Do you think we left out anything on the to-do list which was due?";
    
    avatar.speak(message, mood: AvatarMood.happy);
  }

  /// Handle user's response during a reminder conversation
  Future<String?> _handleReminderResponse(String input, ActivityProvider activities) async {
    if (!_isReminderConversation) return null;
    
    final lower = input.toLowerCase();
    final userName = widget.userName ?? 'friend';
    
    // Check if user acknowledges they'll do the task
    final positivePatterns = [
      'yes', 'yeah', 'yep', 'yup', 'i will', "i'll", 'will do', 'taking', 'took',
      'medicine', 'tablet', 'pill', 'medication', 'on it', 'doing it', 'right now',
      'forgot', 'let me', 'going to', 'gonna', 'sure', 'ok', 'okay', 'thanks',
    ];
    
    final isPositive = positivePatterns.any((p) => lower.contains(p));
    
    if (isPositive) {
      // User acknowledged - appreciate them and mark as complete if they mention medicine
      _isReminderConversation = false;
      
      // Check if they're completing the task
      if (lower.contains('medicine') || lower.contains('tablet') || 
          lower.contains('pill') || lower.contains('took') || lower.contains('taking')) {
        // Mark the medicine task as complete
        await activities.completeActivityByKeyword('medicine');
        
        return "That's wonderful, $userName! 🌟 I'm so proud of you for staying on top of things. "
            "Taking care of yourself is the best gift you can give! Keep it up! 💪😊";
      }
      
      // General positive acknowledgment
      return "Great! 😊 I knew you had it covered, $userName. "
          "You're doing amazing - keep being awesome! 💙";
    }
    
    // Check if user says no or denies
    final negativePatterns = ['no', 'nope', 'nah', "don't think", 'nothing', 'all done', 'completed'];
    final isNegative = negativePatterns.any((p) => lower.contains(p));
    
    if (isNegative) {
      // User says no - gently remind them
      _isReminderConversation = false;
      
      // Find what's overdue
      final overdue = activities.overdueActivities;
      if (overdue.isNotEmpty) {
        final overdueNames = overdue.map((a) => a.title).join(', ');
        return "Hmm, just a gentle thought... 💭 I noticed $overdueNames might still be pending. "
            "No rush at all! But when you get a moment, it might be good to check on those. "
            "I believe in you, $userName! 💙";
      }
      
      return "Okay! If you're all caught up, that's fantastic! 🎉 "
          "You're doing great today, $userName!";
    }
    
    // Unclear response - provide a gentle nudge
    _isReminderConversation = false;
    
    final overdue = activities.overdueActivities;
    if (overdue.isNotEmpty && _pendingReminderActivityId != null) {
      try {
        final activity = activities.activities.firstWhere((a) => a.id == _pendingReminderActivityId);
        return "Just a friendly reminder, $userName - ${activity.title.toLowerCase()} was scheduled for earlier. "
            "Did you get a chance to do that? It's totally okay if not, just wanted to check in! 😊💊";
      } catch (_) {}
    }
    
    return null; // Let normal processing handle it
  }

  Future<void> _handleUserInput(String input) async {
    if (input.trim().isEmpty) return;

    _textController.clear();

    final avatar = context.read<AvatarProvider>();
    final activities = context.read<ActivityProvider>();

    // Check if we're in a reminder conversation first
    if (_isReminderConversation) {
      final reminderResponse = await _handleReminderResponse(input, activities);
      if (reminderResponse != null) {
        avatar.speak(reminderResponse, mood: AvatarMood.happy);
        return;
      }
    }

    // Check for task-related commands
    final taskResponse = await _processTaskCommand(input, activities);
    
    if (taskResponse != null) {
      // Task command was handled
      avatar.speak(taskResponse, mood: AvatarMood.happy);
      return;
    }

    // Otherwise, chat with Gemini including task context
    final response = await avatar.chatWithContext(
      input,
      activities: activities.activities,
      taskSummary: activities.getActivitiesSummary(),
    );

    avatar.speak(response, mood: AvatarMood.happy);
  }

  /// Process task-related voice/text commands
  Future<String?> _processTaskCommand(String input, ActivityProvider activities) async {
    final lower = input.toLowerCase();
    
    // === TASK COMPLETION PATTERNS ===
    final completionPatterns = [
      'done', 'finished', 'completed', 'did', 'took', 'taken', 
      'drank', 'walked', 'played', 'i had', 'just had', 'already'
    ];
    
    bool isCompletion = completionPatterns.any((p) => lower.contains(p));
    
    if (isCompletion) {
      // Extract what task they completed
      String? taskKeyword;
      
      if (lower.contains('water') || lower.contains('drink') || lower.contains('drank')) {
        taskKeyword = 'water';
      } else if (lower.contains('walk') || lower.contains('walked') || lower.contains('exercise')) {
        taskKeyword = 'walk';
      } else if (lower.contains('game') || lower.contains('played') || lower.contains('memory')) {
        taskKeyword = 'game';
      } else if (lower.contains('medicine') || lower.contains('tablet') || 
                 lower.contains('pill') || lower.contains('medication')) {
        taskKeyword = 'medicine';
      }
      
      if (taskKeyword != null) {
        return await activities.completeActivityByKeyword(taskKeyword);
      }
    }
    
    // === TASK ADDITION PATTERNS ===
    final addPatterns = ['add', 'remind me', 'set reminder', 'put on list', 'add to list', 'add to tracker'];
    bool isAddition = addPatterns.any((p) => lower.contains(p));
    
    if (isAddition) {
      // Extract task name - text after "add", "remind me to", etc.
      String taskTitle = input;
      
      for (final pattern in ['remind me to ', 'add ', 'put ', 'set reminder for ']) {
        if (lower.contains(pattern)) {
          final idx = lower.indexOf(pattern);
          taskTitle = input.substring(idx + pattern.length).trim();
          break;
        }
      }
      
      // Clean up common trailing words
      taskTitle = taskTitle
          .replaceAll(RegExp(r'\b(to my list|to tracker|to the list|please)\b', caseSensitive: false), '')
          .trim();
      
      if (taskTitle.isNotEmpty && taskTitle.length > 2) {
        // Check for time mentions
        DateTime? scheduledTime;
        final timeMatch = RegExp(r'at\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?', caseSensitive: false)
            .firstMatch(taskTitle);
        
        if (timeMatch != null) {
          int hour = int.parse(timeMatch.group(1)!);
          int minute = timeMatch.group(2) != null ? int.parse(timeMatch.group(2)!) : 0;
          final ampm = timeMatch.group(3)?.toLowerCase();
          
          if (ampm == 'pm' && hour < 12) hour += 12;
          if (ampm == 'am' && hour == 12) hour = 0;
          
          final now = DateTime.now();
          scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
          
          // Remove time from title
          taskTitle = taskTitle.replaceAll(timeMatch.group(0)!, '').trim();
        }
        
        return await activities.addCustomActivity(
          title: taskTitle.substring(0, 1).toUpperCase() + taskTitle.substring(1),
          scheduledTime: scheduledTime,
        );
      }
    }
    
    // === TASK QUERY PATTERNS ===
    if (lower.contains('what') && (lower.contains('left') || lower.contains('pending') || 
        lower.contains('remaining') || lower.contains('to do') || lower.contains('todo'))) {
      final pending = activities.pendingActivities;
      if (pending.isEmpty) {
        return "You've completed all your tasks for today! 🎉 You're amazing!";
      }
      
      final taskList = pending.map((a) => a.title).join(', ');
      return "You still have ${pending.length} task${pending.length > 1 ? 's' : ''} left: $taskList. You've got this! 💪";
    }
    
    // === REMOVAL PATTERNS ===
    if (lower.contains('remove') || lower.contains('delete') || lower.contains('cancel')) {
      // Extract what to remove
      final removeMatch = RegExp(r'(?:remove|delete|cancel)\s+(.+?)(?:\s+from|\s*$)', caseSensitive: false)
          .firstMatch(input);
      if (removeMatch != null) {
        return await activities.removeActivityByKeyword(removeMatch.group(1)!);
      }
    }
    
    return null; // Not a task command
  }

  bool _isVoiceInputActive = false;

  Future<void> _startVoiceInput() async {
    if (_isVoiceInputActive) return;
    
    final avatar = context.read<AvatarProvider>();
    
    // Check if STT is available
    if (!avatar.canListen) {
      // Show error and fallback to text input
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice input is not available. Please use text input.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    
    _isVoiceInputActive = true;
    setState(() {});
    
    await avatar.startListening();
    
    // Wait for speech recognition to complete (up to 10 seconds)
    int waitTime = 0;
    const maxWait = 10000; // 10 seconds max
    const checkInterval = 300; // Check every 300ms
    
    while (avatar.isListening && waitTime < maxWait) {
      await Future.delayed(const Duration(milliseconds: checkInterval));
      waitTime += checkInterval;
      
      // If we have a transcript, we can stop waiting
      if (avatar.userTranscript.isNotEmpty) {
        break;
      }
    }
    
    await avatar.stopListening();
    _isVoiceInputActive = false;
    if (mounted) setState(() {});
    
    // Give a small delay for final transcript to be set
    await Future.delayed(const Duration(milliseconds: 200));
    
    final transcript = avatar.userTranscript;
    if (transcript.isNotEmpty) {
      _handleUserInput(transcript);
    } else if (mounted) {
      // No speech detected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("I didn't hear anything. Please try again or type your message."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _textController.dispose();
    context.read<AvatarProvider>().stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          decoration: BoxDecoration(
            // Glassmorphic white with slight blue tint
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF8FBFF), // Very pale blue-white
                Color(0xFFFFFFFF),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar - stitch style
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),

                // Close button - accessible size
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4, top: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F7FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF64748B),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Cute Avatar
                _buildCuteAvatar(),

                // Speech text (what Buddy is saying)
                _buildSpeechArea(),

                // Input area
                _buildInputArea(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCuteAvatar() {
    return Consumer<AvatarProvider>(
      builder: (context, avatar, _) {
        return AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_bounceAnimation.value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cute Mochi Cat with animated talking
                  AnimatedScale(
                    scale: avatar.isSpeaking ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glowing ring when speaking
                        if (avatar.isSpeaking)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1.0, end: 1.2),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF3B82F6).withOpacity(0.3),
                                        const Color(0xFF3B82F6).withOpacity(0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                        // Main avatar container - glassmorphic style
                        Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.95),
                            border: Border.all(
                              color: avatar.isSpeaking
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFFDBEAFE),
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6).withOpacity(
                                  avatar.isSpeaking ? 0.3 : 0.1,
                                ),
                                blurRadius: avatar.isSpeaking ? 24 : 12,
                                spreadRadius: avatar.isSpeaking ? 4 : 0,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 8,
                                offset: const Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _buildMochiCat(avatar),
                          ),
                        ),

                        // Status indicator dot
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: avatar.isSpeaking ? 20 : 16,
                            height: avatar.isSpeaking ? 20 : 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: avatar.isSpeaking
                                  ? const Color(0xFF22C55E) // Green when speaking
                                  : const Color(0xFF3B82F6), // Blue when idle
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: (avatar.isSpeaking
                                          ? const Color(0xFF22C55E)
                                          : const Color(0xFF3B82F6))
                                      .withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Name badge - stitch style with pill shape
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: avatar.isSpeaking
                            ? [const Color(0xFF3B82F6), const Color(0xFF2563EB)]
                            : [
                                const Color(0xFFDBEAFE),
                                const Color(0xFFBFDBFE),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (avatar.isSpeaking) ...[
                          _buildMiniSpeakingWave(),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          'Buddy',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: avatar.isSpeaking
                                ? Colors.white
                                : const Color(0xFF1E3A8A),
                            letterSpacing: 0.5,
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
      },
    );
  }

  Widget _buildMiniSpeakingWave() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 3, end: 10),
          duration: Duration(milliseconds: 400 + (index * 150)),
          curve: Curves.easeInOut,
          builder: (context, height, _) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 3,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }

  /// Build the cute Mochi Cat avatar with animated mouth for talking
  Widget _buildMochiCat(AvatarProvider avatar) {
    // Drawing a cute Mochi-style cat like the reference images
    return Container(
      color: const Color(0xFFFFF8F0), // Warm cream background
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cat body/head - cream colored round shape
          Positioned(
            top: 15,
            child: Container(
              width: 120,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF5), // Cream white
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: const Color(0xFF8B7355), // Brown outline
                  width: 2.5,
                ),
              ),
            ),
          ),
          
          // Left ear
          Positioned(
            top: 5,
            left: 20,
            child: Transform.rotate(
              angle: -0.3,
              child: Container(
                width: 28,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                  border: Border.all(
                    color: const Color(0xFF8B7355),
                    width: 2.5,
                  ),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 14,
                    height: 18,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB6A3), // Pink inner ear
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Right ear
          Positioned(
            top: 5,
            right: 20,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                width: 28,
                height: 35,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                  border: Border.all(
                    color: const Color(0xFF8B7355),
                    width: 2.5,
                  ),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 14,
                    height: 18,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB6A3), // Pink inner ear
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Left eye
          Positioned(
            top: 50,
            left: 35,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFF3D3D3D),
                shape: BoxShape.circle,
              ),
              child: Align(
                alignment: const Alignment(0.3, -0.3),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          
          // Right eye  
          Positioned(
            top: 50,
            right: 35,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFF3D3D3D),
                shape: BoxShape.circle,
              ),
              child: Align(
                alignment: const Alignment(0.3, -0.3),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          
          // Left cheek blush
          Positioned(
            top: 60,
            left: 22,
            child: Container(
              width: 18,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB6A3).withOpacity(0.6),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          
          // Right cheek blush
          Positioned(
            top: 60,
            right: 22,
            child: Container(
              width: 18,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB6A3).withOpacity(0.6),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          
          // Nose - small brown triangle/oval
          Positioned(
            top: 68,
            child: Container(
              width: 8,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFF8B7355),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          
          // Mouth - animated for talking
          Positioned(
            top: 76,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: avatar.mouthOpen ? 20 : 6,
              height: avatar.mouthOpen ? 14 : 6,
              decoration: BoxDecoration(
                color: avatar.mouthOpen 
                    ? const Color(0xFFE57373) // Open mouth - reddish
                    : const Color(0xFF8B7355), // Closed - brown dot
                borderRadius: BorderRadius.circular(avatar.mouthOpen ? 10 : 4),
              ),
              child: avatar.mouthOpen
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        // Tongue
                        Positioned(
                          bottom: 1,
                          child: Container(
                            width: 10,
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8A80),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          
          // Left paw/hand - waving
          Positioned(
            bottom: 25,
            left: 15,
            child: Transform.rotate(
              angle: avatar.isSpeaking ? -0.2 : 0.0,
              child: Container(
                width: 25,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8B7355),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          
          // Right paw/hand - waving when speaking
          Positioned(
            bottom: avatar.isSpeaking ? 30 : 25,
            right: 15,
            child: AnimatedRotation(
              turns: avatar.isSpeaking ? 0.05 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                width: 25,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF8B7355),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechArea() {
    return Consumer<AvatarProvider>(
      builder: (context, avatar, _) {
        if (avatar.currentText.isEmpty && _isInitialized) {
          return const SizedBox(height: 16);
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            // Soft blue bubble like speech container
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0F7FF), Color(0xFFDBEAFE)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (avatar.isSpeaking)
                Container(
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildSpeakingIndicator(),
                ),
              Expanded(
                child: Text(
                  avatar.currentText.isEmpty
                      ? 'Hi there! 👋'
                      : avatar.currentText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E3A8A), // Deep blue for readability
                    height: 1.5,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpeakingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 4, end: 14),
          duration: Duration(milliseconds: 350 + (index * 120)),
          curve: Curves.easeInOut,
          builder: (context, height, child) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 350 + (index * 120)),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white, // White on blue background
                borderRadius: BorderRadius.circular(3),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildInputArea() {
    return Consumer<AvatarProvider>(
      builder: (context, avatar, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Text input - larger, more accessible
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: const Color(0xFF94A3B8),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: _handleUserInput,
                ),
              ),

              // Voice button - larger touch target (44x44 min)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: avatar.isListening ? null : _startVoiceInput,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: avatar.isListening
                            ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                            : [
                                const Color(0xFFDBEAFE),
                                const Color(0xFFBFDBFE),
                              ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              (avatar.isListening
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF3B82F6))
                                  .withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      avatar.isListening
                          ? Icons.stop_rounded
                          : Icons.mic_rounded,
                      color: avatar.isListening
                          ? Colors.white
                          : const Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send button - primary action, stands out
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleUserInput(_textController.text),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
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
