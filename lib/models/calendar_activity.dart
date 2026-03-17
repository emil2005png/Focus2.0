import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarActivity {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final DateTime createdAt;
  final String type; // 'activity' or 'exam'
  final bool isCompleted;

  CalendarActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.createdAt,
    this.type = 'activity',
    this.isCompleted = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type,
      'isCompleted': isCompleted,
    };
  }

  factory CalendarActivity.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CalendarActivity(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      type: data['type'] ?? 'activity',
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  CalendarActivity copyWith({
    String? title,
    String? description,
    DateTime? dateTime,
    String? type,
    bool? isCompleted,
  }) {
    return CalendarActivity(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      createdAt: createdAt,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
