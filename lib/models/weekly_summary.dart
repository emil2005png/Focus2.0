import 'package:focus_app/models/badge.dart' as app_badge;

class WeeklySummary {
  final double averageScreenTime;
  final String bestDay;
  final int hydrationStreak;
  final int totalWaterIntake;

  WeeklySummary({
    required this.averageScreenTime,
    required this.bestDay,
    required this.hydrationStreak,
    required this.totalWaterIntake,
  });
}

class WeeklyData {
  final List<app_badge.Badge> badges;
  final WeeklySummary summary;

  WeeklyData({required this.badges, required this.summary});
}
