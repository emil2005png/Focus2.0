import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/services/points_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_app/widgets/glass_container.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  final PointsService _pointsService = PointsService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _pointsService.getGamificationDataStream(),
        builder: (context, snapshot) {
          final data = snapshot.data ??
              {
                'totalPoints': 0,
                'currentStreak': 0,
                'monthlyLivesRemaining': 1,
                'streakBrokenAt': 0,
                'unlockedSections': <String>[],
              };

          final totalPoints = data['totalPoints'] as int;
          final currentStreak = data['currentStreak'] as int;
          final lives = data['monthlyLivesRemaining'] as int;
          final brokenAt = data['streakBrokenAt'] as int;
          final unlocked = List<String>.from(data['unlockedSections'] ?? []);

          return CustomScrollView(
            slivers: [
              // ─── Premium Header ───────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple[700]!,
                        Colors.deepPurple[400]!,
                        Colors.purple[300]!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Achievements',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Points & Streak Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatBubble(
                            '⭐',
                            '$totalPoints',
                            'Points',
                            Colors.amber,
                          ),
                          _buildStatBubble(
                            currentStreak >= 7
                                ? '🔥'
                                : currentStreak >= 3
                                    ? '🔥'
                                    : '📈',
                            '$currentStreak',
                            'Day Streak',
                            Colors.orange,
                          ),
                          _buildStatBubble(
                            '❤️',
                            '$lives',
                            'Lives Left',
                            Colors.red,
                          ),
                        ],
                      ),

                      // Streak Broken Banner
                      if (brokenAt > 0) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Text('💔', style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Streak Broken!',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Your $brokenAt-day streak was lost. Use a life to restore it!',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: lives > 0
                                    ? () => _useLife(brokenAt)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.deepPurple,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                ),
                                child: Text(
                                  lives > 0 ? '❤️ Use Life' : 'No Lives',
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Tab Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white60,
                          labelStyle: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          tabs: const [
                            Tab(text: '🏆 Unlockables'),
                            Tab(text: '📜 Point History'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Tab Content ──────────────────────────────
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUnlockablesTab(totalPoints, unlocked),
                    _buildPointHistoryTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  STAT BUBBLE
  // ═══════════════════════════════════════════════════════════
  Widget _buildStatBubble(
      String emoji, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  UNLOCKABLES TAB
  // ═══════════════════════════════════════════════════════════
  Widget _buildUnlockablesTab(int totalPoints, List<String> unlocked) {
    final sections = [
      _SectionData(
        id: 'hydration_hero',
        title: 'Hydration Hero',
        emoji: '🚰',
        description: 'Track hydration goals & earn bonus water streak points',
        cost: PointsService.unlockCosts['hydration_hero']!,
        color: Colors.cyan,
        gradient: [Colors.cyan[300]!, Colors.blue[500]!],
        tips: [
          'Drink 8 glasses of water daily',
          'Set hourly hydration reminders',
          'Track your daily water intake',
          'Hydrate before every meal',
        ],
      ),
      _SectionData(
        id: 'sleep_guardian',
        title: 'Sleep Guardian',
        emoji: '😴',
        description: 'Sleep quality insights & bedtime reminders',
        cost: PointsService.unlockCosts['sleep_guardian']!,
        color: Colors.indigo,
        gradient: [Colors.indigo[300]!, Colors.deepPurple[500]!],
        tips: [
          'Aim for 7-9 hours of sleep',
          'No screens 30 min before bed',
          'Keep a consistent sleep schedule',
          'Create a dark, cool environment',
        ],
      ),
      _SectionData(
        id: 'fitness_starter',
        title: 'Fitness Starter',
        emoji: '🏃',
        description: 'Exercise tracking with workout suggestions',
        cost: PointsService.unlockCosts['fitness_starter']!,
        color: Colors.orange,
        gradient: [Colors.orange[300]!, Colors.deepOrange[500]!],
        tips: [
          'Start with 15-min daily walks',
          'Try bodyweight exercises at home',
          'Stretch for 5 minutes every morning',
          'Find an activity you enjoy',
        ],
      ),
      _SectionData(
        id: 'study_warrior',
        title: 'Study Warrior',
        emoji: '📚',
        description: 'Study session tracking & focus techniques',
        cost: PointsService.unlockCosts['study_warrior']!,
        color: Colors.green,
        gradient: [Colors.green[300]!, Colors.teal[500]!],
        tips: [
          'Use the Pomodoro technique (25/5)',
          'Review notes within 24 hours',
          'Teach concepts to someone else',
          'Take breaks to improve retention',
        ],
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Point Rules Table
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📋', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text('How to Earn Points',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPointRule('😊 Mood Check-in', '+20'),
                _buildPointRule('🌱 Complete Habit', '+15'),
                _buildPointRule('💪 Health Log', '+25'),
                _buildPointRule('🎯 Focus Session', '+30'),
                _buildPointRule('✍️ Journal Entry', '+20'),
                _buildPointRule('🏆 Vision Goal', '+50'),
                _buildPointRule('📱 Daily Login', '+10'),
                const Divider(height: 16),
                _buildPointRule('🔥 7-Day Streak', '+200', isBonus: true),
                _buildPointRule('👑 30-Day Streak', '+500', isBonus: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Unlock Sections',
              style: GoogleFonts.outfit(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final s = sections[index];
                final isUnlocked = unlocked.contains(s.id);
                return _buildSectionCard(s, isUnlocked, totalPoints);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointRule(String label, String points,
      {bool isBonus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isBonus ? Colors.amber[800] : Theme.of(context).colorScheme.onSurface)),
          ),
          Text(points,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isBonus ? Colors.amber[800] : Colors.green[700],
              )),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
      _SectionData section, bool isUnlocked, int totalPoints) {
    final progress = (totalPoints / section.cost).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isUnlocked ? section.color : Colors.grey)
                .withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: isUnlocked ? () => _showSectionContent(section) : null,
            child: Column(
              children: [
                // Header gradient area
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isUnlocked
                          ? section.gradient
                          : [Colors.grey[400]!, Colors.grey[600]!],
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(section.emoji,
                          style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              section.title,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              section.description,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (isUnlocked)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 20),
                        ),
                      if (!isUnlocked)
                        const Icon(Icons.lock, color: Colors.white54, size: 28),
                    ],
                  ),
                ),

                // Bottom section
                if (!isUnlocked)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$totalPoints / ${section.cost} pts',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: totalPoints >= section.cost
                                  ? () => _unlockSection(section)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: section.color,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                              child: Text(
                                totalPoints >= section.cost
                                    ? 'Unlock 🔓'
                                    : 'Need ${section.cost - totalPoints} more',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[200],
                            valueColor:
                                AlwaysStoppedAnimation<Color>(section.color),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (isUnlocked)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.touch_app, color: section.color, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Tap to view tips & insights',
                          style: GoogleFonts.outfit(
                              color: section.color,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  POINT HISTORY TAB
  // ═══════════════════════════════════════════════════════════
  Widget _buildPointHistoryTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _pointsService.getPointHistoryStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final history = snapshot.data ?? [];

        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎯', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text('No points earned yet!',
                    style: GoogleFonts.outfit(
                        fontSize: 18, color: Colors.grey[600])),
                Text('Start using the app to earn points',
                    style:
                        GoogleFonts.outfit(fontSize: 14, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = history[index];
            final amount = item['amount'] as int;
            final reason = item['reason'] as String;
            final ts = item['timestamp'] as Timestamp?;
            final isNegative = amount < 0;

            String timeAgo = '';
            if (ts != null) {
              final diff = DateTime.now().difference(ts.toDate());
              if (diff.inMinutes < 60) {
                timeAgo = '${diff.inMinutes}m ago';
              } else if (diff.inHours < 24) {
                timeAgo = '${diff.inHours}h ago';
              } else {
                timeAgo = '${diff.inDays}d ago';
              }
            }

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isNegative ? Colors.red : Colors.green)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isNegative ? '🔻' : '✨',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              title: Text(reason,
                  style: GoogleFonts.outfit(
                      fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              subtitle: Text(timeAgo,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              trailing: Text(
                '${isNegative ? '' : '+'}$amount',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isNegative ? Colors.red : Colors.green[700],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ACTIONS
  // ═══════════════════════════════════════════════════════════
  void _useLife(int brokenAt) async {
    final result = await _pointsService.useLife();
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '❤️ Life used! Your $brokenAt-day streak has been restored!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to use life'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _unlockSection(_SectionData section) async {
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unlock ${section.title}?',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
            'This will cost ${section.cost} points. You\'ll gain access to ${section.title} tips and insights.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: section.color),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await _pointsService.unlockSection(section.id);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 ${section.title} Unlocked!'),
          backgroundColor: section.color,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSectionContent(_SectionData section) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
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
                Row(
                  children: [
                    Text(section.emoji,
                        style: const TextStyle(fontSize: 36)),
                    const SizedBox(width: 12),
                    Text(section.title,
                        style: GoogleFonts.outfit(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(section.description,
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: section.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 Tips & Insights',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...section.tips.map((tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.check,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Point Rules reminder
                GlassContainer(
                  color: section.color.withValues(alpha: 0.05),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: section.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Keep logging your daily activities to earn more points and unlock more sections!',
                          style: GoogleFonts.outfit(
                              fontSize: 13, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Data Model ───────────────────────────────────────────────
class _SectionData {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final int cost;
  final Color color;
  final List<Color> gradient;
  final List<String> tips;

  const _SectionData({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.cost,
    required this.color,
    required this.gradient,
    required this.tips,
  });
}
