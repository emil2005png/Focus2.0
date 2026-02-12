import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:focus_app/services/auth_service.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:focus_app/screens/home_screen.dart';
import 'package:focus_app/screens/login_screen.dart';
import 'package:focus_app/screens/mood_checkin_screen.dart';
import 'package:focus_app/screens/email_verification_screen.dart';

import 'package:focus_app/screens/inspirational_message_screen.dart';
import 'package:focus_app/screens/mini_focus_game_screen.dart';

class AuthGate extends StatefulWidget {
  final bool initialInspirationShown;
  const AuthGate({super.key, this.initialInspirationShown = false});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late bool _hasShownInspiration;

  @override
  void initState() {
    super.initState();
    _hasShownInspiration = widget.initialInspirationShown;
  }

  Future<Map<String, bool>> _checkDailyProgress() async {
     final mood = await FirestoreService().hasCheckedInToday();
     final game = await FirestoreService().hasPlayedMiniGameToday();
     return {'mood': mood, 'game': game};
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData) {
          final user = snapshot.data;
          
          // 1. Check Verification
          if (user != null && !user.emailVerified) {
            return const EmailVerificationScreen();
          }

          // 2. Inspiration Message (Once per session loop)
          if (!_hasShownInspiration) {
             return InspirationalMessageScreen(
               onDone: () {
                 if (mounted) setState(() => _hasShownInspiration = true);
               }
             );
          }

          // 3. User is logged in and verified, check progress
          return FutureBuilder<Map<String, bool>>(
            future: _checkDailyProgress(),
            builder: (context, checkInSnapshot) {
              if (checkInSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              final data = checkInSnapshot.data ?? {'mood': false, 'game': false};
              final moodDone = data['mood']!;
              final gameDone = data['game']!;
              
              if (!moodDone) {
                return const MoodCheckInScreen();
              } else if (!gameDone) {
                return const MiniFocusGameScreen();
              } else {
                return const HomeScreen();
              }
            },
          );
        }
        
        return const LoginScreen();
      },
    );
  }
}
