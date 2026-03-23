
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:focus_app/screens/analytics_screen.dart';
import 'package:focus_app/screens/achievements_screen.dart';
import 'package:focus_app/screens/journal_main_screen.dart';

import 'package:focus_app/screens/distraction_stats_screen.dart';

import 'package:focus_app/services/advice_service.dart';

import 'package:focus_app/widgets/fade_in_animation.dart';
import 'package:focus_app/widgets/glass_container.dart';

import 'package:focus_app/widgets/daily_planning_widget.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/services/quote_service.dart';
import 'package:focus_app/models/habit.dart';
import 'package:focus_app/widgets/dashboard_feature_card.dart';
import 'package:focus_app/screens/vision_board_screen.dart';
import 'package:focus_app/services/points_service.dart';

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
    _dailyQuote = _quoteService.getDailyQuote();
    _adviceFuture = _getAdvice();
    _awardDailyPoints();
  }

  Future<void> _awardDailyPoints() async {
    final points = await PointsService().awardDailyEngagement();
    if (points > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back! +$points points awarded! ✨'),
          backgroundColor: Colors.blue,
        ),
      );
    }
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
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: _firestoreService.getUserProfile(),
                      builder: (context, profileSnap) {
                        final profileData = profileSnap.data?.data() as Map<String, dynamic>?;
                        final username = profileData?['username'] as String? ?? '';
                        final greeting = username.isNotEmpty
                            ? 'Welcome Back, $username!'
                            : 'Welcome Back!';

                        return Column(
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
                              greeting,
                              style: GoogleFonts.outfit(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Points & Streak Banner
                  FadeInAnimation(
                    delay: step,
                    duration: duration,
                    child: StreamBuilder<Map<String, dynamic>>(
                      stream: PointsService().getGamificationDataStream(),
                      builder: (context, gamSnap) {
                        final gData = gamSnap.data ?? {'totalPoints': 0, 'currentStreak': 0, 'monthlyLivesRemaining': 1};
                        final pts = gData['totalPoints'] as int;
                        final streak = gData['currentStreak'] as int;
                        final lives = gData['monthlyLivesRemaining'] as int;
                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.deepPurple[500]!, Colors.purple[400]!],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildBannerStat('⭐', '$pts', 'Points'),
                                Container(width: 1, height: 30, color: Colors.white24),
                                _buildBannerStat('🔥', '$streak', 'Streak'),
                                Container(width: 1, height: 30, color: Colors.white24),
                                _buildBannerStat('❤️', '$lives', 'Lives'),
                                const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

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

                  // Tracker & Calendar Cards
                  FadeInAnimation(
                    delay: step * 2,
                    duration: duration,
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                      children: [
                        DashboardFeatureCard(
                          title: "Journal & Reflection",
                          subtitle: "Record your thoughts",
                          icon: Icons.book_rounded,
                          gradient: AppGradients.blue,
                          iconColor: Colors.blue,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const JournalMainScreen())),
                        ),
                        DashboardFeatureCard(
                          title: "Achievements",
                          subtitle: "View your awards",
                          icon: Icons.emoji_events_rounded,
                          gradient: AppGradients.orange,
                          iconColor: Colors.orange,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AchievementsScreen())),
                        ),
                        DashboardFeatureCard(
                          title: "Analytics & Insights",
                          subtitle: "View your trends",
                          icon: Icons.insights_rounded,
                          gradient: AppGradients.purple,
                          iconColor: Colors.purple,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen())),
                        ),
                        DashboardFeatureCard(
                          title: "Vision Board",
                          subtitle: "Visualize Goals",
                          icon: Icons.auto_awesome_mosaic_rounded,
                          gradient: AppGradients.teal,
                          iconColor: Colors.teal,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VisionBoardScreen())),
                        ),
                        DashboardFeatureCard(
                          title: "Distraction Tracker",
                          subtitle: "Log & View Insights",
                          icon: Icons.track_changes_outlined,
                          gradient: AppGradients.orange,
                          iconColor: Colors.orange,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DistractionStatsScreen())),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Weekly Event Card
                  FutureBuilder<Map<String, dynamic>>(
                    future: _firestoreService.getWeeklyStats(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final stats = snapshot.data!;
                      final goalDays = stats['goalDays'] as int;
                      final isUnlocked = stats['isUnlocked'] as bool;
                      final progress = (goalDays / 5).clamp(0.0, 1.0);

                      return FadeInAnimation(
                        delay: step * 2,
                        duration: duration,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isUnlocked 
                                ? [Colors.purple[400]!, Colors.purple[700]!] 
                                : [Colors.grey[800]!, Colors.grey[900]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: (isUnlocked ? Colors.purple : Theme.of(context).colorScheme.onSurface).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isUnlocked ? Icons.stars_rounded : Icons.lock_outline_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isUnlocked ? 'Weekly Event Unlocked! ✨' : 'Weekly Event Progress',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color?>(
                                    isUnlocked ? Colors.amber[400] : Colors.purple[300],
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                isUnlocked 
                                  ? 'You reached your goals for $goalDays days! Enjoy your reward.' 
                                  : 'Meet your goals for ${stats['remainingDays']} more days to unlock this week\'s event.',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),



                  // Streak & Stats Row
                  StreamBuilder<DocumentSnapshot>(
                    stream: _firestoreService.getUserStats(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      final focusStreak = data?['currentStreak'] ?? 0;
                      final waterStreak = data?['waterStreak'] ?? 0;
                      final minutes = data?['totalFocusMinutes'] ?? 0;
                      
                      return FadeInAnimation(
                        delay: step * 4,
                        duration: duration,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: _buildStatCard('Focus Streak', '$focusStreak Days', Icons.local_fire_department_rounded, Colors.orange)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FutureBuilder<int>(
                                    future: _firestoreService.getTodayFocusMinutes(),
                                    builder: (context, focusSnapshot) {
                                      final mins = focusSnapshot.data ?? minutes;
                                      return _buildStatCard('Focus Time', '$mins mins', Icons.timer_rounded, Colors.blue);
                                    }
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildStatCard('Water Streak', '$waterStreak Days', Icons.water_drop_rounded, Colors.cyan)),
                                const SizedBox(width: 16),
                                Expanded(
                                      child: StreamBuilder<List<Habit>>(
                                    stream: _firestoreService.getHabits(),
                                    builder: (context, habitSnapshot) {
                                      int maxHabitStreak = 0;
                                      if (habitSnapshot.hasData && habitSnapshot.data!.isNotEmpty) {
                                        final streaks = habitSnapshot.data!.map((h) => h.currentStreak).toList();
                                        maxHabitStreak = streaks.reduce((a, b) => a > b ? a : b);
                                      }
                                      return _buildStatCard('Best Habit', '$maxHabitStreak Days', Icons.spa_rounded, Colors.green);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Active Days Streak & Screen Time row
                            Row(
                              children: [
                                Expanded(
                                  child: FutureBuilder<int>(
                                    future: _firestoreService.getActiveDaysStreak(),
                                    builder: (context, streakSnap) {
                                      final activeDays = streakSnap.data ?? 0;
                                      return _buildStatCard('Active Days', '$activeDays Days', Icons.calendar_today_rounded, Colors.deepPurple);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: FutureBuilder<double>(
                                    future: _firestoreService.getTodayScreenTime(),
                                    builder: (context, screenSnap) {
                                      final screenTime = screenSnap.data ?? 0.0;
                                      return _buildStatCard('Screen Time', '${screenTime.toStringAsFixed(1)}h', Icons.phone_android_rounded, Colors.red);
                                    },
                                  ),
                                ),
                              ],
                            ),
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
                  const SizedBox(height: 24),

                  // Contextual Feedback Messages
                  FadeInAnimation(
                    delay: step * 6,
                    duration: duration,
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _getContextualFeedback(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final feedback = snapshot.data!;
                        final message = feedback['message'] as String;
                        final icon = feedback['icon'] as IconData;
                        final color = feedback['color'] as Color;

                        return GlassContainer(
                          color: Colors.white,
                          opacity: 0.8,
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icon, color: color, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Daily Insight', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[600])),
                                    const SizedBox(height: 4),
                                    Text(message, style: GoogleFonts.outfit(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
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

  Widget _buildBannerStat(String emoji, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(value, style: GoogleFonts.outfit(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
            )),
          ],
        ),
        Text(label, style: GoogleFonts.outfit(
          fontSize: 11, color: Colors.white70,
        )),
      ],
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
              color: Colors.amber.withValues(alpha: 0.1),
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
              color: Colors.blue.withValues(alpha: 0.1),
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
                    color: Theme.of(context).colorScheme.onSurface,
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
              color: color.withValues(alpha: 0.1),
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
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChart(List<Map<String, dynamic>> moods) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Generate last 7 days list
    final last7Days = List.generate(7, (index) {
      return today.subtract(Duration(days: 6 - index));
    });

    Map<String, double> moodValueMap = {
      '😊': 5.0, '🤩': 5.0, '😌': 4.0, '🙂': 4.0, '😐': 3.0, '😔': 2.0, '😰': 1.0, '😴': 2.0,
      'Happy': 5.0, 'Excited': 5.0, 'Calm': 4.0, 'Sad': 2.0, 'Anxious': 1.0, 'Tired': 2.0,
    };

    List<FlSpot> spots = [];
    List<String> moodsPerDay = []; // For the dot painter
    List<int> plottedDayIndices = []; // Keep track of which x indices have points

    for (int i = 0; i < last7Days.length; i++) {
      final date = last7Days[i];
      
      // Find latest mood for this day
      final dayMoods = moods.where((m) {
        final mDate = m['date'] as DateTime;
        return mDate.year == date.year && mDate.month == date.month && mDate.day == date.day;
      }).toList();

      if (dayMoods.isNotEmpty) {
        // Sort by date to get the latest one in case they aren't sorted
        dayMoods.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        final latestMood = dayMoods.last['mood'] as String;
        final value = moodValueMap[latestMood] ?? 3.0;
        spots.add(FlSpot(i.toDouble(), value));
        moodsPerDay.add(latestMood);
        plottedDayIndices.add(i);
      }
      // If empty, we just don't add a spot, the line will connect the spots we do add.
    }

    if (spots.isEmpty) {
      return Center(
        child: Text(
          "No mood data from the last 7 days",
          style: TextStyle(color: Colors.grey[400]),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 5: return const Text('😊', style: TextStyle(fontSize: 16));
                    case 3: return const Text('😐', style: TextStyle(fontSize: 16));
                    case 1: return const Text('😰', style: TextStyle(fontSize: 16));
                    default: return const Text('');
                  }
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < last7Days.length) {
                    final date = last7Days[index];
                    final isToday = date.day == today.day && date.month == today.month && date.year == today.year;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        isToday ? 'Today' : DateFormat('E').format(date),
                        style: TextStyle(
                          fontSize: 10, 
                          color: isToday ? Theme.of(context).primaryColor : Colors.grey[600],
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: 0.5,
          maxY: 5.5,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  // Index is the index of the spot in the spots list, so we can just use it to look up the emoji
                  final moodEmoji = moodsPerDay[index];
                  return _EmojiDotPainter(emoji: moodEmoji, size: 20);
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    Theme.of(context).primaryColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generate contextual feedback based on user activity and progress
  Future<Map<String, dynamic>> _getContextualFeedback() async {
    try {
      final focusMins = await _firestoreService.getTodayFocusMinutes();
      final screenTime = await _firestoreService.getTodayScreenTime();
      final streak = await _firestoreService.getActiveDaysStreak();
      final moods = await _firestoreService.getMoodsForLast7Days();

      // Priority-based feedback selection
      if (streak >= 7) {
        return {
          'message': 'Incredible $streak-day streak! 🔥 You\'re building great habits.',
          'icon': Icons.local_fire_department_rounded,
          'color': Colors.orange,
        };
      }

      if (focusMins >= 60) {
        return {
          'message': 'Outstanding focus today — $focusMins minutes! Keep up the great work. 🎯',
          'icon': Icons.psychology_rounded,
          'color': Colors.blue,
        };
      }

      if (screenTime > 4) {
        return {
          'message': 'Screen time is ${screenTime.toStringAsFixed(1)}h today. Consider taking a focus break! 📵',
          'icon': Icons.phone_android_rounded,
          'color': Colors.red,
        };
      }

      if (moods.length >= 3) {
        // Check mood trend
        final moodScores = {'😊': 5, '🤩': 5, '😌': 4, '😐': 3, '😔': 2, '😰': 1, '😴': 2};
        final recent = moods.take(3).map((m) => moodScores[m['mood'] ?? '😐'] ?? 3).toList();
        final avg = recent.reduce((a, b) => a + b) / recent.length;
        if (avg >= 4) {
          return {
            'message': 'Your mood has been positive lately! 🎉 Keep doing what makes you happy.',
            'icon': Icons.sentiment_very_satisfied_rounded,
            'color': Colors.green,
          };
        } else if (avg <= 2) {
          return {
            'message': 'You\'ve been feeling low. Try a short meditation or talk to someone you trust. 💙',
            'icon': Icons.favorite_rounded,
            'color': Colors.purple,
          };
        }
      }

      if (focusMins == 0) {
        return {
          'message': 'Start your day with a 25-minute focus session! Small steps lead to big wins. 💪',
          'icon': Icons.timer_rounded,
          'color': Colors.indigo,
        };
      }

      return {
        'message': 'You\'re making progress. Every small step counts! 🌟',
        'icon': Icons.star_rounded,
        'color': Colors.amber,
      };
    } catch (e) {
      return {};
    }
  }
}

class _EmojiDotPainter extends FlDotPainter {
  final String emoji;
  final double size;

  _EmojiDotPainter({required this.emoji, this.size = 20});

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offset) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: size),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2),
    );
  }

  @override
  Size getSize(FlSpot spot) => Size(size, size);

  @override
  Color get mainColor => Colors.transparent;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    return b;
  }

  @override
  List<Object?> get props => [emoji, size];
}
