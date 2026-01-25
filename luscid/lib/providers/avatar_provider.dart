/// Avatar Provider
///
/// Manages the AI Avatar state, animations, and conversation flow.
/// Implements Active Recall methodology for memory training.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/gemini_service.dart';
import '../services/speech_service.dart';
import '../services/local_storage_service.dart';
import '../models/activity_model.dart';

/// Avatar state
enum AvatarState {
  idle,
  speaking,
  listening,
  thinking,
}

/// Avatar mood for animations
enum AvatarMood {
  happy,
  neutral,
  encouraging,
  celebrating,
  thinking,
}

class AvatarProvider extends ChangeNotifier {
  final GeminiService _gemini = GeminiService();
  final SpeechService _speech = SpeechService();
  final LocalStorageService _storage = LocalStorageService();

  AvatarState _state = AvatarState.idle;
  AvatarMood _mood = AvatarMood.neutral;
  String _currentText = '';
  String _userTranscript = '';
  bool _isInitialized = false;
  bool _useGemini = true; // Toggle between AI and scripted responses
  String? _geminiApiKey;

  // Conversation context
  List<String> _todaysTasks = [];
  List<String> _completedTasks = [];
  List<Map<String, dynamic>> _missedTasks = [];
  String? _userName;
  DateTime _lastInteraction = DateTime.now();

  // Animation timer for mouth movement
  Timer? _mouthTimer;
  bool _mouthOpen = false;

  // Getters
  AvatarState get state => _state;
  AvatarMood get mood => _mood;
  String get currentText => _currentText;
  String get userTranscript => _userTranscript;
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _state == AvatarState.speaking;
  bool get isListening => _state == AvatarState.listening;
  bool get isThinking => _state == AvatarState.thinking;
  bool get mouthOpen => _mouthOpen;
  bool get canListen => _speech.canListen;
  List<String> get todaysTasks => _todaysTasks;
  List<String> get completedTasks => _completedTasks;

  /// Initialize the Avatar
  Future<void> init({String? apiKey}) async {
    if (_isInitialized) return;

    try {
      // Initialize speech service
      await _speech.init();

      // Set up speech callbacks
      _speech.onSpeakingChanged = (speaking) {
        if (speaking) {
          _state = AvatarState.speaking;
          _startMouthAnimation();
        } else {
          _state = AvatarState.idle;
          _stopMouthAnimation();
        }
        notifyListeners();
      };

      _speech.onSpeechResult = (result) {
        _userTranscript = result;
        notifyListeners();
      };

      _speech.onListeningStarted = () {
        _state = AvatarState.listening;
        notifyListeners();
      };

      _speech.onListeningStopped = () {
        if (_state == AvatarState.listening) {
          _state = AvatarState.idle;
          notifyListeners();
        }
      };

      // Initialize Gemini - uses default API key if none provided
      _geminiApiKey = apiKey ?? await _loadApiKey();
      try {
        await _gemini.init(_geminiApiKey);
        _useGemini = true;
        debugPrint('✅ Gemini initialized with API key');
      } catch (e) {
        _useGemini = false;
        debugPrint('⚠️ Gemini init failed - using scripted responses: $e');
      }

      // Load user data
      await _loadUserData();

      _isInitialized = true;
      notifyListeners();
      debugPrint('✅ Avatar provider initialized');
    } catch (e) {
      debugPrint('❌ Avatar init error: $e');
      _useGemini = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Load API key from storage
  Future<String?> _loadApiKey() async {
    try {
      return _storage.getString('gemini_api_key');
    } catch (e) {
      return null;
    }
  }

  /// Save API key
  Future<void> saveApiKey(String apiKey) async {
    try {
      await _storage.setString('gemini_api_key', apiKey);
      _geminiApiKey = apiKey;
      await _gemini.init(apiKey);
      _useGemini = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving API key: $e');
    }
  }

  /// Load user data from storage
  Future<void> _loadUserData() async {
    try {
      _userName = _storage.getString('user_name');
      final tasksJson = _storage.getString('todays_tasks');
      if (tasksJson != null) {
        // Parse tasks if stored
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  /// Start mouth animation while speaking
  void _startMouthAnimation() {
    _mouthTimer?.cancel();
    _mouthTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      _mouthOpen = !_mouthOpen;
      notifyListeners();
    });
  }

  /// Stop mouth animation
  void _stopMouthAnimation() {
    _mouthTimer?.cancel();
    _mouthOpen = false;
    notifyListeners();
  }

  /// Speak a message
  Future<void> speak(String text, {AvatarMood? mood, VoidCallback? onComplete}) async {
    _currentText = text;
    _mood = mood ?? AvatarMood.neutral;
    _lastInteraction = DateTime.now();
    notifyListeners();

    await _speech.speak(text, onComplete: onComplete);
  }

  /// Start listening for user input
  Future<void> startListening() async {
    _userTranscript = '';
    await _speech.startListening();
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _speech.stopListening();
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _speech.stop();
  }

  /// Have a conversation with Gemini
  Future<String> chat(String userMessage) async {
    _state = AvatarState.thinking;
    notifyListeners();

    String response;

    if (_useGemini && _gemini.isReady) {
      response = await _gemini.chat(userMessage, context: _buildContext());
    } else {
      // Fall back to pattern matching for scripted responses
      response = _getPatternMatchedResponse(userMessage);
    }

    _state = AvatarState.idle;
    notifyListeners();

    return response;
  }

  // App context for smarter responses
  String _appContext = '';

  /// Set app context (activities, schedule, etc.)
  void setAppContext(String context) {
    _appContext = context;
  }

  /// Chat with full activity context
  Future<String> chatWithContext(String userMessage, {
    List<ActivityModel>? activities,
    String? taskSummary,
  }) async {
    _state = AvatarState.thinking;
    notifyListeners();

    String response;

    // Build enhanced context
    final contextMap = _buildContext();
    if (activities != null) {
      contextMap['activities'] = activities.map((a) => {
        'title': a.title,
        'completed': a.isCompleted,
        'icon': a.icon,
        'scheduledTime': a.scheduledTime?.toIso8601String(),
        'isOverdue': a.isOverdue,
      }).toList();
    }
    if (taskSummary != null) {
      contextMap['taskSummary'] = taskSummary;
    }
    contextMap['appContext'] = _appContext;

    if (_useGemini && _gemini.isReady) {
      response = await _gemini.chat(userMessage, context: contextMap);
    } else {
      response = _getSmartPatternResponse(userMessage, activities);
    }

    _state = AvatarState.idle;
    notifyListeners();

    return response;
  }

  /// Smart pattern matching with activity awareness
  String _getSmartPatternResponse(String input, List<ActivityModel>? activities) {
    final lower = input.toLowerCase();

    // Schedule/activity related queries
    if (lower.contains('schedule') || lower.contains('today') || lower.contains('do today') || lower.contains('tasks')) {
      if (activities != null && activities.isNotEmpty) {
        final pending = activities.where((a) => !a.isCompleted).toList();
        if (pending.isEmpty) {
          return "You've completed all your tasks for today! Amazing job! Want to play a game for fun?";
        }
        final taskList = pending.map((a) => a.title).join(', ');
        return "You still have these to do: $taskList. Which one would you like to start with?";
      }
      return "Let me check your schedule... You can view your daily activities in Today's Activity screen!";
    }

    // Completing tasks
    if (lower.contains('done') || lower.contains('finished') || lower.contains('completed')) {
      return "That's wonderful! I'm so proud of you. What would you like to do next?";
    }

    // Water
    if (lower.contains('water') || lower.contains('drink') || lower.contains('thirsty')) {
      return "Great idea to stay hydrated! Have you had your glass of water today?";
    }

    // Walking
    if (lower.contains('walk') || lower.contains('exercise') || lower.contains('move')) {
      return "A short walk is great for your health! Even 5 minutes helps. Ready to take one?";
    }

    // Games
    if (lower.contains('game') || lower.contains('play') || lower.contains('memory')) {
      return "Memory games are wonderful for keeping your mind sharp! Would you like to play one now?";
    }

    // Help
    if (lower.contains('help') || lower.contains('how') || lower.contains('what can')) {
      return "I can help you with your daily activities, remind you about tasks, or just chat! What would you like?";
    }

    // Feeling queries
    if (lower.contains('tired') || lower.contains('sleepy')) {
      return "It's okay to rest when you need to. Would you like me to remind you about your tasks later?";
    }

    if (lower.contains('happy') || lower.contains('good') || lower.contains('great')) {
      return "I'm so happy to hear that! Your positive energy brightens my day too!";
    }

    if (lower.contains('sad') || lower.contains('lonely') || lower.contains('miss')) {
      return "I'm here for you. Would you like to connect with a friend or family member? They'd love to hear from you!";
    }

    // Default
    return _getPatternMatchedResponse(input);
  }

  /// Build context for Gemini
  Map<String, dynamic> _buildContext() {
    final hour = DateTime.now().hour;
    String timeOfDay;
    if (hour < 12) {
      timeOfDay = 'morning';
    } else if (hour < 17) {
      timeOfDay = 'afternoon';
    } else {
      timeOfDay = 'evening';
    }

    return {
      'timeOfDay': timeOfDay,
      'userName': _userName,
      'completedTasks': _completedTasks.join(', '),
      'missedTasks': _missedTasks.map((t) => t['task']).join(', '),
    };
  }

  /// Pattern match user input for scripted responses
  String _getPatternMatchedResponse(String input) {
    final lower = input.toLowerCase();

    // Medicine-related
    if (lower.contains('medicine') || lower.contains('meds') || lower.contains('pill')) {
      return _gemini.getScriptedResponse(AvatarScenario.userRememberedTask);
    }

    // Forgot/Don't remember
    if (lower.contains("don't remember") || lower.contains('forgot') || lower.contains('not sure')) {
      return _gemini.getScriptedResponse(AvatarScenario.userForgotTask, detail: 'your scheduled task');
    }

    // Yes/Okay responses
    if (lower.contains('yes') || lower.contains('okay') || lower.contains('sure') || lower.contains('ready')) {
      return _gemini.getScriptedResponse(AvatarScenario.routineConfirmed);
    }

    // No/Not now
    if (lower.contains('no') || lower.contains('not now') || lower.contains('later')) {
      return "That's okay! Take your time. I'll be here whenever you're ready.";
    }

    // Good/Thanks
    if (lower.contains('good') || lower.contains('great') || lower.contains('thank')) {
      return "Wonderful! I'm so glad. What would you like to do next?";
    }

    // Default encouraging response
    return "I hear you! That's great. Let's keep going with our day.";
  }

  /// Trigger morning greeting scenario
  Future<void> triggerMorningGreeting() async {
    _mood = AvatarMood.happy;
    final greeting = _gemini.getScriptedResponse(AvatarScenario.morningGreeting);
    await speak(greeting, mood: AvatarMood.happy);
  }

  /// Trigger missed task reminder (Socratic method)
  Future<void> triggerMissedTaskReminder(String task, String scheduledTime) async {
    _missedTasks.add({'task': task, 'time': scheduledTime});
    
    // Step 1: Gentle nudge
    final nudge = _gemini.getScriptedResponse(AvatarScenario.missedTaskNudge);
    await speak(nudge, mood: AvatarMood.encouraging);

    // Wait a moment then ask the question
    await Future.delayed(const Duration(seconds: 2));

    // Step 2: Ask the recall question
    final question = _gemini.getScriptedResponse(
      AvatarScenario.missedTaskQuestion,
      detail: scheduledTime,
    );
    await speak(question, mood: AvatarMood.thinking);
  }

  /// Handle game start
  Future<void> onGameStart() async {
    final message = _gemini.getScriptedResponse(AvatarScenario.gameStart);
    await speak(message, mood: AvatarMood.encouraging);
  }

  /// Handle game success
  Future<void> onGameSuccess() async {
    final message = _gemini.getScriptedResponse(AvatarScenario.gameSuccess);
    await speak(message, mood: AvatarMood.celebrating);
  }

  /// Handle game failure
  Future<void> onGameFailure() async {
    final message = _gemini.getScriptedResponse(AvatarScenario.gameFailure);
    await speak(message, mood: AvatarMood.encouraging);
  }

  /// Handle friend coming online
  Future<void> onFriendOnline(String friendName) async {
    final message = _gemini.getScriptedResponse(
      AvatarScenario.friendOnline,
      detail: friendName,
    );
    await speak(message, mood: AvatarMood.happy);
  }

  /// Handle evening wrap-up
  Future<void> triggerEveningWrapUp() async {
    final message = _gemini.getScriptedResponse(AvatarScenario.eveningWrapUp);
    await speak(message, mood: AvatarMood.happy);
  }

  /// Add a task to today's list
  void addTask(String task) {
    _todaysTasks.add(task);
    notifyListeners();
  }

  /// Mark a task as complete
  void completeTask(String task) {
    _todaysTasks.remove(task);
    _completedTasks.add(task);
    notifyListeners();
  }

  /// Reset for new day
  void resetDay() {
    _todaysTasks.clear();
    _completedTasks.clear();
    _missedTasks.clear();
    _gemini.resetChat();
    notifyListeners();
  }

  /// Set user name
  void setUserName(String name) {
    _userName = name;
    _storage.setString('user_name', name);
    notifyListeners();
  }

  @override
  void dispose() {
    _mouthTimer?.cancel();
    _speech.dispose();
    _gemini.dispose();
    super.dispose();
  }
}
