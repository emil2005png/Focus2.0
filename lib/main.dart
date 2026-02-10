import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:focus_app/screens/home_screen.dart';
import 'package:focus_app/services/auth_service.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:focus_app/screens/mood_checkin_screen.dart';
import 'package:focus_app/screens/email_verification_screen.dart';
import 'package:focus_app/screens/splash_screen.dart';
import 'package:focus_app/widgets/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FocusApp());
}

class FocusApp extends StatelessWidget {
  const FocusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

