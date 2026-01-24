import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/game_provider.dart';
import 'providers/activity_provider.dart';
import 'services/local_storage_service.dart';
import 'screens/splash_screen.dart';
import 'screens/pin_entry_screen.dart';
import 'screens/role_select_screen.dart';
import 'screens/home_screen.dart';
import 'screens/difficulty_select_screen.dart';
import 'screens/game_screen.dart';
import 'screens/multiplayer_setup_screen.dart';
import 'screens/result_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/help_screen.dart';

/// Main entry point for the Luscid Memory Game app
/// An elderly-friendly memory matching game with Firebase integration
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize local storage service
  await LocalStorageService.init();

  // Set preferred orientations (portrait only for better UX)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF7F5F2),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const LuscidApp());
}

/// Root widget of the Luscid application
class LuscidApp extends StatelessWidget {
  const LuscidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication provider for PIN-based login
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Game state provider for single and multiplayer games
        ChangeNotifierProvider(create: (_) => GameProvider()),
        // Activity provider for daily checklist
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
      ],
      child: MaterialApp(
        title: 'Luscid - Memory Game',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,

        // Named routes for navigation
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/pin-entry': (context) => const PinEntryScreen(),
          '/role-select': (context) => const RoleSelectScreen(),
          '/home': (context) => const HomeScreen(),
          '/difficulty-select': (context) => const DifficultySelectScreen(),
          '/game': (context) => const GameScreen(),
          '/multiplayer-setup': (context) => const MultiplayerSetupScreen(),
          '/result': (context) => const ResultScreen(),
          '/activities': (context) => const ActivityScreen(),
          '/help': (context) => const HelpScreen(),
        },

        // Custom page transitions for elderly-friendly navigation
        onGenerateRoute: (settings) {
          // Add custom transitions if needed
          return null;
        },

        // Handle unknown routes
        onUnknownRoute: (settings) {
          return MaterialPageRoute(builder: (context) => const SplashScreen());
        },
      ),
    );
  }
}
