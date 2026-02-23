import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/services/firestore_service.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> with TickerProviderStateMixin {
  int _focusTime = 25 * 60; 
  int _secondsRemaining = 25 * 60;
  double _selectedMinutes = 25;
  Timer? _timer;
  bool _isRunning = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startTimer() {
    if (_timer != null) return;
    setState(() => _isRunning = true);
    _pulseController.repeat(reverse: true); // Start pulsing
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _stopTimer();
          _showCompletionDialog();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _pulseController.stop(); // Stop pulsing
    _pulseController.reset();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    setState(() {
      _focusTime = (_selectedMinutes * 60).toInt();
      _secondsRemaining = _focusTime;
    });
  }

  void _updateDuration(double value) {
    if (_isRunning) return;
    setState(() {
      _selectedMinutes = value;
      _focusTime = (value * 60).toInt();
      _secondsRemaining = _focusTime;
    });
  }

  void _showCompletionDialog() {
    // Save focus stats to Firestore
    final focusMinutes = (_focusTime / 60).round();
    FirestoreService().updateFocusStats(focusMinutes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Focus Session Complete!", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text("Great job! Take a short break."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = _focusTime > 0 ? 1 - (_secondsRemaining / _focusTime) : 0;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Focus Timer', style: GoogleFonts.outfit(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing Background
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.1),
                    ),
                  ),
                ),
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 15,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    strokeCap: StrokeCap.round, 
                  ),
                ),
                Text(
                  _formatTime(_secondsRemaining),
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            
            // Duration Slider
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isRunning ? 0.0 : 1.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text(
                      "Duration: ${_selectedMinutes.toInt()} min",
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    Slider(
                      value: _selectedMinutes,
                      min: 5,
                      max: 120,
                      divisions: 23,
                      label: "${_selectedMinutes.toInt()} min",
                      activeColor: primaryColor,
                      onChanged: _isRunning ? null : _updateDuration,
                    ),
                  ],
                ),
              ),
            ),
             SizedBox(height: _isRunning ? 0 : 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: _isRunning ? Colors.orange : Colors.green,
                  onPressed: _isRunning ? _stopTimer : _startTimer,
                ),
                const SizedBox(width: 24),
                _buildControlButton(
                  icon: Icons.refresh_rounded,
                  color: Colors.grey,
                  onPressed: _resetTimer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 36),
      ),
    );
  }
}
