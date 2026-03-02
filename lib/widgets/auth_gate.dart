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

import 'package:shared_preferences/shared_preferences.dart';

class AuthGate extends StatefulWidget {
  final bool initialInspirationShown;
  const AuthGate({super.key, this.initialInspirationShown = false});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late bool _hasShownInspiration;
  bool _checkedDailyFlowPreference = false;
  bool _shouldSkipDailyFlow = false;

  @override
  void initState() {
    super.initState();
    _hasShownInspiration = widget.initialInspirationShown;
    _checkDailyFlowPreference();
  }

  Future<void> _checkDailyFlowPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastFlowDate = prefs.getString('last_daily_flow_date');
    
    if (lastFlowDate == today) {
      if (mounted) {
        setState(() {
          _shouldSkipDailyFlow = true;
          _hasShownInspiration = true;
          _checkedDailyFlowPreference = true;
        });
      }
    } else {
      // Mark flow as started for today so it doesn't repeat
      await prefs.setString('last_daily_flow_date', today);
      if (mounted) {
        setState(() {
          _checkedDailyFlowPreference = true;
        });
      }
    }
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
        if (snapshot.connectionState == ConnectionState.waiting || !_checkedDailyFlowPreference) {
           return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData) {
          final user = snapshot.data;
          
          // 1. Check Verification
          if (user != null && !user.emailVerified) {
            return const EmailVerificationScreen();
          }

          // If we should skip the daily flow, go straight to Home
          if (_shouldSkipDailyFlow) {
            return const HomeScreen();
          }

          // 2. Inspiration Message (Once per day sequence)
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
