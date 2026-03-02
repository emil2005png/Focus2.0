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

  // Method to convert Habit to a Map for Firestore (keeps 'streak' for backwards compatibility/caching if needed)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedDates': completedDates.map((e) => Timestamp.fromDate(e)).toList(),
      'streak': streak, // This remains the 'saved' streak, but we'll prefer the dynamic one
      'plantType': plantType,
      'timeOfDay': timeOfDay,
      'motivationalMessage': motivationalMessage,
    };
  }

  // Dynamic Streak Calculation
  int get currentStreak {
    if (completedDates.isEmpty) return 0;

    // Get unique dates (normalized to midnight) and sort them descending
    final uniqueDates = completedDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // If the latest completion is not today or yesterday, streak is broken
    final lastCompletion = uniqueDates.first;
    final diffDays = today.difference(lastCompletion).inDays;
    
    if (diffDays > 1) return 0;

    int count = 1;
    for (int i = 0; i < uniqueDates.length - 1; i++) {
      final current = uniqueDates[i];
      final next = uniqueDates[i + 1];
      if (current.difference(next).inDays == 1) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  // Logic to determine the plant stage based on streak and recency
  String get plantStage {
    if (completedDates.isEmpty) return '🌱'; 

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sortedDates = List<DateTime>.from(completedDates)..sort();
    final lastCompletion = sortedDates.last;
    final lastCompletionDate = DateTime(lastCompletion.year, lastCompletion.month, lastCompletion.day);
    
    final difference = today.difference(lastCompletionDate).inDays;

    if (difference > 1) {
      return '🥀'; // Faded/Wilted
    }

    // Growth stages based on current dynamic streak
    final s = currentStreak;
    if (s >= 14) return '🌳'; 
    if (s >= 7) return '🌸'; 
    if (s >= 3) return '🪴'; 
    if (s >= 1) return '🌿'; 
    
    return '🌱'; 
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
