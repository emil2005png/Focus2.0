import 'package:flutter/material.dart';
import 'package:focus_app/models/calendar_activity.dart';
import 'package:focus_app/models/habit.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:focus_app/services/notification_service.dart';

class CalendarProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();
  
  List<CalendarActivity> _activities = [];
  List<Habit> _habits = [];
  final Map<String, String> _moodsByDate = {}; // date string -> mood emoji
  
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  List<CalendarActivity> get activities => _activities;
  DateTime get selectedDay => _selectedDay;
  DateTime get focusedDay => _focusedDay;

  CalendarProvider() {
    _init();
  }

  void _init() {
    _firestoreService.getCalendarActivities().listen((activities) {
      _activities = activities;
      notifyListeners();
    });

    _firestoreService.getHabits().listen((habits) {
      _habits = habits;
      notifyListeners();
    });

    _loadMoodMarkers();
  }

  Future<void> _loadMoodMarkers() async {
    // For simplicity, load last 30 days of moods
    final start = DateTime.now().subtract(const Duration(days: 30));
    final end = DateTime.now().add(const Duration(days: 1));
    final moods = await _firestoreService.getMoodsForRange(start, end);
    for (var m in moods) {
      final date = m['date'] as String?;
      final emoji = m['mood'] as String?;
      if (date != null && emoji != null) {
        _moodsByDate[date] = emoji;
      }
    }
    notifyListeners();
  }

  void setSelectedDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }

  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
  }

  List<CalendarActivity> getActivitiesForDay(DateTime day) {
    return _activities.where((activity) {
      return isSameDay(activity.dateTime, day);
    }).toList();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool hasHabitCompletion(DateTime day) {
    final dateOnly = DateTime(day.year, day.month, day.day);
    return _habits.any((h) => h.completedDates.any((d) => isSameDay(d, dateOnly)));
  }

  String? getMoodForDay(DateTime day) {
    final dateStr = day.toIso8601String().split('T')[0];
    return _moodsByDate[dateStr];
  }

  Future<void> addActivity(String title, String description, DateTime dateTime, {String type = 'activity'}) async {
    final activity = CalendarActivity(
      id: '',
      title: title,
      description: description,
      dateTime: dateTime,
      createdAt: DateTime.now(),
      type: type,
    );
    await _firestoreService.addCalendarActivity(activity);
    
    if (type == 'exam') {
      await _notificationService.scheduleExamCountdown(title, dateTime);
    }
  }

  Future<void> updateActivity(CalendarActivity activity) async {
    await _firestoreService.updateCalendarActivity(activity);
    // Note: If type changed to exam or date changed, we'd need to re-schedule notifications
  }

  Future<void> deleteActivity(String activityId) async {
    await _firestoreService.deleteCalendarActivity(activityId);
  }
}
