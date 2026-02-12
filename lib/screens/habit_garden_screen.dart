import 'package:flutter/material.dart';
import 'package:focus_app/models/habit.dart';
import 'package:focus_app/models/daily_health_log.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:focus_app/widgets/digital_balance_tracker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/models/badge.dart' as app_badge;
import 'package:focus_app/models/weekly_summary.dart';
import 'package:intl/intl.dart';

class HabitGardenScreen extends StatefulWidget {
  const HabitGardenScreen({super.key});

  @override
  State<HabitGardenScreen> createState() => _HabitGardenScreenState();
}

class _HabitGardenScreenState extends State<HabitGardenScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showAddHabitDialog() {
    String newHabitTitle = '';
    String timeOfDay = 'morning';
    String motivationalMessage = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Plant a New Ritual 🌱', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Habit Name',
                      hintText: 'e.g., Drink Water',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      newHabitTitle = value;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: timeOfDay,
                    decoration: InputDecoration(
                      labelText: 'Time of Day',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: const [
                      DropdownMenuItem(value: 'morning', child: Text('☀️ Morning')),
                      DropdownMenuItem(value: 'afternoon', child: Text('🌤 Afternoon')),
                      DropdownMenuItem(value: 'night', child: Text('🌙 Night')),
                    ],
                    onChanged: (value) {
                      setState(() {
                         timeOfDay = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Motivation (Optional)',
                      hintText: 'e.g., Hydration fuels focus!',
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                       filled: true,
                       fillColor: Colors.grey[50],
                    ),
                    onChanged: (value) {
                      motivationalMessage = value;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (newHabitTitle.isNotEmpty) {
                          await _firestoreService.addHabit(
                            newHabitTitle, 
                            timeOfDay: timeOfDay,
                            motivationalMessage: motivationalMessage.isNotEmpty ? motivationalMessage : 'Keep growing!',
                          );
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Keep it green for habit addition
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Plant Ritual', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showHealthLogDialog(DailyHealthLog? currentLog) {
    double sleep = currentLog?.sleepHours ?? 0;
    int exercise = currentLog?.exerciseMinutes ?? 0;
    int water = currentLog?.waterGlasses ?? 0;
    double screenTime = currentLog?.screenTimeHours ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Health Log ⚡', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  // Digital Balance Tracker
                  DigitalBalanceTracker(
                    screenTime: screenTime,
                    onChanged: (value) => setState(() => screenTime = value),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        // Sleep
                        Row(
                          children: [
                            const Icon(Icons.bedtime, color: Colors.indigo),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Sleep: ${sleep.toStringAsFixed(1)}h', style: GoogleFonts.outfit(fontSize: 16)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline), 
                              onPressed: () => setState(() => sleep = (sleep - 0.5).clamp(0, 24)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline), 
                              onPressed: () => setState(() => sleep = (sleep + 0.5).clamp(0, 24)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // Exercise
                        Row(
                          children: [
                            const Icon(Icons.directions_run, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                               child: Text('Exercise: ${exercise}m', style: GoogleFonts.outfit(fontSize: 16)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline), 
                              onPressed: () => setState(() => exercise = (exercise - 15).clamp(0, 300)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline), 
                              onPressed: () => setState(() => exercise = (exercise + 15).clamp(0, 300)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // Water
                        Row(
                          children: [
                            const Icon(Icons.local_drink, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Water: $water glasses', style: GoogleFonts.outfit(fontSize: 16)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline), 
                              onPressed: () => setState(() => water = (water - 1).clamp(0, 20)),
                               padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline), 
                              onPressed: () => setState(() => water = (water + 1).clamp(0, 20)),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _firestoreService.updateDailyHealthLog(DateTime.now(), sleep, exercise, water, screenTime);
                        if (mounted) {
                          Navigator.pop(context);
                          if (screenTime > 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('High screen time detected. Consider a 20-minute focus break! 🧘', style: GoogleFonts.outfit()),
                                backgroundColor: Colors.orange[800],
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          } else if (screenTime < 3) {
                             ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Great digital discipline today! 🌟', style: GoogleFonts.outfit()),
                                backgroundColor: Colors.green[800],
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Save Health Log', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _deleteHabit(String habitId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Ritual?'),
        content: const Text('Are you sure you want to dig up this habit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _firestoreService.deleteHabit(habitId);
              if (mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Dig Up'),
          ),
        ],
      ),
    );
  }

  String _getStreakFlame(int streak) {
    if (streak >= 30) return '👑';
    if (streak >= 21) return '🌟';
    if (streak >= 7) return '🔥🔥';
    if (streak >= 3) return '🔥';
    return '';
  }

  String _getConsistencyMessage(int streak) {
    if (streak >= 3) return "You are building consistency like a pro!";
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamBuilder<List<Habit>>(
          stream: _firestoreService.getHabits(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.spa_outlined, size: 80, color: Colors.green),
                    const SizedBox(height: 16),
                    Text(
                      'Your Ritual Board is Empty',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                      const Text('Start building your daily rituals!'),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddHabitDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Ritual'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              );
            }

            final habits = snapshot.data!;
            final morningHabits = habits.where((h) => h.timeOfDay == 'morning').toList();
            final afternoonHabits = habits.where((h) => h.timeOfDay == 'afternoon').toList();
            final nightHabits = habits.where((h) => h.timeOfDay == 'night').toList();

            // Calculate Habit Completion %
            final totalHabits = habits.length;
            final completedHabits = habits.where((h) => h.isCompletedToday).length;
            final habitScoreRaw = totalHabits > 0 ? (completedHabits / totalHabits) * 100 : 0.0;

            return StreamBuilder<DailyHealthLog?>(
              stream: _firestoreService.getDailyHealthLog(DateTime.now()),
              builder: (context, healthSnapshot) {
                 final healthLog = healthSnapshot.data;
                 
                 // Calculate Energy Score
                 double habitScore = habitScoreRaw; // 0-100
                 double sleepScore = ((healthLog?.sleepHours ?? 0) / 8.0 * 100).clamp(0, 100);
                 double exerciseScore = ((healthLog?.exerciseMinutes ?? 0).toDouble() / 30.0 * 100).clamp(0, 100);
                 double waterScore = ((healthLog?.waterGlasses ?? 0).toDouble() / 8.0 * 100).clamp(0, 100);

                 double energyScore = (habitScore * 0.4) + (sleepScore * 0.3) + (exerciseScore * 0.2) + (waterScore * 0.1);

                 return StreamBuilder<String?>(
                   stream: _firestoreService.getLatestMoodStream(),
                   builder: (context, moodSnapshot) {
                     final currentMood = moodSnapshot.data;
                     
                     // Insight Logic
                     String insightMessage = "";
                     final lowMoods = ['😢', '😠', '😫', '😔', '😞'];
                     final happyMoods = ['😀', '🤩', '😊', '😂', '🥰'];
                     
                     final isLowMood = currentMood != null && lowMoods.contains(currentMood);
                     final isHappyMood = currentMood != null && happyMoods.contains(currentMood);
                     
                     final missedHabits = totalHabits - completedHabits;
                     
                     if (isLowMood && missedHabits >= 3) {
                       insightMessage = "Completing small habits may help improve your mood tomorrow.";
                     } else if (isHappyMood && completedHabits == totalHabits && totalHabits > 0) {
                       insightMessage = "Great habits boost your positivity!";
                     }

                     return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
                        child: Text(
                          'Daily Rituals',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: EnergyMeterWidget(
                        energyScore: energyScore,
                        onTap: () => _showHealthLogDialog(healthLog),
                      ),
                    ),
                     if (insightMessage.isNotEmpty)
                      SliverToBoxAdapter(
                        child: InsightCard(
                          message: insightMessage,
                          mood: currentMood ?? '✨',
                        ),
                      ),
                    if (habits.isEmpty)
                      SliverToBoxAdapter(
                        child:  Center(
                          child: Column(
                            children: [
                              const SizedBox(height: 50),
                              const Icon(Icons.spa_outlined, size: 60, color: Colors.green),
                              const SizedBox(height: 16),
                              Text('Plant your first habit!', style: GoogleFonts.outfit(fontSize: 18)),
                              const SizedBox(height: 16),
                               ElevatedButton.icon(
                                onPressed: _showAddHabitDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Create Ritual'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (morningHabits.isNotEmpty) ...[
                      _buildSectionHeader('Morning Habits ☀️'),
                      _buildHabitList(morningHabits),
                    ],
                    if (afternoonHabits.isNotEmpty) ...[
                      _buildSectionHeader('Afternoon Habits 🌤'),
                      _buildHabitList(afternoonHabits),
                    ],
                    if (nightHabits.isNotEmpty) ...[
                      _buildSectionHeader('Night Habits 🌙'),
                      _buildHabitList(nightHabits),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    SliverToBoxAdapter(
                      child: FutureBuilder<WeeklyData>(
                        future: _calculateWeeklyData(habits),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          final data = snapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildWeeklySummaryCard(data.summary),
                              if (data.badges.isNotEmpty) _buildBadgesSection(data.badges),
                            ],
                          );
                        },
                      ),
                    ),
                     const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
                   }
                 );
              }
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddHabitDialog,
          backgroundColor: Colors.green,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text('Add Ritual', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitList(List<Habit> habits) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final habit = habits[index];
            return _buildHabitCard(habit);
          },
          childCount: habits.length,
        ),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final bool isCompletedToday = habit.isCompletedToday;
    final String plantStage = habit.plantStage;

    return GestureDetector(
      onLongPress: () => _deleteHabit(habit.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isCompletedToday ? Colors.green.withOpacity(0.3) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Plant Icon Status
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isCompletedToday ? Colors.green.withOpacity(0.1) : Colors.grey[50],
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                plantStage,
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: 16),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCompletedToday ? Colors.green[800] : Colors.black87,
                      decoration: isCompletedToday ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (habit.motivationalMessage.isNotEmpty && !isCompletedToday)
                    Text(
                      habit.motivationalMessage,
                       style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  // Consistency Badge
                  if (habit.streak >= 3 && !isCompletedToday)
                     Container(
                       margin: const EdgeInsets.only(top: 4),
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                       decoration: BoxDecoration(
                         color: Colors.blue[50],
                         borderRadius: BorderRadius.circular(4),
                       ),
                       child: Text(
                        "You are building consistency like a pro!",
                        style: TextStyle(fontSize: 10, color: Colors.blue[800], fontWeight: FontWeight.bold),
                       ),
                     ),


                   if (isCompletedToday)
                     Text(
                      "Completed! Well done.",
                       style: TextStyle(
                        fontSize: 13,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),

            // Streak & Action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
               if (habit.streak >= 3) 
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50], // Very light orange
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_getStreakFlame(habit.streak)} ${habit.streak}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
               if (habit.streak > 0 && habit.streak < 3)
                   Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50], // Very light orange
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${habit.streak} Day Streak',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                
                InkWell(
                  onTap: () {
                     _firestoreService.toggleHabitCompletion(habit, DateTime.now());
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCompletedToday ? Colors.green : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isCompletedToday ? Colors.green : Colors.grey[300]!),
                    ),
                    child: Text(
                      isCompletedToday ? 'Done' : 'Check',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCompletedToday ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<WeeklyData> _calculateWeeklyData(List<Habit> habits) async {
    final healthLogs = await _firestoreService.getHealthLogsForLast7Days();
    
    // --- Badge Logic ---
    // 1. Hydration Hero: 7 days water >= 8 glasses
    int waterStreak = 0;
    int currentWaterStreak = 0;
    int hydrationDays = 0;
    for (var log in healthLogs) {
        if (log.waterGlasses >= 8) {
            currentWaterStreak++;
            hydrationDays++;
        } else {
            if (currentWaterStreak > waterStreak) waterStreak = currentWaterStreak;
            currentWaterStreak = 0;
        }
    }
    if (currentWaterStreak > waterStreak) waterStreak = currentWaterStreak; // Check last streak
    bool hydrationHero = hydrationDays >= 7;

    // 2. Sleep Guardian: 7 days sleep >= 7h
    int sleepStreak = healthLogs.where((log) => log.sleepHours >= 7).length;
    bool sleepGuardian = sleepStreak >= 7;

    // 3. Fitness Starter: 3 days exercise > 0
    int exerciseDays = healthLogs.where((log) => log.exerciseMinutes > 0).length;
    bool fitnessStarter = exerciseDays >= 3;

    // 4. Study Warrior: Habit "Study" streak >= 5
    bool studyWarrior = habits.any((h) => 
      h.title.toLowerCase().contains('study') && h.streak >= 5
    );

    final badges = [
      app_badge.Badge(
        id: 'hydration',
        name: 'Hydration Hero',
        icon: '💧',
        description: 'Drank 8+ glasses of water for 7 days',
        color: Colors.blue,
        isEarned: hydrationHero,
      ),
      app_badge.Badge(
        id: 'sleep',
        name: 'Sleep Guardian',
        icon: '🌙',
        description: 'Slept 7+ hours for 7 days',
        color: Colors.indigo,
        isEarned: sleepGuardian,
      ),
      app_badge.Badge(
        id: 'fitness',
        name: 'Fitness Starter',
        icon: '💪',
        description: 'Worked out 3 times this week',
        color: Colors.orange,
        isEarned: fitnessStarter,
      ),
      app_badge.Badge(
        id: 'study',
        name: 'Study Warrior',
        icon: '📚',
        description: '5-day study streak',
        color: Colors.red,
        isEarned: studyWarrior,
      ),
    ];

    // --- Summary Logic ---
    double totalScreenTime = 0;
    int totalWater = 0;
    String bestDay = 'N/A';
    double maxScore = -1;

    for (var log in healthLogs) {
        totalScreenTime += log.screenTimeHours;
        totalWater += log.waterGlasses;
        
        // Calculate daily score roughly (approximate since we don't have habit data per day easily accessible here without more complexity)
        // We'll use the health metrics for "Best Day" estimation
        double score = (log.sleepHours / 8.0) * 30 + (log.exerciseMinutes / 30.0) * 20 + (log.waterGlasses / 8.0) * 10;
        if (score > maxScore) {
            maxScore = score;
            bestDay = DateFormat('EEEE').format(log.date);
        }
    }

    double avgScreenTime = healthLogs.isNotEmpty ? totalScreenTime / healthLogs.length : 0.0;

    final summary = WeeklySummary(
        averageScreenTime: avgScreenTime,
        bestDay: bestDay,
        hydrationStreak: waterStreak,
        totalWaterIntake: totalWater,
    );

    return WeeklyData(badges: badges, summary: summary);
  }

  Widget _buildWeeklySummaryCard(WeeklySummary summary) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Digital Health Summary 📊',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Avg Screen Time', '${summary.averageScreenTime.toStringAsFixed(1)}h', Icons.phonelink_ring, Colors.purple),
              _buildSummaryItem('Best Day', summary.bestDay, Icons.star, Colors.amber),
            ],
          ),
          const SizedBox(height: 12),
          Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               _buildSummaryItem('Hydration Streak', '${summary.hydrationStreak} days', Icons.water_drop, Colors.blue),
               // You can add more items here
             ],
           ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(List<app_badge.Badge> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Weekly Achievements 🏆',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: badge.isEarned ? badge.color.withOpacity(0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: badge.isEarned ? badge.color.withOpacity(0.5) : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Text(
                       badge.icon,
                       style: TextStyle(
                         fontSize: 32,
                         color: badge.isEarned ? null : Colors.grey.withOpacity(0.5),
                       ),
                     ),
                     const SizedBox(height: 8),
                     Text(
                       badge.name,
                       textAlign: TextAlign.center,
                       style: GoogleFonts.outfit(
                         fontSize: 12,
                         fontWeight: FontWeight.bold,
                         color: badge.isEarned ? badge.color : Colors.grey,
                       ),
                     ),
                     if (!badge.isEarned)
                       Padding(
                         padding: const EdgeInsets.only(top: 4),
                         child: Icon(Icons.lock, size: 12, color: Colors.grey[400]),
                       ),
                   ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class InsightCard extends StatelessWidget {
  final String message;
  final String mood;

  const InsightCard({super.key, required this.message, required this.mood});

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo[100]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(mood, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Insight",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[800],
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.indigo[900],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EnergyMeterWidget extends StatelessWidget {
  final double energyScore;
  final VoidCallback onTap;

  const EnergyMeterWidget({
    super.key,
    required this.energyScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final score = energyScore.clamp(0.0, 100.0);
    final color = score >= 80 ? Colors.green : (score >= 50 ? Colors.orange : Colors.red);
    final message = score >= 80 
        ? "You are performing strong 💪" 
        : (score >= 50 ? "Doing good, keep going! 🚀" : "Let's recharge! 🔋");

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                children: [
                   Center(
                    child: CircularProgressIndicator(
                      value: score / 100,
                      backgroundColor: Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      strokeWidth: 8,
                    ),
                  ),
                   Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         const Icon(Icons.flash_on, size: 20, color: Colors.amber),
                         Text(
                          '${score.toInt()}%',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Energy Score Today', style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                   Text(
                    message,
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Tap to log health stats', style: TextStyle(fontSize: 12, color: Colors.blue[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
