import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/services/firestore_service.dart';
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
          actions: [
            if (kDebugMode)
              IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.indigo),
                tooltip: 'Generate Mock Data',
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating Data...')));
                  await FirestoreService().generateMockData();
                  if (context.mounted) {
                    context.read<AnalyticsProvider>().loadWeeklyData();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mock Data Generated!')));
                  }
                },
              ),
          ],
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
            Colors.orange,
            _buildMiniLineChart(provider.getMoodValuesPerDay(), Colors.orange)),
        _insightTile(
            context,
            'Habit Consistency',
            provider.getHabitConsistency(),
            Icons.check_circle,
            Colors.green,
            _buildMiniBarChart(provider.getHabitCompletionsPerDay(), Colors.green)),
        _insightTile(
            context,
            'Best Focus Day',
            provider.getBestFocusDay(),
            Icons.timer,
            Colors.blue,
            _buildMiniBarChart(provider.getFocusMinutesPerDay(), Colors.blue)),
        _insightTile(
            context,
            'Screen Usage',
            provider.getScreenUsageChange(),
            Icons.app_blocking,
            Colors.purple,
            _buildMiniAreaChart(provider.getScreenTimePerDay(), Colors.purple)),
      ],
    );
  }

  Widget _insightTile(BuildContext context, String label, String value, IconData icon, Color color, Widget miniChart) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.02), blurRadius: 10)
          ]),
      child: Stack(
        children: [
          // Background mini chart
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 48,
            child: Opacity(
              opacity: 0.25,
              child: miniChart,
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBarChart(List<double> data, Color color) {
    if (data.every((v) => v == 0)) return const SizedBox();
    double maxY = data.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 1;
    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(enabled: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(toY: data[i], color: color, width: 8, borderRadius: BorderRadius.circular(2))
          ]);
        }),
      ),
    );
  }

  Widget _buildMiniLineChart(List<double?> data, Color color) {
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
        spots.add(FlSpot(i.toDouble(), data[i] ?? 0));
    }
    if (spots.every((s) => s.y == 0)) return const SizedBox();
    
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 6,
        lineTouchData: LineTouchData(enabled: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          )
        ],
      ),
    );
  }

  Widget _buildMiniAreaChart(List<double> data, Color color) {
    if (data.every((v) => v == 0)) return const SizedBox();
    List<FlSpot> spots = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    
    return LineChart(
      LineChartData(
        minY: 0,
        lineTouchData: LineTouchData(enabled: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.3)),
          )
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
                'Focus Activity', _FocusLineChart(provider)),
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

// --- Focus Line Chart (Real Data) ---
class _FocusLineChart extends StatelessWidget {
  final AnalyticsProvider provider;
  const _FocusLineChart(this.provider);

  @override
  Widget build(BuildContext context) {
    final dailyMinutes = provider.getFocusMinutesPerDay();
    final dayLabels = provider.getDayLabels();
    final maxY = dailyMinutes.isEmpty ? 60.0 : (dailyMinutes.reduce((a, b) => a > b ? a : b)).clamp(30.0, 500.0);
    final hasData = dailyMinutes.any((v) => v > 0);

    List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), dailyMinutes[i]));
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY + (maxY * 0.2), // Add 20% padding at top
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value % 10 != 0 && value != 0) return const SizedBox.shrink(); // declutter y-axis
                return Text('${value.toInt()}m', style: TextStyle(fontSize: 10, color: Colors.grey[600]));
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
                    child: Text(dayLabels[i], style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
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
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200]!, strokeWidth: 1, dashArray: [5, 5]),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.indigo.withValues(alpha: 0.9),
            tooltipPadding: const EdgeInsets.all(8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) => LineTooltipItem(
                '${spot.y > 0 && spot.y < 1 ? spot.y.toStringAsFixed(1) : spot.y.toInt()} mins',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              )).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        showingTooltipIndicators: hasData ? spots.asMap().keys.where((i) => spots[i].y > 0).map((i) => ShowingTooltipIndicators([LineBarSpot(LineChartBarData(spots: spots), 0, spots[i])])).toList() : [],
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: Colors.indigo,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: spot.y > 0 ? 4 : 0,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: Colors.indigo,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.withValues(alpha: 0.3),
                  Colors.blue.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          )
        ],
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
    final dayLabels = provider.getDayLabels();
    
    // Build spots only for days with data
    List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      if (dailyMoods[i] != null) {
        spots.add(FlSpot(i.toDouble(), dailyMoods[i]!));
      }
    }

    if (spots.isEmpty) {
      return Center(
        child: Text('No mood data in the last 7 days', style: TextStyle(color: Colors.grey[400])),
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
          enabled: false,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots
                  .map((spot) => LineTooltipItem(
                        spot.y.toStringAsFixed(1),
                        const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10),
                      ))
                  .toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            showingIndicators: spots.asMap().keys.toList(),
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
    final dayLabels = provider.getDayLabels();
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
          enabled: false,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 4,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (rod.toY == 0) return null;
              return BarTooltipItem(
                '${rod.toY.toInt()}',
                const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
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
          return BarChartGroupData(
            x: i,
            showingTooltipIndicators: dailyCompletions[i] > 0 ? [0] : [],
            barRods: [
              BarChartRodData(
                toY: dailyCompletions[i],
                color: Colors.green,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              )
            ]
          );
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
    final dayLabels = provider.getDayLabels();
    final hasData = dailyScreenTime.any((v) => v > 0);
    
    // Always build spots for all 7 days (including zeros)
    List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      spots.add(FlSpot(i.toDouble(), dailyScreenTime[i]));
    }

    if (!hasData) {
      return Center(
        child: Text('No screen time data in the last 7 days', style: TextStyle(color: Colors.grey[400])),
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
          enabled: false,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots
                  .map((spot) => LineTooltipItem(
                        spot.y == 0 ? '' : '${spot.y.toStringAsFixed(1)}h',
                        const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 10),
                      ))
                  .toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            showingIndicators: spots.asMap().keys.where((i) => spots[i].y > 0).toList(),
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