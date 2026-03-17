import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:focus_app/services/points_service.dart';
import 'package:focus_app/models/focus_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:focus_app/services/notification_service.dart';
import 'package:focus_app/services/quote_service.dart';


class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

enum TimerMode { focus }

class _FocusTimerScreenState extends State<FocusTimerScreen> with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final PointsService _pointsService = PointsService();
  final QuoteService _quoteService = QuoteService();
  bool _hasAutoStarted = false;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  TimerMode _mode = TimerMode.focus;
  int _secondsRemaining = (25 + 5) * 60;
  int _totalSessionDuration = (25 + 5) * 60;
  int _actualSecondsSpent = 0;
  
  double _selectedFocusMinutes = 25;
  double _selectedBreakMinutes = 5;
  
  Timer? _timer;
  bool _isRunning = false;
  bool _autoStartBreak = true;
  bool _isAlarmEnabled = false;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _purposeController = TextEditingController();

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
    
    // Initialize durations
    _totalSessionDuration = ((_selectedFocusMinutes + _selectedBreakMinutes) * 60).toInt();
    _secondsRemaining = _totalSessionDuration;
    _checkForDistractionAutostart();
  }

  Future<void> _checkForDistractionAutostart() async {
    if (_hasAutoStarted || _isRunning) return;

    final distractions = await _firestoreService.getTodayDistractions();
    int totalMinutes = 0;
    for (var d in distractions) {
      totalMinutes += (d['durationMinutes'] as int? ?? 0);
    }

    if (totalMinutes >= 60 && mounted) {
      setState(() {
        _hasAutoStarted = true;
      });
      
      _startTimer();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_quoteService.getRandomQuote()} (Distraction: ${totalMinutes}m)',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _startTimer() {
    if (_timer != null) return;
    setState(() {
      _isRunning = true;
      _isAlarmEnabled = true; // Auto-toggle alarm on
    });
    _pulseController.repeat(reverse: true);

    // Schedule background alarm if focus portion is active
    if (_isAlarmEnabled && _secondsRemaining > (_selectedBreakMinutes * 60)) {
      final focusSecondsLeft = _secondsRemaining - (_selectedBreakMinutes * 60);
      NotificationService().scheduleAlarm(
        1001,
        "Focus Session Complete! 🔔",
        "Your focus time is up. Starting your ${_selectedBreakMinutes.toInt()} min break now.",
        DateTime.now().add(Duration(seconds: focusSecondsLeft.toInt())),
      );
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          
          if (_mode == TimerMode.focus) {
            // Only count actual seconds spent during focus portion
            if (_secondsRemaining >= (_selectedBreakMinutes * 60).toInt()) {
              _actualSecondsSpent++;
            }
            
            // Focus portion complete? (hitting the break threshold)
            if (_secondsRemaining == (_selectedBreakMinutes * 60).toInt()) {
              _onFocusPortionComplete();
            }
          }
          
          // Reminder every 30 mins (total time)
          if ((_totalSessionDuration - _secondsRemaining) % (30 * 60) == 0 && (_totalSessionDuration - _secondsRemaining) > 0) {
            _showReminderNotification();
          }
        } else {
          _onTimerComplete();
        }
      });
    });
  }

  void _onFocusPortionComplete() {
    // Session is saved here. Notification is handled by the scheduled alarm/system.
    _saveSession();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Focus time complete! Break starting."),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showReminderNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("You've been focusing for 30 minutes. Consider a short break!"),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _onTimerComplete() {
    _stopTimer();
    _showCompletionDialog();
    _switchMode(TimerMode.focus); // Reset to start state
  }

  void _saveSession() {
    if (_userId == null) return;
    
    final session = FocusSession(
      userId: _userId,
      startTime: DateTime.now().subtract(Duration(seconds: _actualSecondsSpent)),
      endTime: DateTime.now(),
      focusDuration: Duration(minutes: _selectedFocusMinutes.toInt()),
      actualFocusDuration: Duration(seconds: _actualSecondsSpent),
      purpose: _purposeController.text.isEmpty ? "Focus Session" : _purposeController.text,
      isCompleted: _secondsRemaining == 0,
    );
    
    _firestoreService.saveFocusSession(session);
    _firestoreService.updateFocusStats(session.actualFocusDuration.inMinutes, session.purpose);
    _pointsService.awardFocusSession(session.actualFocusDuration.inMinutes);
    _actualSecondsSpent = 0;
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _pulseController.stop();
    _pulseController.reset();
    NotificationService().cancel(1001); // Cancel scheduled alarm on stop/pause
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _stopTimer();
    NotificationService().cancel(1001);
    _actualSecondsSpent = 0;
    _switchMode(_mode);
  }

  void _switchMode(TimerMode mode) {
    setState(() {
      _mode = mode;
      _totalSessionDuration = ((_selectedFocusMinutes + _selectedBreakMinutes) * 60).toInt();
      _secondsRemaining = _totalSessionDuration;
    });
  }

  void _updateFocusDuration(double value) {
    if (_isRunning || _mode != TimerMode.focus) return;
    setState(() {
      _selectedFocusMinutes = value;
      _totalSessionDuration = ((value + _selectedBreakMinutes) * 60).toInt();
      _secondsRemaining = _totalSessionDuration;
    });
  }

  void _updateBreakDuration(double value) {
    if (_isRunning) return;
    setState(() {
      _selectedBreakMinutes = value;
      _totalSessionDuration = ((_selectedFocusMinutes + value) * 60).toInt();
      _secondsRemaining = _totalSessionDuration;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Session Complete! 🎉", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text("Amazing work. Time for a well-deserved break."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Great!")),
        ],
      ),
    );
  }


  void _showExitWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("End Session?", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: const Text("Leaving now will stop your focus timer. Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Stay")),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _resetTimer();
              Navigator.pop(context); // Exit screen
            },
            child: const Text("End & Exit", style: TextStyle(color: Colors.red)),
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
    _purposeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = _totalSessionDuration > 0 ? 1 - (_secondsRemaining / _totalSessionDuration) : 0;
    final primaryColor = _mode == TimerMode.focus ? Theme.of(context).primaryColor : Colors.teal;

    return PopScope(
      canPop: !_isRunning,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isRunning) {
          _showExitWarning();
        }
      },
      child: Scaffold(
        backgroundColor: _isRunning ? Colors.black.withValues(alpha: 0.05) : Theme.of(context).scaffoldBackgroundColor,
      appBar: _isRunning ? null : AppBar( // Hide app bar during session for distraction-free
        title: Text('Focus Timer', style: GoogleFonts.outfit(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(_autoStartBreak ? Icons.flash_on : Icons.flash_off, size: 20),
            onPressed: () => setState(() => _autoStartBreak = !_autoStartBreak),
            tooltip: "Auto-start Break",
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: _isRunning ? 80 : 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mode indicator
                if (!_isRunning)
                const SizedBox(height: 30),
                
                // Purpose Input (Hidden during break)
                if (_mode == TimerMode.focus)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: TextField(
                    controller: _purposeController,
                    enabled: !_isRunning,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "What are you working on?",
                      border: _isRunning ? InputBorder.none : OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: !_isRunning,
                      fillColor: Colors.white.withValues(alpha: 0.5),
                    ),
                    style: GoogleFonts.outfit(
                      fontSize: _isRunning ? 24 : 16,
                      fontWeight: _isRunning ? FontWeight.bold : FontWeight.normal,
                      color: _isRunning ? primaryColor : Colors.black87,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryColor.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        strokeCap: StrokeCap.round, 
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(_secondsRemaining),
                          style: GoogleFonts.outfit(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        Text(
                          _secondsRemaining > (_selectedBreakMinutes * 60) ? "FOCUSING" : "BREAK TIME",
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            letterSpacing: 4,
                            fontWeight: FontWeight.bold,
                            color: primaryColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                
                // Duration Sliders (Only if not running)
                if (!_isRunning)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Text(
                        "Focus Duration: ${_selectedFocusMinutes.toInt()} min",
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Slider(
                        value: _selectedFocusMinutes,
                        min: 1,
                        max: 120,
                        divisions: 119,
                        activeColor: primaryColor,
                        onChanged: (v) => _updateFocusDuration(v),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Break Duration: ${_selectedBreakMinutes.toInt()} min",
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Slider(
                        value: _selectedBreakMinutes,
                        min: 1,
                        max: 30,
                        divisions: 29,
                        activeColor: Colors.teal,
                        onChanged: (v) => _updateBreakDuration(v),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Total Session: ${(_selectedFocusMinutes + _selectedBreakMinutes).toInt()} min",
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                    ],
                  ),
                ),
  
                const SizedBox(height: 30),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRunning)
                    _buildControlButton(
                      icon: Icons.stop_rounded,
                      color: Colors.redAccent,
                      onPressed: () {
                        if (_mode == TimerMode.focus && _actualSecondsSpent > 60) {
                          _saveSession();
                        }
                        _resetTimer();
                      },
                    ),
                    if (_isRunning) const SizedBox(width: 30),
                    _buildControlButton(
                      icon: _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: _isRunning ? Colors.orange : (_mode == TimerMode.focus ? Colors.green : Colors.teal),
                      onPressed: _isRunning ? _stopTimer : _startTimer,
                    ),
                    if (!_isRunning) ...[
                      const SizedBox(width: 30),
                      Column(
                        children: [
                          _buildControlButton(
                            icon: _isAlarmEnabled ? Icons.notifications_active : Icons.notifications_off,
                            color: _isAlarmEnabled ? Colors.blueAccent : Colors.grey,
                            onPressed: () => setState(() => _isAlarmEnabled = !_isAlarmEnabled),
                          ),
                          const SizedBox(height: 4),
                          Text("Focus Alarm", style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[600])),
                        ],
                      ),
                    ]
                  ],
                ),
                
                // Cancel button during session
                if (_isRunning)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: TextButton(
                    onPressed: () => _resetTimer(),
                    child: Text("CANCEL SESSION", style: GoogleFonts.outfit(color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}