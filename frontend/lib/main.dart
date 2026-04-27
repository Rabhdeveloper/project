import 'package:flutter/material.dart';
import 'screens/main_layout.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

void main() {
  runApp(const SmartStudyTrackerApp());
}

class SmartStudyTrackerApp extends StatelessWidget {
  const SmartStudyTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Study & Productivity',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData.light(), // Fallback
      darkTheme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _onboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final onboarded = prefs.getBool('onboarding_complete') ?? false;
    
    setState(() {
      _isAuthenticated = token != null;
      _onboardingComplete = onboarded;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (!_onboardingComplete) {
      return const OnboardingScreen();
    }
    return _isAuthenticated ? const MainLayout() : const LoginScreen();
  }
}
