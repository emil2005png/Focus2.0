import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String id;
  final String userId;
  final String mood; // e.g., 'Happy', 'Sad', 'Anxious'
  final DateTime timestamp;
  final String? note;

  MoodEntry({
    required this.id,
    required this.userId,
    required this.mood,
    required this.timestamp,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'mood': mood,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map, String id) {
    return MoodEntry(
      id: id,
      userId: map['userId'] ?? '',
      mood: map['mood'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      note: map['note'],
    );
  }
}
