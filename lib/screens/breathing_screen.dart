import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _instruction = "Inhale";

  @override
  void initState() {
    super.initState();
    // 4s Inhale, 4s Hold, 4s Exhale, 4s Hold = 16s cycle
    _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 16),
  )..repeat();

    _controller.addListener(() {
      final value = _controller.value;
      setState(() {
        if (value < 0.25) {
          _instruction = "Inhale";
        } else if (value < 0.5) {
          _instruction = "Hold";
        } else if (value < 0.75) {
          _instruction = "Exhale";
        } else {
          _instruction = "Hold";
        }
      });
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
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Text('Breathing Exercise', style: GoogleFonts.outfit(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Manually handle scale based on phases for fuller control if needed
                // Using controller value for size simulation
                double scale = 1.0;
                double val = _controller.value;
                if (val < 0.25) {
                  scale = 1.0 + (val / 0.25) * 0.5; // Grow 1.0 -> 1.5
                } else if (val < 0.5) {
                  scale = 1.5; // Stay
                } else if (val < 0.75) {
                   scale = 1.5 - ((val - 0.5) / 0.25) * 0.5; // Shrink 1.5 -> 1.0
                } else {
                  scale = 1.0; // Stay
                }

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Colors.blue[200]!, Colors.blue[600]!],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _instruction,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 60),
             Text(
              "Follow the rhythm",
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
