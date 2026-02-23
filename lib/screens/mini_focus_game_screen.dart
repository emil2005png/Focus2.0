import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Assuming google_fonts is used based on pubspec
import 'package:focus_app/screens/home_screen.dart';
import 'package:focus_app/services/firestore_service.dart';

class MiniFocusGameScreen extends StatefulWidget {
  const MiniFocusGameScreen({super.key});

  @override
  State<MiniFocusGameScreen> createState() => _MiniFocusGameScreenState();
}

class _MiniFocusGameScreenState extends State<MiniFocusGameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHolding = false;
  String _instructionText = "Hold to Focus";
  // The duration for the focus game
  static const int _focusDurationSeconds = 10;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: _focusDurationSeconds));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onFocusComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _isHolding = true;
      _instructionText = "Keep Holding...";
    });
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _resetGame();
  }

  void _onTapCancel() {
    _resetGame();
  }

  void _resetGame() {
    if (_controller.isCompleted) return; // Don't reset if already done

    setState(() {
      _isHolding = false;
      _instructionText = "Hold to Focus";
    });
    _controller.reset();
  }

  Future<void> _onFocusComplete() async {
    setState(() {
      _instructionText = "Focus Locked!";
    });

    // Save Focus Stats & Record Game — await so Firestore is updated
    // before we navigate away (prevents the gate from re-showing the game).
    await FirestoreService().recordMiniGamePlayed(1);

    // Navigate directly to HomeScreen — bypasses AuthGate re-evaluation
    // which would re-check Firestore and show the game a second time.
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _instructionText,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background Circle
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withOpacity(0.2),
                      boxShadow: _isHolding
                          ? [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ]
                          : [],
                    ),
                  ),
                  // Progress Indicator
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return CircularProgressIndicator(
                          value: _controller.value,
                          strokeWidth: 8,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor),
                        );
                      },
                    ),
                  ),
                  // Icon
                  Icon(
                    _isHolding ? Icons.lock_clock : Icons.fingerprint,
                    size: 80,
                    color: _isHolding
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
             // Countdown text
             AnimatedBuilder(
                animation: _controller,
                builder:(context, child) {
                    if (!_isHolding && !_controller.isCompleted) return const SizedBox.shrink();
                     int remaining = _focusDurationSeconds - (_controller.value * _focusDurationSeconds).floor();
                     if (remaining <= 0) return const Text("Done!", style: TextStyle(fontWeight: FontWeight.bold));
                     return Text(
                        "$remaining s",
                         style: Theme.of(context).textTheme.titleLarge,
                     );
                }
             )
          ],
        ),
      ),
    );
  }
}
