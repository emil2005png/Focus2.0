import 'dart:async';
import 'package:flutter/material.dart';
import 'package:focus_app/widgets/auth_gate.dart';
import 'package:focus_app/screens/mini_focus_game_screen.dart';

class QuoteScreen extends StatefulWidget {
  final String quote;

  const QuoteScreen({super.key, required this.quote});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Navigate to Home after 3 seconds
    _timer = Timer(const Duration(seconds: 3), _navigateToHome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MiniFocusGameScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: InkWell(
        onTap: _navigateToHome, // Allow tap to skip
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.format_quote,
                  size: 64,
                  color: Colors.white70,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.quote,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                const CircularProgressIndicator(
                  color: Colors.white30,
                  strokeWidth: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
