import 'package:cloud_firestore/cloud_firestore.dart';

class FocusSession {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration focusDuration; // Targeted
  final Duration actualFocusDuration;
  final Duration breakDuration; // Targeted
  final Duration actualBreakDuration;
  final String purpose;
  final bool isCompleted;

  FocusSession({
    this.id = '',
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.focusDuration,
    this.actualFocusDuration = Duration.zero,
    this.breakDuration = Duration.zero,
    this.actualBreakDuration = Duration.zero,
    this.purpose = 'Focus Session',
    this.isCompleted = false,
  });

  factory FocusSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FocusSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      startTime: data['startTime'] != null ? (data['startTime'] as Timestamp).toDate() : DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      focusDuration: Duration(seconds: data['focusDurationSeconds'] ?? 0),
      actualFocusDuration: Duration(seconds: data['actualFocusDurationSeconds'] ?? 0),
      breakDuration: Duration(seconds: data['breakDurationSeconds'] ?? 0),
      actualBreakDuration: Duration(seconds: data['actualBreakDurationSeconds'] ?? 0),
      purpose: data['purpose'] ?? 'Focus Session',
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'focusDurationSeconds': focusDuration.inSeconds,
      'actualFocusDurationSeconds': actualFocusDuration.inSeconds,
      'breakDurationSeconds': breakDuration.inSeconds,
      'actualBreakDurationSeconds': actualBreakDuration.inSeconds,
      'purpose': purpose,
      'isCompleted': isCompleted,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  FocusSession copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    Duration? focusDuration,
    Duration? actualFocusDuration,
    Duration? breakDuration,
    Duration? actualBreakDuration,
    String? purpose,
    bool? isCompleted,
  }) {
    return FocusSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      focusDuration: focusDuration ?? this.focusDuration,
      actualFocusDuration: actualFocusDuration ?? this.actualFocusDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      actualBreakDuration: actualBreakDuration ?? this.actualBreakDuration,
      purpose: purpose ?? this.purpose,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
