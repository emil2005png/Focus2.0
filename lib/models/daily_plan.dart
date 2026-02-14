import 'package:cloud_firestore/cloud_firestore.dart';

class DailyPlan {
  final String id;
  final DateTime date;
  final List<String> priorities;
  final List<Map<String, dynamic>> tasks; // { 'title': String, 'isCompleted': bool }
  final String notes;

  DailyPlan({
    required this.id,
    required this.date,
    required this.priorities,
    this.tasks = const [],
    this.notes = '',
  });

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'priorities': priorities,
      'tasks': tasks, // Firestore handles List<Map> natively
      'notes': notes,
    };
  }

  factory DailyPlan.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DailyPlan(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      priorities: List<String>.from(data['priorities'] ?? []),
      tasks: List<Map<String, dynamic>>.from(
        (data['tasks'] ?? []).map((item) => Map<String, dynamic>.from(item))
      ),
      notes: data['notes'] ?? '',
    );
  }

  DailyPlan copyWith({
    List<String>? priorities,
    List<Map<String, dynamic>>? tasks,
    String? notes,
  }) {
    return DailyPlan(
      id: id,
      date: date,
      priorities: priorities ?? this.priorities,
      tasks: tasks ?? this.tasks,
      notes: notes ?? this.notes,
    );
  }
}
