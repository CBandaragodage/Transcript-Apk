import 'package:flutter/material.dart';

// Imports
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_home_screen.dart'; 
import 'screens/live_transcription_screen.dart'; // Ensure file exists at lib/screens/live_transcription_page.dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SLT VoiceNotes',
      
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0072CE),
          secondary: Color(0xFF00C853),
          surface: Color(0xFF161B22),
        ),
        useMaterial3: true,
      ),

      initialRoute: '/login',

      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/dashboard': (context) => const DashboardHomeScreen(),
        '/transcription': (context) => const LiveTranscriptionPage(),
        
      },
    );
  }
}