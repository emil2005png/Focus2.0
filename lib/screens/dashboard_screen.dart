import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:focus_app/screens/journal_entry_screen.dart';
import 'package:focus_app/screens/mood_checkin_screen.dart';
// import 'package:focus_app/screens/mini_focus_game_screen.dart'; 
// Note: We need to import MiniFocusGame, but it might be circularly dependent if not careful. 
// Ideally HomeScreen handles navigation, but QuickActions need to navigate.
// For now, let's assume we can navigate to these screens.

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // Mock Quotes for now (or move to a service)
  final List<String> _quotes = [
    "The secret of getting ahead is getting started.",
    "Focus on being productive instead of busy.",
    "Your future is created by what you do today, not tomorrow.",
    "Don't watch the clock; do what it does. Keep going.",
    "Starve your distraction and feed your focus.",
  ];
  late String _dailyQuote;

  @override
  void initState() {
    super.initState();
    _dailyQuote = _quotes[Random().nextInt(_quotes.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome & Date
            Text(
              DateFormat('EEEE, MMM d').format(DateTime.now()),
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome Back!',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Daily Quote Card
            _buildQuoteCard(),
            const SizedBox(height: 24),

            // Streak & Stats Row
            StreamBuilder<DocumentSnapshot>(
              stream: _firestoreService.getUserStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final streak = data?['currentStreak'] ?? 0;
                final minutes = data?['totalFocusMinutes'] ?? 0;
                return Row(
                  children: [
                    Expanded(child: _buildStatCard('Streak', '$streak Days', Icons.local_fire_department, Colors.orange)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Focus Time', '$minutes mins', Icons.timer, Colors.blue)),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Mood Chart
            Text(
              'Mood History',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _firestoreService.getMoodsForLast7Days(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                     return Center(child: Text("No mood data yet", style: TextStyle(color: Colors.grey[400])));
                  }
                  return _buildMoodChart(snapshot.data!);
                },
              ),
            ),
            const SizedBox(height: 24),

            const SizedBox(height: 24), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      // ... (rest of method unchanged)
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[400]!, Colors.blue[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote, color: Colors.white70, size: 30),
          const SizedBox(height: 8),
          Text(
            _dailyQuote,
            style: GoogleFonts.patrickHand(
              fontSize: 22,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Daily Inspiration",
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChart(List<Map<String, dynamic>> moods) {
    // Map moods to values: 😊=5, 🤩=5, 😌=4, 😐=3, 😔=2, 😰=1, 😴=3
    double getMoodValue(String mood) {
      switch (mood) {
        case '🤩': return 5;
        case '😊': return 4;
        case '😌': return 4;
        case '😐': return 3;
        case '😴': return 3;
        case '😔': return 2;
        case '😰': return 1;
        default: return 3;
      }
    }

    // Prepare spots
    List<FlSpot> spots = [];
    for (int i = 0; i < moods.length; i++) {
        spots.add(FlSpot(i.toDouble(), getMoodValue(moods[i]['mood'])));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (moods.length - 1).toDouble(),
        minY: 0,
        maxY: 6,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.purple,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
