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
import 'package:focus_app/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<AdviceItem?> _adviceFuture;

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

                  // Tracker Card (New Entry Point)
                  FadeInAnimation(
                    delay: step * 2,
                    duration: duration,
                    child: Column(
                      children: [
                        _buildTrackerCard(context),
                        const SizedBox(height: 16),
                        _buildWeeklySummaryCard(context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Wellness Tools Card
                  FadeInAnimation(
                    delay: step * 3,
                    duration: duration,
                    child: _buildWellnessCard(context),
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

  Widget _buildTrackerCard(BuildContext context) {
    return GlassContainer(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DistractionStatsScreen()),
        );
      },
      color: Colors.white,
      opacity: 0.7,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppGradients.orange,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(Icons.track_changes_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Distraction Tracker",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Log & View Insights",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded, color: Colors.white70, size: 36),
          const SizedBox(height: 12),
          Text(
            _dailyQuote,
            style: GoogleFonts.merriweather( // Serif font for quotes
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Daily Inspiration",
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                letterSpacing: 1,
              ),
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
    if (moods.isEmpty) {
      return const Center(child: Text("No mood data yet"));
    }

    // Sort by date to ensure correct order
    moods.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    // Map mood emojis to values
    double getMoodValue(String mood) {
      switch (mood) {
        case '🤩': return 5;
        case '😊': return 4;
        case '😌': return 3; // Swapped for better visual spread
        case '😐': return 2;
        case '😴': return 2; // Same level as neutral
        case '😔': return 1;
        case '😰': return 0;
        default: return 2;
      }
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < moods.length; i++) {
      spots.add(FlSpot(i.toDouble(), getMoodValue(moods[i]['mood'])));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.only(right: 16, left: 0, top: 24, bottom: 0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < moods.length) {
                    final date = moods[index]['date'] as DateTime;
                    // Format: Mon 12
                    final day = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "$day ${date.day}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  String text;
                  switch (value.toInt()) {
                    case 5: text = '🤩'; break;
                    case 4: text = '😊'; break;
                    case 3: text = '😌'; break;
                    case 2: text = '😐'; break;
                    case 1: text = '😔'; break;
                    case 0: text = '😰'; break;
                    default: return const SizedBox();
                  }
                  return Text(text, style: const TextStyle(fontSize: 20));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (moods.length - 1).toDouble(),
          minY: -0.5,
          maxY: 5.5,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).primaryColor,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.3),
                    Theme.of(context).primaryColor.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  final index = barSpot.x.toInt();
                  if (index >= 0 && index < moods.length) {
                     final mood = moods[index]['mood'];
                     return LineTooltipItem(
                       mood,
                       const TextStyle(fontSize: 24),
                     );
                  }
                  return null;
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdviceCard(AdviceItem item) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      color: Colors.orange,
      opacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lightbulb_outline, color: Colors.orange[800], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Insight for You",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.message,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.actionType != AdviceActionType.none) ...[
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (item.actionType == AdviceActionType.reflection) {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => const ReflectionScreen()));
                  } else if (item.actionType == AdviceActionType.breathing) {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => const BreathingScreen()));
                  } else if (item.actionType == AdviceActionType.timer) {
                     Navigator.push(context, MaterialPageRoute(builder: (context) => const FocusTimerScreen()));
                  }
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(item.actionLabel ?? "Take Action"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.orange.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            )
          ]
        ],
      ),
    );
  }
  Widget _buildWellnessCard(BuildContext context) {
    return GlassContainer(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WellnessToolsScreen()),
        );
      },
      color: Colors.white,
      opacity: 0.7,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppGradients.teal,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(Icons.spa_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Wellness Tools",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "Timer, Breathing & Quotes",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard(BuildContext context) {
    return GlassContainer(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DistractionSummaryScreen()),
        );
      },
      color: Colors.white,
      opacity: 0.7,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppShadows.primary,
            ),
            child: const Icon(Icons.summarize_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Summary',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Analyze your week',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}
