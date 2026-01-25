/// Gemini AI Service
///
/// Handles conversation with Google's Gemini API for the Avatar assistant.
/// Uses Active Recall methodology - asks questions instead of telling.
library;

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // Default API key for Luscid project
  static const String _defaultApiKey = 'AIzaSyDMjDL2OLBjKSvZ9dG60xgB7o27DOKTT9Q';

  GenerativeModel? _model;
  ChatSession? _chat;
  bool _isInitialized = false;

  /// System prompt that defines the Avatar's personality and behavior
  static const String _systemPrompt = '''
You are "Buddy", a cute, warm, and encouraging virtual pet companion in the Luscid app - a cognitive health app for elderly users.

ABOUT THE APP:
Luscid helps elderly users with:
1. Memory Games - Card matching games to exercise the brain
2. Daily Activities - A checklist with tasks like:
   - "Play a Memory Game" (🧠)
   - "Drink Water" (💧) 
   - "Take a Short Walk" (🚶)
3. Buddy Circle - Connect with friends and family
4. Shopping List Game - Memory training with grocery items

YOUR PERSONALITY:
- You are a cute, friendly puppy who loves the user
- Be warm, patient, and playful
- Use simple, clear language
- Keep responses SHORT (1-2 sentences) - they will be spoken aloud
- Celebrate every small win enthusiastically!
- Never scold or be negative

WHAT YOU CAN HELP WITH:
- Remind about daily tasks (water, walking, games)
- Encourage completing activities
- Cheer them on during/after games
- Suggest connecting with friends
- Answer questions about the app

ACTIVE RECALL METHOD:
Instead of telling, ASK questions:
- "Did you remember to drink water today?"
- "How about we do a quick walk together?"
- "Want to play a memory game to keep your mind sharp?"

RESPONSE STYLE:
- Max 2 sentences
- End with encouragement or gentle question
- Use happy phrases: "That's wonderful!", "I'm so proud!", "Great job!"
''';

  /// Initialize the Gemini model with API key
  Future<void> init([String? apiKey]) async {
    if (_isInitialized && _model != null) return;

    final key = apiKey ?? _defaultApiKey;
    try {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: key,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 150, // Keep responses short for TTS
        ),
        systemInstruction: Content.text(_systemPrompt),
      );

      _chat = _model!.startChat();
      _isInitialized = true;
      debugPrint('✅ Gemini service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize Gemini: $e');
      rethrow;
    }
  }

  /// Check if service is ready
  bool get isReady => _isInitialized && _model != null;

  /// Send a message and get a response
  Future<String> chat(String message, {Map<String, dynamic>? context}) async {
    if (!isReady) {
      return "I'm having trouble connecting. Please try again in a moment.";
    }

    try {
      // Build context-aware prompt
      String contextualMessage = message;
      if (context != null) {
        contextualMessage = _buildContextualPrompt(message, context);
      }

      final response = await _chat!.sendMessage(Content.text(contextualMessage));
      final text = response.text;

      if (text == null || text.isEmpty) {
        return "I didn't quite catch that. Could you say that again?";
      }

      return text.trim();
    } catch (e) {
      debugPrint('❌ Gemini chat error: $e');
      return "I'm having a little trouble right now. Let's try again!";
    }
  }

  /// Build a context-aware prompt with user state
  String _buildContextualPrompt(String userMessage, Map<String, dynamic> context) {
    final buffer = StringBuffer();
    
    buffer.writeln('[CONTEXT]');
    
    if (context['timeOfDay'] != null) {
      buffer.writeln('Time of day: ${context['timeOfDay']}');
    }
    
    if (context['scenario'] != null) {
      buffer.writeln('Current scenario: ${context['scenario']}');
    }
    
    if (context['missedTasks'] != null) {
      buffer.writeln('Missed tasks: ${context['missedTasks']}');
    }
    
    if (context['completedTasks'] != null) {
      buffer.writeln('Completed tasks today: ${context['completedTasks']}');
    }
    
    if (context['userName'] != null) {
      buffer.writeln('User name: ${context['userName']}');
    }

    if (context['lastGameScore'] != null) {
      buffer.writeln('Last game score: ${context['lastGameScore']}');
    }
    
    buffer.writeln('[USER MESSAGE]');
    buffer.writeln(userMessage);
    
    return buffer.toString();
  }

  /// Get a scripted response for common scenarios (fallback/demo mode)
  String getScriptedResponse(AvatarScenario scenario, {String? detail}) {
    switch (scenario) {
      case AvatarScenario.morningGreeting:
        return _getRandomResponse([
          "Good morning! It looks like a beautiful day to get moving. I'm ready to start our day, are you?",
          "Rise and shine! I've been waiting for you. Ready to plan out today together?",
          "Good morning! Let's exercise our memory first. What are the main things you need to get done today?",
        ]);

      case AvatarScenario.askForRoutine:
        return _getRandomResponse([
          "Can you tell me what are the main things you need to get done today?",
          "Let's plan together. What's on your mind for today?",
          "What are the three most important things you want to accomplish today?",
        ]);

      case AvatarScenario.routineConfirmed:
        return _getRandomResponse([
          "Got it! That sounds like a solid plan. Let's lock that in! I'll check in with you later.",
          "Perfect! I've noted that down. We're going to have a productive day!",
          "Wonderful! That's a great plan. I'll be here to help you stay on track.",
        ]);

      case AvatarScenario.missedTaskNudge:
        return _getRandomResponse([
          "Hey there! I was just looking at our schedule... I have a feeling we might have missed a step.",
          "Oh! I was checking our plan and something seems incomplete. Do you remember what was scheduled earlier?",
          "Hi! I noticed our afternoon plan might be missing something. Any idea what it could be?",
        ]);

      case AvatarScenario.missedTaskQuestion:
        final time = detail ?? '2:00 PM';
        return "Do you remember what was on the plan for $time?";

      case AvatarScenario.userRememberedTask:
        return _getRandomResponse([
          "Spot on! Your memory is sharp. Go ahead and take care of it now—I'll wait right here!",
          "You nailed it! Great memory. Mark it as done when you're finished!",
          "That's right! Excellent recall. Go do that now and come back when you're ready.",
        ]);

      case AvatarScenario.userForgotTask:
        final task = detail ?? 'your scheduled task';
        return _getRandomResponse([
          "No worries, that's why I'm here. It was time for $task. Why don't you take care of that now?",
          "That's okay! It was $task. Let's go handle that first, then we can continue our activities.",
          "Don't worry about it. It was $task. Go ahead and do that—I'll be right here when you get back!",
        ]);

      case AvatarScenario.gameStart:
        return _getRandomResponse([
          "Alright, let's exercise that brain! Take a good look and remember what you see.",
          "Game time! Focus carefully—I know you've got this.",
          "Ready for a challenge? Let's see how sharp that memory is today!",
        ]);

      case AvatarScenario.gameEncouragement:
        return _getRandomResponse([
          "Take your time. Close your eyes for a second if it helps.",
          "You're doing great! Trust your memory.",
          "No rush—really picture it in your mind.",
        ]);

      case AvatarScenario.gameSuccess:
        return _getRandomResponse([
          "Fantastic work! That kind of focus is exactly what keeps the brain strong.",
          "You nailed it! I knew you could do it. Your memory is getting sharper!",
          "Brilliant! That was impressive. Ready for another round?",
        ]);

      case AvatarScenario.gameFailure:
        return _getRandomResponse([
          "That was a tricky one! We got close though. Want to try again?",
          "Not bad at all! Practice makes perfect. Shall we give it another go?",
          "Good effort! Each attempt makes your memory stronger. Try once more?",
        ]);

      case AvatarScenario.friendOnline:
        final friendName = detail ?? 'A friend';
        return "$friendName just came online! This is a perfect chance to say hello. Should we invite them to play?";

      case AvatarScenario.gameInvite:
        final friendName = detail ?? 'Someone';
        return "Exciting news! $friendName wants to play a game with you. Shall we accept the challenge?";

      case AvatarScenario.eveningWrapUp:
        return _getRandomResponse([
          "It's getting late. You've had a wonderful day! Let's look at what you achieved.",
          "What a productive day! Before you rest, let's celebrate your accomplishments.",
          "Evening already! You should be proud of today. Let's review together.",
        ]);

      case AvatarScenario.goodnight:
        return _getRandomResponse([
          "Rest well tonight. Your brain needs sleep to store all those memories we practiced. Goodnight!",
          "Sweet dreams! Tomorrow we'll continue building those memory muscles. Goodnight!",
          "Time to rest that amazing brain. See you tomorrow morning. Goodnight!",
        ]);

      case AvatarScenario.welcomeBack:
        return _getRandomResponse([
          "Welcome back! I missed you. Ready to continue where we left off?",
          "There you are! Great to see you. What shall we do today?",
          "Hello again! I'm so glad you're here. Let's have some fun!",
        ]);

      case AvatarScenario.pttInstruction:
        return "Remember, if you want to talk to your friend, just hold down the big blue button like a walkie-talkie. Give it a try!";
    }
  }

  String _getRandomResponse(List<String> responses) {
    responses.shuffle();
    return responses.first;
  }

  /// Reset chat session (for new day/conversation)
  void resetChat() {
    if (_model != null) {
      _chat = _model!.startChat();
    }
  }

  /// Dispose resources
  void dispose() {
    _chat = null;
    _model = null;
    _isInitialized = false;
  }
}

/// Predefined scenarios for the Avatar
enum AvatarScenario {
  morningGreeting,
  askForRoutine,
  routineConfirmed,
  missedTaskNudge,
  missedTaskQuestion,
  userRememberedTask,
  userForgotTask,
  gameStart,
  gameEncouragement,
  gameSuccess,
  gameFailure,
  friendOnline,
  gameInvite,
  eveningWrapUp,
  goodnight,
  welcomeBack,
  pttInstruction,
}
