import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final List<DateTime> completedDates;
  final int streak; // Current streak
  final String plantType; // For future extensibility (e.g., 'rose', 'cactus')
  final String timeOfDay; // 'morning', 'afternoon', 'night'
  final String motivationalMessage;

  Habit({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.completedDates,
    required this.streak,
    this.plantType = 'default',
    this.timeOfDay = 'morning', // Default to morning
    this.motivationalMessage = 'Keep growing!', // Default message
  });

  // Factory constructor to create a Habit from a Firestore DocumentSnapshot
  factory Habit.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Habit(
      id: snapshot.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedDates: (data['completedDates'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [],
      streak: data['streak'] ?? 0,
      plantType: data['plantType'] ?? 'default',
      timeOfDay: data['timeOfDay'] ?? 'morning',
      motivationalMessage: data['motivationalMessage'] ?? 'Keep growing!',
    );
  }

  // Method to convert Habit to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedDates': completedDates.map((e) => Timestamp.fromDate(e)).toList(),
      'streak': streak,
      'plantType': plantType,
      'timeOfDay': timeOfDay,
      'motivationalMessage': motivationalMessage,
    };
  }

  // Logic to determine the plant stage based on streak and recency
  String get plantStage {
    // Check if missed yesterday (faded)
    // We need to check if the last completion was before yesterday.
    // If completed today, it's fine.
    // If completed yesterday, it's fine.
    // If completed before yesterday (or never), it's potentially fading.

    if (completedDates.isEmpty) return '🌱'; // Seed

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Sort dates to satisfy the "last" check
    final sortedDates = List<DateTime>.from(completedDates)..sort();
    final lastCompletion = sortedDates.last;
    final lastCompletionDate = DateTime(lastCompletion.year, lastCompletion.month, lastCompletion.day);
    
    final difference = today.difference(lastCompletionDate).inDays;

    if (difference > 1) {
      return '🥀'; // Faded/Wilted if missed more than 1 day (i.e., didn't do it yesterday or today)
    }

    // Growth stages based on streak
    if (streak >= 14) return '🌳'; // Fully grown tree/large plant
    if (streak >= 7) return '🌸'; // Blooming
    if (streak >= 3) return '🪴'; // Small Plant
    if (streak >= 1) return '🌿'; // Sprout
    
    return '🌱'; // Default Seed
  }

  // Helper to check if completed today
  bool get isCompletedToday {
    if (completedDates.isEmpty) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Check if any completion date matches today
    return completedDates.any((date) {
      final d = DateTime(date.year, date.month, date.day);
      return d.isAtSameMomentAs(today);
    });
  }
}
