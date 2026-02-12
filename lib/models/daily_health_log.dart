import 'package:cloud_firestore/cloud_firestore.dart';

class DailyHealthLog {
  final String id;
  final String userId;
  final DateTime date;
  final double sleepHours;
  final int exerciseMinutes;
  final int waterGlasses;
  final double screenTimeHours;

  DailyHealthLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.sleepHours,
    required this.exerciseMinutes,
    required this.waterGlasses,
    this.screenTimeHours = 0.0,
  });

  factory DailyHealthLog.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyHealthLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      sleepHours: (data['sleepHours'] ?? 0).toDouble(),
      exerciseMinutes: data['exerciseMinutes'] ?? 0,
      waterGlasses: data['waterGlasses'] ?? 0,
      screenTimeHours: (data['screenTimeHours'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'sleepHours': sleepHours,
      'exerciseMinutes': exerciseMinutes,
      'waterGlasses': waterGlasses,
      'screenTimeHours': screenTimeHours,
    };
  }
}
