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

import 'package:focus_app/screens/log_distraction_screen.dart';

import 'package:focus_app/screens/distraction_stats_screen.dart';

import 'package:focus_app/services/advice_service.dart';
import 'package:focus_app/screens/wellness_tools_screen.dart';
import 'package:focus_app/screens/distraction_summary_screen.dart';
import 'package:focus_app/screens/breathing_screen.dart';
import 'package:focus_app/screens/focus_timer_screen.dart';
import 'package:focus_app/screens/reflection_screen.dart';
import 'package:focus_app/widgets/fade_in_animation.dart';
import 'package:focus_app/widgets/glass_container.dart';
import 'package:focus_app/widgets/bouncy_button.dart';
import 'package:focus_app/widgets/daily_planning_widget.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/services/quote_service.dart';
import 'package:focus_app/widgets/dashboard_feature_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<AdviceItem?> _adviceFuture;
  final QuoteService _quoteService = QuoteService();
  late String _dailyQuote;

  @override
  void initState() {
    super.initState();
    _dailyQuote = _quoteService.getRandomQuote();
    _adviceFuture = _getAdvice();
  }

  Future<AdviceItem?> _getAdvice() async {
    final distractions = await _firestoreService.getTodayDistractions();
    final mood = await _firestoreService.getTodayMood();
    
    int totalMinutes = 0;
    for (var d in distractions) {
      totalMinutes += (d['durationMinutes'] as int? ?? 0);
    }
    
    return AdviceService().generateAdvice(
      totalDistractionMinutes: totalMinutes,
      currentMood: mood,
      distractionCount: distractions.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Staggered delays
    const duration = Duration(milliseconds: 600);
    const step = Duration(milliseconds: 100);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInAnimation(
                    duration: duration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d').format(DateTime.now()),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome Back!',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Daily Quote Card
                  FadeInAnimation(
                    delay: step,
                    duration: duration,
                    child: _buildQuoteCard(),
                  ),
                  const SizedBox(height: 24),

                  // Advice Card (Dynamic)
                  FutureBuilder<AdviceItem?>(
                    future: _adviceFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return FadeInAnimation(
                          delay: step * 2,
                          duration: duration,
                          child: Column(
                             children: [
                              _buildAdviceCard(snapshot.data!),
                              const SizedBox(height: 24),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Daily Planning Widget
                  FadeInAnimation(
                    delay: step * 2,
                    duration: duration,
                    child: Column(
                      children: const [
                        DailyPlanningWidget(),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // Tracker Card (New Entry Point)
                  FadeInAnimation(
                    delay: step * 2,
                    duration: duration,
                    child: Column(
                      children: [
                        DashboardFeatureCard(
                          title: "Distraction Tracker",
                          subtitle: "Log & View Insights",
                          icon: Icons.track_changes_outlined,
                          gradient: AppGradients.orange,
                          iconColor: Colors.orange,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DistractionStatsScreen())),
                        ),
                        const SizedBox(height: 16),
                        DashboardFeatureCard(
                          title: "Weekly Summary",
                          subtitle: "Analyze your week",
                          icon: Icons.summarize_outlined,
                          gradient: AppGradients.primary,
                          iconColor: Theme.of(context).primaryColor,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DistractionSummaryScreen())),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Wellness Tools Card
                  FadeInAnimation(
                    delay: step * 3,
                    duration: duration,
                  child: DashboardFeatureCard(
                    title: "Wellness Tools",
                    subtitle: "Timer, Breathing & Quotes",
                    icon: Icons.spa_outlined,
                    gradient: AppGradients.teal,
                    iconColor: Colors.teal,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WellnessToolsScreen())),
                  ),
                  ),
                  const SizedBox(height: 24),

                  // Streak & Stats Row
                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestoreService.getUserStats(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      final streak = data?['currentStreak'] ?? 0;
                      final minutes = data?['totalFocusMinutes'] ?? 0;
                      return FadeInAnimation(
                        delay: step * 4,
                        duration: duration,
                        child: Row(
                          children: [
                            Expanded(child: _buildStatCard('Streak', '$streak Days', Icons.local_fire_department_rounded, Colors.orange)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildStatCard('Focus Time', '$minutes mins', Icons.timer_rounded, Colors.blue)),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // Mood Chart
                  FadeInAnimation(
                    delay: step * 5,
                    duration: duration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return GlassContainer(
      color: Colors.white,
      opacity: 0.8,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.format_quote_rounded, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _dailyQuote,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceCard(AdviceItem advice) {
    return GlassContainer(
      color: Colors.white,
      opacity: 0.8,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_outline_rounded, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insight',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advice.message,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassContainer(
      color: Colors.white,
      opacity: 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChart(List<Map<String, dynamic>> moods) {
    // Map mood strings to numeric values
    Map<String, double> moodValues = {
      'Great': 5.0,
      'Good': 4.0,
      'Okay': 3.0,
      'Bad': 2.0,
      'Terrible': 1.0,
      '😊': 5.0,
      '🙂': 4.0,
      '😐': 3.0,
      '😔': 2.0,
      '😰': 1.0,
      '😴': 2.5,
    };

    if (moods.isEmpty) {
      return Center(
        child: Text(
          "No mood data yet",
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < moods.length; i++) {
      String mood = moods[i]['mood'] ?? 'Okay';
      double value = moodValues[mood] ?? 3.0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    // Ensure we have at least one spot
    if (spots.isEmpty) {
      spots.add(FlSpot(0, 3.0));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[200]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < moods.length) {
                    try {
                      DateTime date = (moods[value.toInt()]['date'] as Timestamp).toDate();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('E').format(date),
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      );
                    } catch (e) {
                      return const Text('');
                    }
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: 6,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Theme.of(context).primaryColor,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
