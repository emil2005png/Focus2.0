import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:focus_app/services/auth_service.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:focus_app/screens/home_screen.dart';
import 'package:focus_app/screens/login_screen.dart';
import 'package:focus_app/screens/mood_checkin_screen.dart';
import 'package:focus_app/screens/email_verification_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

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
          
          if (user != null && !user.emailVerified) {
            return const EmailVerificationScreen();
          }

          // User is logged in and verified, check if they have done mood check-in today
          return FutureBuilder<bool>(
            future: FirestoreService().hasCheckedInToday(),
            builder: (context, checkInSnapshot) {
              if (checkInSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              final hasCheckedIn = checkInSnapshot.data ?? false;
              
              if (hasCheckedIn) {
                return const HomeScreen();
              } else {
                return const MoodCheckInScreen();
              }
            },
          );
        }
        
        return const LoginScreen();
      },
    );
  }
}
