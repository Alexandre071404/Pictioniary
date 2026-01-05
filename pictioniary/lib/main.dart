import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/drawing_screen.dart';
import 'screens/guessing_wait_screen.dart';
import 'screens/results_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PICTION.IA.RY',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF10B981),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        useMaterial3: true,
        fontFamily: 'Roboto',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.12),
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF6366F1),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.08),
          shadowColor: Colors.black54,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
      home: const LoginScreen(),
      routes: {
        '/drawing': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return DrawingScreen(
            gameSessionId: args['gameSessionId'],
            playerData: args['playerData'],
          );
        },
        '/guessing_wait': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return GuessingWaitScreen(
            gameSessionId: args['gameSessionId'],
            playerData: args['playerData'],
          );
        },
        '/results': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ResultsScreen(
            gameSessionId: args['gameSessionId'],
            playerData: args['playerData'],
          );
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
