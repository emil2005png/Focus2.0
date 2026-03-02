import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/screens/focus_timer_screen.dart';
import 'package:focus_app/screens/breathing_screen.dart';
import 'package:focus_app/screens/quote_screen.dart';
import 'package:focus_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WellnessToolsScreen extends StatefulWidget {
  const WellnessToolsScreen({super.key});

  @override
  State<WellnessToolsScreen> createState() => _WellnessToolsScreenState();
}

class _WellnessToolsScreenState extends State<WellnessToolsScreen> {
  bool _waterReminder = false;
  bool _focusReset = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterReminder = prefs.getBool('water_reminder') ?? false;
      _focusReset = prefs.getBool('focus_reset') ?? false;
    });
  }

  Future<void> _toggleWaterReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterReminder = value;
    });
    await prefs.setBool('water_reminder', value);

    if (value) {
      await NotificationService().scheduleHydrationReminders();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Water reminders enabled (Every 2h)! 💧")));
    } else {
      await NotificationService().cancelHydrationReminders();
    }
  }

  Future<void> _toggleFocusReset(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _focusReset = value;
    });
    await prefs.setBool('focus_reset', value);

    if (value) {
      await NotificationService().scheduleFocusReset(); // ID 2
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Focus Reset reminders enabled! 🧘")));
    } else {
      await NotificationService().cancel(2); // ID 2 for focus
    }
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: Text('Wellness Tools', style: GoogleFonts.outfit(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Tools"),
            const SizedBox(height: 12),
            _buildToolCard(
              context,
              title: "Focus Timer",
              description: "25-minute Pomodoro timer",
              icon: Icons.timer,
              color: Colors.deepPurple,
              destination: const FocusTimerScreen(),
            ),
            const SizedBox(height: 16),
            _buildToolCard(
              context,
              title: "Breathing Exercise",
              description: "2-minute guided relaxation",
              icon: Icons.air,
              color: Colors.blue,
              destination: const BreathingScreen(),
            ),
            const SizedBox(height: 16),
             _buildToolCard(
              context,
              title: "Daily Inspiration",
              description: "Get motivated with quotes",
              icon: Icons.format_quote,
              color: Colors.amber,
              destination: const QuoteScreen(),
            ),
            const SizedBox(height: 32),

            _buildSectionHeader("Reminders"),
            const SizedBox(height: 12),
            _buildReminderCard(
              title: "Hydration Check",
              description: "Every 2 hours reminder to drink water",
              icon: Icons.water_drop,
              color: Colors.cyan,
              value: _waterReminder,
              onChanged: _toggleWaterReminder,
            ),
            const SizedBox(height: 16),
            _buildReminderCard(
              title: "Focus Reset",
              description: "Periodic friendly nudges",
              icon: Icons.self_improvement,
              color: Colors.green,
              value: _focusReset,
              onChanged: _toggleFocusReset,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildReminderCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
           Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                   Text(
                    description,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: color,
            ),
        ],
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
             BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                   Text(
                    description,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
