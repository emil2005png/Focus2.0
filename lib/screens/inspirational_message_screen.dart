import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InspirationalMessageScreen extends StatefulWidget {
  final VoidCallback onDone;

  const InspirationalMessageScreen({super.key, required this.onDone});

  @override
  State<InspirationalMessageScreen> createState() => _InspirationalMessageScreenState();
}

class _InspirationalMessageScreenState extends State<InspirationalMessageScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation; // Opacity
  late Animation<Offset> _slideAnimation; // Position

  final List<String> _quotes = [
    "Believe you can and you're halfway there.",
    "The only way to do great work is to love what you do.",
    "Your limitation—it's only your imagination.",
    "Push yourself, because no one else is going to do it for you.",
    "Great things never come from comfort zones.",
    "Dream it. Wish it. Do it.",
    "Success doesn't just find you. You have to go out and get it.",
    "The harder you work for something, the greater you'll feel when you achieve it.",
    "Dream bigger. Do bigger.",
    "Don't stop when you're tired. Stop when you're done.",
    "Wake up with determination. Go to bed with satisfaction.",
    "Do something today that your future self will thank you for.",
    "Little things make big days.",
    "It's going to be hard, but hard does not mean impossible.",
    "Don't wait for opportunity. Create it.",
    "Sometimes we're tested not to show our weaknesses, but to discover our strengths.",
    "The key to success is to focus on goals, not obstacles.",
    "Dream it. Believe it. Build it.",
  ];

  late String _quote;

  @override
  void initState() {
    super.initState();
    _quote = _quotes[Random().nextInt(_quotes.length)];

    _controller = AnimationController(
    duration: const Duration(seconds: 2), // Animation duration (fade in/slide up)
      vsync: this,
    );
     
    // Fade in
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    // Slide up slightly
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), 
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));


    _controller.forward();

    // Timer to finish
    Timer(const Duration(seconds: 3), () {
        if (mounted) {
            widget.onDone();
        }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    "Daily Inspiration",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.grey[500],
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    _quote,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit( // Using a nice font
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87, 
                      height: 1.3,
                    ),
                  ),
                   const SizedBox(height: 30),
                   // Optional: Loading indicator or just static
                   SizedBox(
                     width: 40,
                     height: 40,
                     child: CircularProgressIndicator(
                       strokeWidth: 2,
                       valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                     ),
                   )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
