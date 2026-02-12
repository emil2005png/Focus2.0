import 'package:cloud_firestore/cloud_firestore.dart';

class Distraction {
  final String? id;
  final String userId;
  final String type;
  final int durationMinutes;
  final String? note;
  final DateTime timestamp;

  Distraction({
    this.id,
    required this.userId,
    required this.type,
    required this.durationMinutes,
    this.note,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'durationMinutes': durationMinutes,
      'note': note,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory Distraction.fromMap(Map<String, dynamic> map, String id) {
    return Distraction(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? '',
      durationMinutes: map['durationMinutes']?.toInt() ?? 0,
      note: map['note'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
