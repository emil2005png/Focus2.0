import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:focus_app/models/mood_entry.dart';
import 'package:focus_app/models/distraction_model.dart';
import 'package:focus_app/models/daily_plan.dart';
import 'package:focus_app/models/habit.dart';
import 'package:focus_app/models/daily_health_log.dart';
// import 'package:focus_app/models/journal_entry.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection References
  CollectionReference get _usersCollection => _db.collection('users');
  
  DocumentReference get _userDoc {
    if (_userId == null) throw Exception('User not logged in');
    return _usersCollection.doc(_userId);
  }

  CollectionReference get _moodsCollection => _userDoc.collection('moods');
  CollectionReference get _journalsCollection => _userDoc.collection('journals');
  CollectionReference get _habitsCollection => _userDoc.collection('habits');
  
  // --- User Profile ---

  // Check if username is already taken
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final QuerySnapshot result = await _usersCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return result.docs.isEmpty;
    } catch (e) {
      print('Error checking username: $e');
      return false; // Assume taken on error to be safe, or handle differently
    }
  }

  // Create user profile
  Future<void> createUserProfile({
    required String uid,
    required String email,
    required String username,
    String? fullName,
  }) async {
    await _usersCollection.doc(uid).set({
      'username': username,
      'email': email,
      'fullName': fullName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Moods ---

  // Add a mood entry
  Future<void> addMood({required int moodIndex, String? note}) async {
    // Map mood index to emoji
    final List<String> emojis = ['😊', '🤩', '😌', '😔', '😰', '😴'];
    final List<String> moods = ['Happy', 'Excited', 'Calm', 'Sad', 'Anxious', 'Tired'];
    
    await _moodsCollection.add({
      'moodIndex': moodIndex,
      'mood': emojis[moodIndex], // Save emoji for display
      'moodName': moods[moodIndex], // Save name for reference
      'note': note,
      'timestamp': FieldValue.serverTimestamp(),
      'date': DateTime.now().toIso8601String().split('T')[0], // For easy querying by date
    });
  }

  // Check if user has checked in today
  Future<bool> hasCheckedInToday() async {
    try {
      if (_userId == null) return false;
      
      String today = DateTime.now().toIso8601String().split('T')[0];
      
      QuerySnapshot snapshot = await _moodsCollection
          .where('date', isEqualTo: today)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking daily check-in: $e');
      return false; // Default to false on error so they can try again
    }
  }

  // Get mood history (example)
  Stream<QuerySnapshot> getMoodHistory() {
    return _moodsCollection.orderBy('timestamp', descending: true).snapshots();
  }

  // Get user profile
  Stream<DocumentSnapshot> getUserProfile() {
    return _userDoc.snapshots();
  }

  // Get stream of latest mood
  Stream<String?> getLatestMoodStream() {
    if (_userId == null) return Stream.value(null);
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    return _moodsCollection
        .where('date', isEqualTo: today)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final data = snapshot.docs.first.data() as Map<String, dynamic>;
            return data['mood'] as String?;
          }
          return null;
        });
  }

  // Update user profile (creates if not exists)
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    await _userDoc.set(data, SetOptions(merge: true));
  }

  // Upload profile image
  Future<String> uploadProfileImage(File imageFile) async {
    if (_userId == null) throw Exception('User not logged in');
    
    try {
      final String filePath = 'user_profiles/$_userId.jpg';
      print('Attempting to upload to: $filePath');
      
      final Reference storageRef = _storage.ref().child(filePath);
      
      // Set metadata (optional but good practice)
      final SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');

      final UploadTask uploadTask = storageRef.putFile(imageFile, metadata);
      
      // Listen to stream for debug
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload state: ${snapshot.state}, bytes: ${snapshot.bytesTransferred}');
      }, onError: (e) {
        print('Upload stream error: $e');
      });

      final TaskSnapshot snapshot = await uploadTask;
      print('Upload finished. State: ${snapshot.state}');

      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await storageRef.getDownloadURL();
        print('Got download URL: $downloadUrl');
        
        // Update Firestore with new photo URL
        await updateUserProfile({'photoUrl': downloadUrl});
        return downloadUrl;
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      print('Detailed upload error: $e');
      rethrow;
    }
  }
  // --- Journals ---

  // Add a journal entry
  Future<void> addJournal(String title, String content, {String? mood}) async {
    await _journalsCollection.add({
      'title': title,
      'content': content,
      'mood': mood,
      'timestamp': FieldValue.serverTimestamp(),
      'date': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  // Update a journal entry
  Future<void> updateJournal(String id, String title, String content, {String? mood}) async {
    await _journalsCollection.doc(id).update({
      'title': title,
      'content': content,
      'mood': mood,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a journal entry
  Future<void> deleteJournal(String id) async {
    await _journalsCollection.doc(id).delete();
  }

  // Get journals stream
  Stream<QuerySnapshot> getJournals() {
    return _journalsCollection.orderBy('timestamp', descending: true).snapshots();
  }

  // --- Dashboard Stats ---

  // Update Focus Stats
  Future<void> updateFocusStats(int minutes) async {
    final userRef = _userDoc;
    
    // Use a transaction to ensure atomic updates
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      
      if (!snapshot.exists) return;
      
      final data = snapshot.data() as Map<String, dynamic>;
      final currentTotal = data['totalFocusMinutes'] ?? 0;
      final currentStreak = data['currentStreak'] ?? 0;
      final lastFocusDate = data['lastFocusDate'];
      
      final now = DateTime.now();
      final todayStr = now.toIso8601String().split('T')[0];
      
      int newStreak = currentStreak;
      
      if (lastFocusDate != todayStr) {
        // If last focus was yesterday, increment streak
        // We'd need to parse the date properly, but for simplicity:
        // increment if consecutive. For now, let's just increment if not today.
        // A robust streak needs date comparisons.
        
        // Normalize both dates to midnight for accurate day comparison
        if (lastFocusDate != null) {
           final lastDate = DateTime.parse(lastFocusDate);
           final today = DateTime(now.year, now.month, now.day);
           final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
           final difference = today.difference(lastDay).inDays;
           if (difference == 1) {
             newStreak++;
           } else if (difference > 1) {
             newStreak = 1; // Reset streak
           }
        } else {
          newStreak = 1; // First time
        }
      }

      transaction.update(userRef, {
        'totalFocusMinutes': currentTotal + minutes,
        'currentStreak': newStreak,
        'lastFocusDate': todayStr,
      });
    });
  }

  // Get Moods for Last 7 Days
  Future<List<Map<String, dynamic>>> getMoodsForLast7Days() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      final snapshot = await _moodsCollection
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .orderBy('timestamp')
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'mood': data['mood'] ?? '😐', // Default to neutral if missing
          'date': (data['timestamp'] as Timestamp).toDate(),
        };
      }).toList();
    } catch (e) {
      print("Error fetching mood history: $e");
      return [];
    }
  }

  // Get User Stats (Stream)
  Stream<DocumentSnapshot> getUserStats() {
    return _userDoc.snapshots();
  }
  // --- Distractions ---

  CollectionReference get _distractionsCollection => _userDoc.collection('distractions');

  // Add a distraction
  Future<void> addDistraction({
    required String type,
    required int durationMinutes,
    String? note,
  }) async {
    if (_userId == null) throw Exception('User not logged in');

    await _distractionsCollection.add({
      'userId': _userId,
      'type': type,
      'durationMinutes': durationMinutes,
      'note': note,
      'timestamp': FieldValue.serverTimestamp(),
      'date': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  // Get distractions stream
  Stream<QuerySnapshot> getDistractions() {
    return _distractionsCollection.orderBy('timestamp', descending: true).snapshots();
  }

  // Get today's distractions (Future)
  Future<List<Map<String, dynamic>>> getTodayDistractions() async {
    try {
       final today = DateTime.now().toIso8601String().split('T')[0];
       final snapshot = await _distractionsCollection.where('date', isEqualTo: today).get();
       
       return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting today distractions: $e');
      return [];
    }
  }

  // Get distractions for the last 7 days
  Future<List<Map<String, dynamic>>> getDistractionsForWeek() async {
    try {
       final now = DateTime.now();
       final sevenDaysAgo = now.subtract(const Duration(days: 7));
       
       final snapshot = await _distractionsCollection
           .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
           .get();
       
       return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting weekly distractions: $e');
      return [];
    }
  }

  // Get today's latest mood
  Future<String?> getTodayMood() async {
     try {
       final today = DateTime.now().toIso8601String().split('T')[0];
       final snapshot = await _moodsCollection
           .where('date', isEqualTo: today)
           .orderBy('timestamp', descending: true)
           .limit(1)
           .get();
       
       if (snapshot.docs.isNotEmpty) {
         final data = snapshot.docs.first.data() as Map<String, dynamic>;
         // Try to get mood emoji, fallback to moodName or convert from index
         if (data.containsKey('mood')) {
           return data['mood'] as String?;
         } else if (data.containsKey('moodName')) {
           return data['moodName'] as String?;
         } else if (data.containsKey('moodIndex')) {
           final List<String> moods = ['Happy', 'Excited', 'Calm', 'Sad', 'Anxious', 'Tired'];
           int index = data['moodIndex'] as int;
           return moods[index];
         }
       }
       return null;
    } catch (e) {
      print('Error getting today mood: $e');
      return null;
    }
  }

  // Check if user has played mini game today
  Future<bool> hasPlayedMiniGameToday() async {
    try {
      if (_userId == null) return false;
      
      final snapshot = await _userDoc.get();
      if (!snapshot.exists) return false;
      
      final data = snapshot.data() as Map<String, dynamic>;
      final lastGameDate = data['lastMiniGameDate'];
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      return lastGameDate == today;
    } catch (e) {
      print('Error checking mini game status: $e');
      return false; 
    }
  }

  // Record that mini game was played
  Future<void> recordMiniGamePlayed(int durationMinutes) async {
    final userRef = _userDoc;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return; 

      final data = snapshot.data() as Map<String, dynamic>;
      final currentTotal = data['totalFocusMinutes'] ?? 0;
       
      transaction.update(userRef, {
        'lastMiniGameDate': today,
        'totalFocusMinutes': currentTotal + durationMinutes,
      });
    });
  }
  // --- Habits ---

  // Add a new habit
  Future<void> addHabit(String title, {String timeOfDay = 'morning', String motivationalMessage = 'Keep growing!'}) async {
    if (_userId == null) throw Exception('User not logged in');

    await _habitsCollection.add({
      'userId': _userId,
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'completedDates': [],
      'streak': 0,
      'plantType': 'default',
      'timeOfDay': timeOfDay,
      'motivationalMessage': motivationalMessage,
    });
  }

  // Get habits stream
  Stream<List<Habit>> getHabits() {
    return _habitsCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Habit.fromSnapshot(doc)).toList();
    });
  }

  // Toggle habit completion
  Future<void> toggleHabitCompletion(Habit habit, DateTime date) async {
    final habitRef = _habitsCollection.doc(habit.id);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(habitRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      List<DateTime> completedDates = (data['completedDates'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ?? [];
      
      int currentStreak = data['streak'] ?? 0;

      // Check if already completed today
      final isCompletedToday = completedDates.any((d) => 
          d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day);

      if (isCompletedToday) {
        // Remove completion (Undo)
        completedDates.removeWhere((d) => 
            d.year == dateOnly.year && d.month == dateOnly.month && d.day == dateOnly.day);
        
        // Recalculate streak (This is complex to do perfectly backwards without full history analysis, 
        // but for now, if we undo today, we might just decrement if streak > 0. 
        // A robust solution would recount from history.)
        // Simplified Logic: If undoing today, and streak > 0, decrement.
        // Better Logic: Recalculate streak from remaining dates.
        currentStreak = _calculateStreak(completedDates);

      } else {
        // Add completion
        completedDates.add(date);
        
        // Recalculate streak
        currentStreak = _calculateStreak(completedDates);
      }

      transaction.update(habitRef, {
        'completedDates': completedDates.map((e) => Timestamp.fromDate(e)).toList(),
        'streak': currentStreak,
      });
    });
  }

  int _calculateStreak(List<DateTime> completedDates) {
    if (completedDates.isEmpty) return 0;

    // Sort dates
    final sortedDates = List<DateTime>.from(completedDates)..sort();
    
    int streak = 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Check if the last completion was today or yesterday to start the streak count
    final lastCompletion = sortedDates.last;
    final lastCompletionDate = DateTime(lastCompletion.year, lastCompletion.month, lastCompletion.day);
    
    final diff = todayDate.difference(lastCompletionDate).inDays;
    
    // If last completion was more than 1 day ago (i.e. missed yesterday and today), streak is 0.
    if (diff > 1) return 0;

    // Count backwards
    streak = 1;
    for (int i = sortedDates.length - 1; i > 0; i--) {
      final current = sortedDates[i];
      final prev = sortedDates[i - 1];
      
      final currentDate = DateTime(current.year, current.month, current.day);
      final prevDate = DateTime(prev.year, prev.month, prev.day);
      
      final difference = currentDate.difference(prevDate).inDays;
      
      if (difference == 1) {
        streak++;
      } else if (difference == 0) {
        // Same day, continue
        continue;
      } else {
        // Break in streak
        break;
      }
    }
    return streak;
  }

  // Delete habit
  Future<void> deleteHabit(String habitId) async {
    await _habitsCollection.doc(habitId).delete();
  }

  // --- Daily Health Logs ---

  final CollectionReference _healthLogsCollection = FirebaseFirestore.instance.collection('health_logs');

  Stream<DailyHealthLog?> getDailyHealthLog(DateTime date) {
    if (_userId == null) return Stream.value(null);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _healthLogsCollection
        .where('userId', isEqualTo: _userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return DailyHealthLog.fromSnapshot(snapshot.docs.first);
        });
  }

  Future<List<DailyHealthLog>> getHealthLogsForLast7Days() async {
    if (_userId == null) return [];
    
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final startOfSevenDaysAgo = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day);

    final snapshot = await _healthLogsCollection
        .where('userId', isEqualTo: _userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfSevenDaysAgo))
        .orderBy('date')
        .get();

    return snapshot.docs
        .map((doc) => DailyHealthLog.fromSnapshot(doc))
        .toList();
  }

  Future<void> updateDailyHealthLog(DateTime date, double sleepHours, int exerciseMinutes, int waterGlasses, double screenTimeHours) async {
    if (_userId == null) throw Exception('User not logged in');

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = await _healthLogsCollection
        .where('userId', isEqualTo: _userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await _healthLogsCollection.doc(query.docs.first.id).update({
        'sleepHours': sleepHours,
        'exerciseMinutes': exerciseMinutes,
        'waterGlasses': waterGlasses,
        'screenTimeHours': screenTimeHours,
      });
    } else {
      await _healthLogsCollection.add({
        'userId': _userId,
        'date': Timestamp.fromDate(date),
        'sleepHours': sleepHours,
        'exerciseMinutes': exerciseMinutes,
        'waterGlasses': waterGlasses,
        'screenTimeHours': screenTimeHours,
      });
    }
  }
  // --- Daily Plan Methods ---

  Stream<DailyPlan?> getDailyPlanStream(DateTime date) {
    if (_userId == null) return Stream.value(null);

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _db
        .collection('users')
        .doc(_userId)
        .collection('daily_plans')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return DailyPlan.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }

  Future<void> saveDailyPlan(DailyPlan plan) async {
    if (_userId == null) return;

    final planRef = _db
        .collection('users')
        .doc(_userId)
        .collection('daily_plans');

    if (plan.id.isEmpty || plan.id == 'new') {
      // Create new
      // Firestore generates ID automatically with add()
      // We don't necessarily need to set the ID in the document data if we rely on doc.id
      // but let's keep it clean.
      await planRef.add(plan.toFirestore());
    } else {
      // Update existing
      await planRef.doc(plan.id).update(plan.toFirestore());
    }
  }

  Future<void> updateDailyPlanTask(String planId, int taskIndex, bool isCompleted) async {
    if (_userId == null) return;

    final docRef = _db
        .collection('users')
        .doc(_userId)
        .collection('daily_plans')
        .doc(planId);
    
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      List<dynamic> tasks = List.from(data['tasks'] ?? []);
      
      if (taskIndex >= 0 && taskIndex < tasks.length) {
         Map<String, dynamic> task = Map.from(tasks[taskIndex]);
         task['isCompleted'] = isCompleted;
         tasks[taskIndex] = task;
         
         transaction.update(docRef, {'tasks': tasks});
      }
    });
  }
}

