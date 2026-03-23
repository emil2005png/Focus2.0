import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';


import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/providers/analytics_provider.dart';


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadWeeklyData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Analytics & Insights',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          bottom: const TabBar(
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            tabs: [
              Tab(text: 'Weekly Overview'),
              Tab(text: 'Visual Charts'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _WeeklyOverviewTab(),
            _ChartsTab(),
          ],
        ),
      ),
    );
  }
}

class _WeeklyOverviewTab extends StatelessWidget {
  const _WeeklyOverviewTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadWeeklyData(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(provider.getWeeklySummary()),
                const SizedBox(height: 24),
                Text(
                  'Quick Insights',
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildInsightGrid(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String summary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Colors.indigo, Colors.blueAccent]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(summary,
          style: const TextStyle(color: Colors.white, fontSize: 15)),
    );
  }

  Widget _buildInsightGrid(BuildContext context, AnalyticsProvider provider) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _insightTile(
            context,
            'Mood Trend',
            provider.getMoodTrend(),
            Icons.emoji_emotions,
            Colors.orange),
        _insightTile(
            context,
            'Habit Consistency',
            provider.getHabitConsistency(),
            Icons.check_circle,
            Colors.green),
        _insightTile(
            context,
            'Best Focus Day',
            provider.getBestFocusDay(),
            Icons.timer,
            Colors.blue),
        _insightTile(
            context,
            'Screen Usage',
            provider.getScreenUsageChange(),
            Icons.app_blocking,
            Colors.purple),
      ],
    );
  }

  Widget _insightTile(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02), blurRadius: 10)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(label, 
            style: const TextStyle(fontSize: 12),
            maxLines: 1, 
            overflow: TextOverflow.ellipsis
          ),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ChartsTab extends StatelessWidget {
  const _ChartsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildChartSection(context,
                'Focus Activity', _FocusBarChart(provider)),
            const SizedBox(height: 24),
            _buildChartSection(context, 'Mood Trends', _MoodLineChart(provider)),
            const SizedBox(height: 24),
            _buildChartSection(context, 'Habit Progress', _HabitBarChart(provider)),
            const SizedBox(height: 24),
            _buildChartSection(context, 'Screen Time',
                _ScreenTimeAreaChart(provider)),
          ],
        );
      },
    );
  }

  Widget _buildChartSection(BuildContext context, String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02), blurRadius: 10)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }
}

// --- Focus Activity Bar Chart (Real Data) ---
class _FocusBarChart extends StatelessWidget {
  final AnalyticsProvider provider;
  const _FocusBarChart(this.provider);

  @override
  Widget build(BuildContext context) {
    final dailyMinutes = provider.getFocusMinutesPerDay();
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxY = dailyMinutes.isEmpty ? 60.0 : (dailyMinutes.reduce((a, b) => a > b ? a : b)).clamp(30.0, 500.0);

    return BarChart(
      BarChartData(
        maxY: maxY + 20,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} min',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}m', style: TextStyle(fontSize: 10, color: Colors.grey[600]));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int i = value.toInt();
                if (i >= 0 && i < dayLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(dayLabels[i], style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) {
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: dailyMinutes[i],
              color: Colors.indigo,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            )
          ]);
        }),
      ),
    );
  }
}

// --- Mood Line Chart (Real Data) ---
class _MoodLineChart extends StatelessWidget {
  final AnalyticsProvider provider;
  const _MoodLineChart(this.provider);

  @override
  Widget build(BuildContext context) {
    final dailyMoods = provider.getMoodValuesPerDay();
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    // Build spots only for days with data
    List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      if (dailyMoods[i] != null) {
        spots.add(FlSpot(i.toDouble(), dailyMoods[i]!));
      }
    }

    if (spots.isEmpty) {
      return Center(
        child: Text('No mood data this week', style: TextStyle(color: Colors.grey[400])),
      );
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 6,
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
                  case 5: return const Text('😊', style: TextStyle(fontSize: 14));
                  case 3: return const Text('😐', style: TextStyle(fontSize: 14));
                  case 1: return const Text('😰', style: TextStyle(fontSize: 14));
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
                int i = value.toInt();
                if (i >= 0 && i < dayLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(dayLabels[i], style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots
                  .map((spot) => LineTooltipItem(
                        'Mood: ${spot.y.toStringAsFixed(1)}',
                        const TextStyle(color: Colors.white),
                      ))
                  .toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.orange,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData:
                BarAreaData(show: true, color: Colors.orange.withValues(alpha: 0.1)),
          )
        ],
      ),
    );
  }
}

// --- Habit Bar Chart (Weekly Completions) ---
class _HabitBarChart extends StatelessWidget {
  final AnalyticsProvider provider;
  const _HabitBarChart(this.provider);

  @override
  Widget build(BuildContext context) {
    final dailyCompletions = provider.getHabitCompletionsPerDay();
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hasData = dailyCompletions.any((v) => v > 0);

    if (!hasData && provider.weeklyHabits.isEmpty) {
      return Center(
        child: Text('No habits created yet', style: TextStyle(color: Colors.grey[400])),
      );
    }

    final maxY = hasData
        ? dailyCompletions.reduce((a, b) => a > b ? a : b) + 1
        : 5.0;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} habits',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value == value.roundToDouble()) {
                  return Text('${value.toInt()}', style: TextStyle(fontSize: 10, color: Colors.grey[600]));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int i = value.toInt();
                if (i >= 0 && i < dayLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(dayLabels[i], style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (i) {
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: dailyCompletions[i],
              color: Colors.green,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            )
          ]);
        }),
      ),
    );
  }
}

// --- Screen Time Area Chart (Real Data) ---
class _ScreenTimeAreaChart extends StatelessWidget {
  final AnalyticsProvider provider;
  const _ScreenTimeAreaChart(this.provider);

  @override
  Widget build(BuildContext context) {
    final dailyScreenTime = provider.getScreenTimePerDay();
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hasData = dailyScreenTime.any((v) => v > 0);
    
    // Always build spots for all 7 days (including zeros)
    List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), dailyScreenTime[i]));
    }

    if (!hasData) {
      return Center(
        child: Text('No screen time data this week', style: TextStyle(color: Colors.grey[400])),
      );
    }

    double maxY = dailyScreenTime.reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: (maxY + 2).clamp(6, 24),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text('${value.toInt()}h', style: TextStyle(fontSize: 10, color: Colors.grey[600]));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int i = value.toInt();
                if (i >= 0 && i < dayLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(dayLabels[i], style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots
                  .map((spot) => LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)}h',
                        const TextStyle(color: Colors.white),
                      ))
                  .toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData:
                BarAreaData(show: true, color: Colors.purple.withValues(alpha: 0.1)),
          )
        ],
      ),
    );
  }
}