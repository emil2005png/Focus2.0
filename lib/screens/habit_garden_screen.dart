import 'package:flutter/material.dart';
import 'package:focus_app/models/habit.dart';
import 'package:focus_app/models/daily_health_log.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:focus_app/services/points_service.dart';
import 'package:focus_app/widgets/digital_balance_tracker.dart';
import 'package:google_fonts/google_fonts.dart';

class HabitGardenScreen extends StatefulWidget {
  const HabitGardenScreen({super.key});

  @override
  State<HabitGardenScreen> createState() => _HabitGardenScreenState();
}

class _HabitGardenScreenState extends State<HabitGardenScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final PointsService _pointsService = PointsService();

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
              child: SingleChildScrollView(
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
                      initialValue: timeOfDay,
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
                            if (context.mounted) Navigator.pop(context);
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
              child: SingleChildScrollView(
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
                        onPressed: currentLog != null ? null : () async {
                          await _firestoreService.updateDailyHealthLog(DateTime.now(), sleep, exercise, water, screenTime);
                          await _pointsService.awardHealthLog(
                            waterGlasses: water,
                            exerciseMinutes: exercise,
                            screenTimeHours: screenTime,
                          );
                          if (context.mounted) {
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
                            } else {
                               ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Health log saved! ✨', style: GoogleFonts.outfit()),
                                  backgroundColor: Colors.blue[800],
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor: Colors.grey[300],
                          disabledForegroundColor: Colors.grey[600],
                        ),
                        child: Text(currentLog != null ? 'Already Logged Today' : 'Save Health Log', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
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
              if (context.mounted) Navigator.pop(context);
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




  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamBuilder<List<Habit>>(
          stream: _firestoreService.getHabits(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final habits = snapshot.data ?? [];
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
                     
                     final isLowMood = currentMood != null && lowMoods.contains(currentMood);
                     
                     final missedHabits = totalHabits - completedHabits;
                     
                     if (completedHabits == totalHabits && totalHabits > 0) {
                       insightMessage = "All rituals done! Great habits boost your positivity! 🌟";
                     } else if (isLowMood && missedHabits >= 3) {
                       insightMessage = "Completing small habits may help improve your mood tomorrow.";
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
                            color: Theme.of(context).colorScheme.onSurface,
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
                    SliverToBoxAdapter(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SizeTransition(
                            sizeFactor: animation,
                            child: child,
                          ),
                        ),
                        child: insightMessage.isNotEmpty
                          ? InsightCard(
                              key: ValueKey(insightMessage),
                              message: insightMessage,
                              mood: currentMood ?? '✨',
                            )
                          : const SizedBox.shrink(key: ValueKey('empty')),
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
                      child: StreamBuilder<Map<String, dynamic>>(
                        stream: _pointsService.getGamificationDataStream(),
                        builder: (context, gamSnap) {
                          final gData = gamSnap.data ?? {'totalPoints': 0, 'unlockedSections': <String>[]};
                          final totalPoints = gData['totalPoints'] as int;
                          final unlocked = List<String>.from(gData['unlockedSections'] ?? []);
                          return _buildUnlockableSections(totalPoints, unlocked);
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
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80.0),
          child: FloatingActionButton.extended(
            heroTag: 'habit_garden_fab',
            onPressed: _showAddHabitDialog,
            backgroundColor: Colors.green,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('Add Ritual', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isCompletedToday ? Colors.green.withValues(alpha: 0.3) : Colors.transparent,
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
                color: isCompletedToday ? Colors.green.withValues(alpha: 0.1) : Colors.grey[50],
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCompletedToday ? Colors.green[800] : Theme.of(context).colorScheme.onSurface,
                      decoration: isCompletedToday ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (habit.motivationalMessage.isNotEmpty && !isCompletedToday)
                    Text(
                      habit.motivationalMessage,
                       style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  // Consistency Badge
                  if (habit.currentStreak >= 3 && !isCompletedToday)
                     Container(
                       margin: const EdgeInsets.only(top: 4),
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                       decoration: BoxDecoration(
                         color: Colors.blue[50],
                         borderRadius: BorderRadius.circular(4),
                       ),
                       child: Text(
                        "You are building consistency like a pro!",
                        style: TextStyle(fontSize: 12, color: Colors.blue[800], fontWeight: FontWeight.bold),
                       ),
                     ),


                   if (isCompletedToday)
                     Text(
                      "Completed! Well done.",
                       style: TextStyle(
                        fontSize: 15,
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
                   if (habit.currentStreak >= 3) 
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50], // Very light orange
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_getStreakFlame(habit.currentStreak)} ${habit.currentStreak}',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
               if (habit.currentStreak > 0 && habit.currentStreak < 3)
                   Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50], // Very light orange
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${habit.currentStreak} Day Streak',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                
                InkWell(
                  onTap: () async {
                    try {
                      final wasCompleted = habit.isCompletedToday;
                      await _firestoreService.toggleHabitCompletion(habit, DateTime.now());
                      if (!wasCompleted) {
                        await _pointsService.awardHabitCompletion(habit.title);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              wasCompleted
                                ? '${habit.title} unchecked'
                                : '${habit.title} completed! +15pts 🌱',
                              style: GoogleFonts.outfit(),
                            ),
                            backgroundColor: wasCompleted ? Colors.grey[700] : Colors.green[700],
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Something went wrong: $e'),
                            backgroundColor: Colors.red[700],
                          ),
                        );
                      }
                    }
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

  Widget _buildUnlockableSections(int totalPoints, List<String> unlocked) {
    final sections = [
      {'id': 'hydration_hero', 'title': 'Hydration Hero', 'emoji': '🚰', 'desc': 'Track hydration goals & earn bonus points', 'cost': 500, 'color': Colors.cyan, 'gradient': [Colors.cyan[300]!, Colors.blue[500]!]},
      {'id': 'sleep_guardian', 'title': 'Sleep Guardian', 'emoji': '😴', 'desc': 'Sleep quality insights & reminders', 'cost': 1000, 'color': Colors.indigo, 'gradient': [Colors.indigo[300]!, Colors.deepPurple[500]!]},
      {'id': 'fitness_starter', 'title': 'Fitness Starter', 'emoji': '🏃', 'desc': 'Exercise tracking & workout tips', 'cost': 1500, 'color': Colors.orange, 'gradient': [Colors.orange[300]!, Colors.deepOrange[500]!]},
      {'id': 'study_warrior', 'title': 'Study Warrior', 'emoji': '📚', 'desc': 'Study tracking & focus techniques', 'cost': 2000, 'color': Colors.green, 'gradient': [Colors.green[300]!, Colors.teal[500]!]},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unlockable Sections 🏆',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          ...sections.map((s) {
            final isUnlocked = unlocked.contains(s['id']);
            final cost = s['cost'] as int;
            final color = s['color'] as Color;
            final gradient = s['gradient'] as List<Color>;
            final progress = (totalPoints / cost).clamp(0.0, 1.0);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isUnlocked ? color : Colors.grey).withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isUnlocked ? gradient : [Colors.grey[400]!, Colors.grey[600]!],
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(s['emoji'] as String, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['title'] as String,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  s['desc'] as String,
                                  style: GoogleFonts.outfit(fontSize: 11, color: Colors.white70),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isUnlocked)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 16),
                            ),
                          if (!isUnlocked)
                            const Icon(Icons.lock, color: Colors.white54, size: 22),
                        ],
                      ),
                    ),
                    if (!isUnlocked)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$totalPoints / $cost pts',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: totalPoints >= cost ? color : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    totalPoints >= cost ? 'Unlock 🔓' : 'Need ${cost - totalPoints} more',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: totalPoints >= cost ? Colors.white : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (isUnlocked)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: color, size: 16),
                            const SizedBox(width: 6),
                            Text('Unlocked!', style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
