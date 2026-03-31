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

  List<String> getDayLabels() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<String> labels = [];
    for (int i = 0; i < 7; i++) {
       final d = today.subtract(Duration(days: 6 - i));
       labels.add(DateFormat('E').format(d));
    }
    return labels;
  }

  Future<void> loadWeeklyData() async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfRange = today.subtract(const Duration(days: 6));
    final endOfRange = DateTime(now.year, now.month, now.day, 23, 59, 59);

    try {
      _weeklyFocusSessions = await _firestoreService.getFocusSessionsForRange(startOfRange, endOfRange);
    } catch (e) {
      debugPrint('Error loading focus sessions: $e');
      _weeklyFocusSessions = [];
    }

    try {
      _weeklyMoods = await _firestoreService.getMoodsForRange(startOfRange, endOfRange);
    } catch (e) {
      debugPrint('Error loading moods: $e');
      _weeklyMoods = [];
    }

    try {
      _weeklyHealthLogs = await _firestoreService.getHealthLogsForRange(startOfRange, endOfRange);
    } catch (e) {
      debugPrint('Error loading health logs: $e');
      _weeklyHealthLogs = [];
    }
      
    try {
      final habitsSnapshot = await _firestoreService.getHabits().first;
      _weeklyHabits = habitsSnapshot;
    } catch (e) {
      debugPrint('Error loading habits: $e');
      _weeklyHabits = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  double _getSessionMinutes(Map<String, dynamic> session) {
    if (session.containsKey('durationMinutes')) {
      return (session['durationMinutes'] as num? ?? 0).toDouble();
    }
    if (session.containsKey('actualFocusDurationSeconds')) {
      int secs = (session['actualFocusDurationSeconds'] as num?)?.toInt() ?? 0;
      return secs / 60.0;
    }
    return 0.0;
  }

  // --- Computed Insight Values ---

  /// Returns "Improving", "Declining", or "Stable" based on mood trend
  String getMoodTrend() {
    if (_weeklyMoods.isEmpty) return 'Stable →';
    if (_weeklyMoods.length == 1) return 'Stable →';
    
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
    if (_weeklyHabits.isEmpty) return '0%';
    
    int totalCompleted = 0;
    int totalPossible = 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfRange = today.subtract(const Duration(days: 6));
    
    for (var habit in _weeklyHabits) {
      // Count how many days this week each habit was completed
      for (var date in habit.completedDates) {
        final d = DateTime(date.year, date.month, date.day);
        if (!d.isBefore(startOfRange) && !d.isAfter(today)) {
          totalCompleted++;
        }
      }
      totalPossible += 7;
    }
    
    if (totalPossible == 0) return '0%';
    double rate = (totalCompleted / totalPossible * 100).clamp(0, 100);
    return '${rate.toInt()}%';
  }

  /// Returns the day of the week with the most focus minutes
  String getBestFocusDay() {
    if (_weeklyFocusSessions.isEmpty) return 'None';
    
    Map<String, double> dayMinutes = {};
    
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
      double mins = _getSessionMinutes(session);
      dayMinutes[dayName] = (dayMinutes[dayName] ?? 0.0) + mins;
    }
    
    if (dayMinutes.isEmpty) return 'None';
    
    var best = dayMinutes.entries.reduce((a, b) => a.value > b.value ? a : b);
    return best.key;
  }

  /// Returns screen usage change compared to previous data
  String getScreenUsageChange() {
    if (_weeklyHealthLogs.isEmpty) return '0.0h avg';
    
    double totalScreenTime = _weeklyHealthLogs.fold(0.0, (acc, log) => acc + log.screenTimeHours);
    double avgScreenTime = totalScreenTime / _weeklyHealthLogs.length;
    
    if (avgScreenTime > 6) return '${avgScreenTime.toStringAsFixed(1)}h avg (High)';
    if (avgScreenTime > 4) return '${avgScreenTime.toStringAsFixed(1)}h avg';
    return '${avgScreenTime.toStringAsFixed(1)}h avg (Low)';
  }

  /// Focus minutes per day of the week (Mon=0 to Sun=6)
  List<double> getFocusMinutesPerDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfRange = today.subtract(const Duration(days: 6));
    
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
      
      final d = DateTime(date.year, date.month, date.day);
      int dayIndex = d.difference(startOfRange).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        double mins = _getSessionMinutes(session);
        dailyMinutes[dayIndex] += mins;
      }
    }
    
    return dailyMinutes;
  }

  /// Mood values per day of the week
  List<double?> getMoodValuesPerDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfRange = today.subtract(const Duration(days: 6));
    
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
      
      final d = DateTime(date.year, date.month, date.day);
      int dayIndex = d.difference(startOfRange).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        String moodName = mood['moodName'] ?? mood['mood'] ?? '';
        dailyMoods[dayIndex] = moodValues[moodName] ?? 3.0;
      }
    }
    
    return dailyMoods;
  }

  /// Screen time per day of the week (includes zero-value days)
  List<double> getScreenTimePerDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfRange = today.subtract(const Duration(days: 6));
    
    List<double> dailyScreenTime = List.filled(7, 0.0);
    
    for (var log in _weeklyHealthLogs) {
      final d = DateTime(log.date.year, log.date.month, log.date.day);
      int dayIndex = d.difference(startOfRange).inDays;
      if (dayIndex >= 0 && dayIndex < 7) {
        dailyScreenTime[dayIndex] = log.screenTimeHours;
      }
    }
    
    return dailyScreenTime;
  }

  /// Habit completions per day of the week (Mon=0 to Sun=6)
  List<double> getHabitCompletionsPerDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfRange = today.subtract(const Duration(days: 6));
    
    List<double> dailyCompletions = List.filled(7, 0.0);
    
    for (var habit in _weeklyHabits) {
      for (var date in habit.completedDates) {
        final d = DateTime(date.year, date.month, date.day);
        int dayIndex = d.difference(startOfRange).inDays;
        if (dayIndex >= 0 && dayIndex < 7) {
          dailyCompletions[dayIndex] += 1;
        }
      }
    }
    return dailyCompletions;
  }

  String getWeeklySummary() {
    if (_isLoading) return "Generating summary...";
    
    double totalFocusMins = 0;
    for (var s in _weeklyFocusSessions) {
      totalFocusMins += _getSessionMinutes(s);
    }
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

    return "This week, you focused for a total of ${totalFocusMins.toStringAsFixed(1)} minutes. "
           "Your average sleep was ${avgSleep.toStringAsFixed(1)} hours, and predominant mood was $predominantMood. "
           "Weekly screen time averaged ${avgScreenTime.toStringAsFixed(1)} hours. "
           "${totalFocusMins > 300 ? 'Excellent productivity!' : 'Try to set more focus goals next week.'}";
  }
}
