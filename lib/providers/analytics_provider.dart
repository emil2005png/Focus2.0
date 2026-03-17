import 'package:flutter/material.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:focus_app/models/daily_health_log.dart';
import 'package:focus_app/models/habit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<Map<String, dynamic>> _weeklyFocusSessions = [];
  List<Map<String, dynamic>> _weeklyMoods = [];
  List<DailyHealthLog> _weeklyHealthLogs = [];
  List<Habit> _weeklyHabits = [];
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> get weeklyFocusSessions => _weeklyFocusSessions;
  List<Map<String, dynamic>> get weeklyMoods => _weeklyMoods;
  List<DailyHealthLog> get weeklyHealthLogs => _weeklyHealthLogs;
  List<Habit> get weeklyHabits => _weeklyHabits;

  Future<void> loadWeeklyData() async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));

    try {
      _weeklyFocusSessions = await _firestoreService.getFocusSessionsForRange(startOfWeek, endOfWeek);
      _weeklyMoods = await _firestoreService.getMoodsForRange(startOfWeek, endOfWeek);
      _weeklyHealthLogs = await _firestoreService.getHealthLogsForRange(startOfWeek, endOfWeek);
      
      // Load current habits snapshot
      final habitsSnapshot = await _firestoreService.getHabits().first;
      _weeklyHabits = habitsSnapshot;
    } catch (e) {
      debugPrint('Error loading analytics data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Computed Insight Values ---

  /// Returns "Improving", "Declining", or "Stable" based on mood trend
  String getMoodTrend() {
    if (_weeklyMoods.length < 2) return 'No data';
    
    final Map<String, double> moodValues = {
      'Happy': 5.0, 'Excited': 5.0, 'Calm': 4.0,
      'Sad': 2.0, 'Anxious': 1.0, 'Tired': 2.0,
      '😊': 5.0, '🤩': 5.0, '😌': 4.0,
      '😔': 2.0, '😰': 1.0, '😴': 2.0, '😐': 3.0,
    };
    
    // Split into first half and second half
    int mid = _weeklyMoods.length ~/ 2;
    double firstHalfAvg = 0;
    double secondHalfAvg = 0;
    
    for (int i = 0; i < mid; i++) {
      String mood = _weeklyMoods[i]['moodName'] ?? _weeklyMoods[i]['mood'] ?? '';
      firstHalfAvg += moodValues[mood] ?? 3.0;
    }
    firstHalfAvg /= mid;
    
    for (int i = mid; i < _weeklyMoods.length; i++) {
      String mood = _weeklyMoods[i]['moodName'] ?? _weeklyMoods[i]['mood'] ?? '';
      secondHalfAvg += moodValues[mood] ?? 3.0;
    }
    secondHalfAvg /= (_weeklyMoods.length - mid);
    
    double diff = secondHalfAvg - firstHalfAvg;
    if (diff > 0.3) return 'Improving ↑';
    if (diff < -0.3) return 'Declining ↓';
    return 'Stable →';
  }

  /// Returns habit completion percentage string
  String getHabitConsistency() {
    if (_weeklyHabits.isEmpty) return 'No habits';
    
    int totalCompleted = 0;
    int totalPossible = 0;
    
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    for (var habit in _weeklyHabits) {
      // Count how many days this week each habit was completed
      for (var date in habit.completedDates) {
        final d = DateTime(date.year, date.month, date.day);
        final s = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        if (!d.isBefore(s)) {
          totalCompleted++;
        }
      }
      // Each habit could be completed each day of the week so far
      int daysSoFar = now.weekday; // Mon=1, Sun=7
      totalPossible += daysSoFar;
    }
    
    if (totalPossible == 0) return '0%';
    double rate = (totalCompleted / totalPossible * 100).clamp(0, 100);
    return '${rate.toInt()}%';
  }

  /// Returns the day of the week with the most focus minutes
  String getBestFocusDay() {
    if (_weeklyFocusSessions.isEmpty) return 'No data';
    
    Map<String, int> dayMinutes = {};
    
    for (var session in _weeklyFocusSessions) {
      DateTime date;
      if (session['timestamp'] is Timestamp) {
        date = (session['timestamp'] as Timestamp).toDate();
      } else if (session['startTime'] is Timestamp) {
        date = (session['startTime'] as Timestamp).toDate();
      } else {
        continue;
      }
      
      String dayName = DateFormat('EEEE').format(date);
      int mins = session['durationMinutes'] as int? ?? 0;
      dayMinutes[dayName] = (dayMinutes[dayName] ?? 0) + mins;
    }
    
    if (dayMinutes.isEmpty) return 'No data';
    
    var best = dayMinutes.entries.reduce((a, b) => a.value > b.value ? a : b);
    return best.key;
  }

  /// Returns screen usage change compared to previous data
  String getScreenUsageChange() {
    if (_weeklyHealthLogs.isEmpty) return 'No data';
    
    double totalScreenTime = _weeklyHealthLogs.fold(0.0, (acc, log) => acc + log.screenTimeHours);
    double avgScreenTime = totalScreenTime / _weeklyHealthLogs.length;
    
    if (avgScreenTime > 6) return '${avgScreenTime.toStringAsFixed(1)}h avg (High)';
    if (avgScreenTime > 4) return '${avgScreenTime.toStringAsFixed(1)}h avg';
    return '${avgScreenTime.toStringAsFixed(1)}h avg (Low)';
  }

  /// Focus minutes per day of the week (Mon=0 to Sun=6)
  List<double> getFocusMinutesPerDay() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    
    List<double> dailyMinutes = List.filled(7, 0.0);
    
    for (var session in _weeklyFocusSessions) {
      DateTime date;
      if (session['timestamp'] is Timestamp) {
        date = (session['timestamp'] as Timestamp).toDate();
      } else if (session['startTime'] is Timestamp) {
        date = (session['startTime'] as Timestamp).toDate();
      } else {
        continue;
      }
      
      int dayIndex = date.difference(startOfWeek).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        int mins = session['durationMinutes'] as int? ?? 0;
        dailyMinutes[dayIndex] += mins;
      }
    }
    
    return dailyMinutes;
  }

  /// Mood values per day of the week
  List<double?> getMoodValuesPerDay() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    
    final Map<String, double> moodValues = {
      'Happy': 5.0, 'Excited': 5.0, 'Calm': 4.0,
      'Sad': 2.0, 'Anxious': 1.0, 'Tired': 2.0,
      '😊': 5.0, '🤩': 5.0, '😌': 4.0,
      '😔': 2.0, '😰': 1.0, '😴': 2.0, '😐': 3.0,
    };
    
    List<double?> dailyMoods = List.filled(7, null);
    
    for (var mood in _weeklyMoods) {
      DateTime date;
      if (mood['timestamp'] is Timestamp) {
        date = (mood['timestamp'] as Timestamp).toDate();
      } else {
        continue;
      }
      
      int dayIndex = date.difference(startOfWeek).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        String moodName = mood['moodName'] ?? mood['mood'] ?? '';
        dailyMoods[dayIndex] = moodValues[moodName] ?? 3.0;
      }
    }
    
    return dailyMoods;
  }

  /// Screen time per day of the week
  List<double> getScreenTimePerDay() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    
    List<double> dailyScreenTime = List.filled(7, 0.0);
    
    for (var log in _weeklyHealthLogs) {
      int dayIndex = log.date.difference(startOfWeek).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        dailyScreenTime[dayIndex] = log.screenTimeHours;
      }
    }
    
    return dailyScreenTime;
  }

  String getWeeklySummary() {
    if (_isLoading) return "Generating summary...";
    
    int totalFocusMins = _weeklyFocusSessions.fold(0, (acc, item) => acc + (item['durationMinutes'] as int? ?? 0));
    double avgSleep = _weeklyHealthLogs.isEmpty ? 0 : _weeklyHealthLogs.fold(0.0, (acc, item) => acc + item.sleepHours) / _weeklyHealthLogs.length;
    double avgScreenTime = _weeklyHealthLogs.isEmpty ? 0 : _weeklyHealthLogs.fold(0.0, (acc, item) => acc + item.screenTimeHours) / _weeklyHealthLogs.length;
    
    String predominantMood = "Stable";
    if (_weeklyMoods.isNotEmpty) {
      Map<String, int> moodCounts = {};
      for (var m in _weeklyMoods) {
        String name = m['moodName'] ?? 'Unknown';
        moodCounts[name] = (moodCounts[name] ?? 0) + 1;
      }
      predominantMood = moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    return "This week, you focused for a total of $totalFocusMins minutes. "
           "Your average sleep was ${avgSleep.toStringAsFixed(1)} hours, and predominant mood was $predominantMood. "
           "Weekly screen time averaged ${avgScreenTime.toStringAsFixed(1)} hours. "
           "${totalFocusMins > 300 ? 'Excellent productivity!' : 'Try to set more focus goals next week.'}";
  }
}
