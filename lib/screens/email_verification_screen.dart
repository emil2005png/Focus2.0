import 'dart:async';
import 'package:flutter/material.dart';
import 'package:focus_app/services/auth_service.dart';
import 'package:focus_app/screens/home_screen.dart';
import 'package:focus_app/screens/mood_checkin_screen.dart';
import 'package:focus_app/widgets/auth_gate.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();

    // Check if email is already verified
    isEmailVerified = AuthService().currentUser?.emailVerified ?? false;

    if (!isEmailVerified) {
      sendVerificationEmail();

      // Check for email verification every 3 seconds
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    // Reload user to get latest status
    await AuthService().reloadUser();
    
    setState(() {
      isEmailVerified = AuthService().currentUser?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      timer?.cancel();
      // AuthGate will handle the navigation, but we can also manually push if needed.
      // Since AuthGate listens to the stream, it might not catch the 'reload' instantly
      // without a proper stream update, but authStateChanges typically fires on sign in/out.
      // For attribute changes like emailVerified, we might need to rely on this manual check
      // or force a refresh. 
      
      // Let's just wait for the user to click "I've Verified" or rely on AuthGate rebuilding
      // if the stream doesn't fire, we might need to manually trigger navigation.
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      await AuthService().sendEmailVerification();
      
      setState(() {
        canResendEmail = false;
      });
      
      await Future.delayed(const Duration(seconds: 5));
      
      if (mounted) {
        setState(() {
          canResendEmail = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEmailVerified) {
      // If verified, show a success message or generic "Continue" 
      // In a real flow, AuthGate would key off this and swap the widget.
      // But if we are stuck here, we can provide a button to continue.
      return const AuthGate(); 
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined, size: 100, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Verify your email address',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We have sent a verification email to ${AuthService().currentUser?.email}. Please verify your email to continue.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            const Text(
              'Verifying automatically...',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
               onPressed: canResendEmail ? sendVerificationEmail : null,
              child: const Text('Resend Email'),
            ),
            const SizedBox(height: 16),
             TextButton(
              onPressed: () => AuthService().signOut(), // Allow them to switch accounts
              child: const Text('Cancel / Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
