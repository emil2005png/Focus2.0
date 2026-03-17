import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PointsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // ─── Point Values ───────────────────────────────────────────
  static const int pointsDailyLogin = 10;
  static const int pointsMoodCheckIn = 20;
  static const int pointsHabitComplete = 15;
  static const int pointsHealthLog = 25;
  static const int pointsFocusSession = 30;
  static const int pointsJournalEntry = 20;
  static const int pointsVisionGoal = 50;
  static const int bonusDailyTasks = 100; // 3 tasks in 1 day
  static const int bonus7DayStreak = 200;
  static const int bonus30DayStreak = 500;
  static const int dailyBonusThreshold = 3;

  // ─── Unlock Costs ───────────────────────────────────────────
  static const Map<String, int> unlockCosts = {
    'hydration_hero': 500,
    'sleep_guardian': 1000,
    'fitness_starter': 1500,
    'study_warrior': 2000,
  };

  // ─── Streak Grace Period ────────────────────────────────────
  static const int streakGraceDays = 3;

  DocumentReference get _userRef {
    if (_userId == null) throw Exception('User not logged in');
    return _db.collection('users').doc(_userId);
  }

  // ═══════════════════════════════════════════════════════════
  //  CORE: Add Points
  // ═══════════════════════════════════════════════════════════
  Future<int> addPoints(int amount, String reason) async {
    if (_userId == null) return 0;

    int newTotal = 0;

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(_userRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final currentPoints = data['totalPoints'] ?? 0;
      newTotal = currentPoints + amount;

      transaction.update(_userRef, {
        'totalPoints': newTotal,
      });

      // Log point history
      transaction.set(_userRef.collection('point_history').doc(), {
        'amount': amount,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });

    return newTotal;
  }

  // ═══════════════════════════════════════════════════════════
  //  STREAK: Check and Update (3-day grace period)
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> checkAndUpdateStreak() async {
    if (_userId == null) return {'streak': 0, 'broken': false};

    final snapshot = await _userRef.get();
    if (!snapshot.exists) return {'streak': 0, 'broken': false};

    final data = snapshot.data() as Map<String, dynamic>;
    final currentStreak = data['currentStreak'] ?? 0;
    final lastActiveDate = data['lastActiveDate'] as String?;
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    // Already active today — no change
    if (lastActiveDate == todayStr) {
      return {'streak': currentStreak, 'broken': false};
    }

    int newStreak = currentStreak;
    bool broken = false;
    int bonusAwarded = 0;

    if (lastActiveDate != null) {
      final lastDate = DateTime.parse(lastActiveDate);
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final daysDiff = today.difference(lastDay).inDays;

      if (daysDiff == 1) {
        // Consecutive day — increment
        newStreak++;
      } else if (daysDiff <= streakGraceDays) {
        // Within grace period — increment (they came back in time)
        newStreak++;
      } else {
        // Streak broken (> 3 days inactive)
        broken = true;
        newStreak = 1; // start fresh
      }
    } else {
      newStreak = 1; // first ever activity
    }

    // Milestone bonuses
    if (newStreak == 7) {
      bonusAwarded = bonus7DayStreak;
    } else if (newStreak == 30) {
      bonusAwarded = bonus30DayStreak;
    }

    final updateData = <String, dynamic>{
      'currentStreak': newStreak,
      'lastActiveDate': todayStr,
    };

    if (broken) {
      updateData['streakBrokenAt'] = currentStreak; // save for life restore
    }

    await _userRef.update(updateData);

    if (bonusAwarded > 0) {
      await addPoints(bonusAwarded, newStreak == 7 ? '7-Day Streak Bonus 🔥' : '30-Day Streak Bonus 🏆');
    }

    return {
      'streak': newStreak,
      'broken': broken,
      'previousStreak': broken ? currentStreak : null,
      'bonus': bonusAwarded,
    };
  }

  // ═══════════════════════════════════════════════════════════
  //  LIVES: Monthly Life System
  // ═══════════════════════════════════════════════════════════
  Future<void> _ensureMonthlyLifeReset() async {
    if (_userId == null) return;

    final snapshot = await _userRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data() as Map<String, dynamic>;
    final currentMonthStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
    final lastResetMonth = data['lastLifeResetMonth'] as String?;

    if (lastResetMonth != currentMonthStr) {
      await _userRef.update({
        'monthlyLivesRemaining': 1,
        'lastLifeResetMonth': currentMonthStr,
      });
    }
  }

  Future<Map<String, dynamic>> useLife() async {
    if (_userId == null) return {'success': false, 'message': 'Not logged in'};

    await _ensureMonthlyLifeReset();

    final snapshot = await _userRef.get();
    if (!snapshot.exists) return {'success': false, 'message': 'No profile'};

    final data = snapshot.data() as Map<String, dynamic>;
    final lives = data['monthlyLivesRemaining'] ?? 0;
    final brokenAt = data['streakBrokenAt'] ?? 0;

    if (lives <= 0) {
      return {'success': false, 'message': 'No lives remaining this month'};
    }
    if (brokenAt <= 0) {
      return {'success': false, 'message': 'No broken streak to restore'};
    }

    await _userRef.update({
      'monthlyLivesRemaining': lives - 1,
      'currentStreak': brokenAt,
      'streakBrokenAt': 0,
      'lastActiveDate': DateTime.now().toIso8601String().split('T')[0],
    });

    return {'success': true, 'restoredStreak': brokenAt};
  }

  // ═══════════════════════════════════════════════════════════
  //  UNLOCKABLES
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> unlockSection(String sectionId) async {
    if (_userId == null) return {'success': false, 'message': 'Not logged in'};

    final cost = unlockCosts[sectionId];
    if (cost == null) return {'success': false, 'message': 'Invalid section'};

    final snapshot = await _userRef.get();
    if (!snapshot.exists) return {'success': false, 'message': 'No profile'};

    final data = snapshot.data() as Map<String, dynamic>;
    final totalPoints = data['totalPoints'] ?? 0;
    final unlocked = List<String>.from(data['unlockedSections'] ?? []);

    if (unlocked.contains(sectionId)) {
      return {'success': false, 'message': 'Already unlocked'};
    }
    if (totalPoints < cost) {
      return {'success': false, 'message': 'Not enough points (need $cost, have $totalPoints)'};
    }

    await _userRef.update({
      'totalPoints': totalPoints - cost,
      'unlockedSections': FieldValue.arrayUnion([sectionId]),
    });

    // Log point history for unlock spend
    await _userRef.collection('point_history').add({
      'amount': -cost,
      'reason': 'Unlocked: $sectionId',
      'timestamp': FieldValue.serverTimestamp(),
    });

    return {'success': true, 'remainingPoints': totalPoints - cost};
  }

  // ═══════════════════════════════════════════════════════════
  //  AWARD HELPERS — Each action type
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> awardMoodCheckIn() async {
    final pts = await addPoints(pointsMoodCheckIn, 'Daily Mood Check-in 😊');
    final streakResult = await checkAndUpdateStreak();
    return {'points': pointsMoodCheckIn, 'total': pts, ...streakResult};
  }

  Future<Map<String, dynamic>> awardHabitCompletion(String habitName) async {
    final pts = await addPoints(pointsHabitComplete, 'Completed: $habitName 🌱');
    final streakResult = await checkAndUpdateStreak();
    return {'points': pointsHabitComplete, 'total': pts, ...streakResult};
  }

  Future<Map<String, dynamic>> awardHealthLog() async {
    final pts = await addPoints(pointsHealthLog, 'Health Log Saved 💪');
    final streakResult = await checkAndUpdateStreak();
    return {'points': pointsHealthLog, 'total': pts, ...streakResult};
  }

  Future<Map<String, dynamic>> awardFocusSession(int minutes) async {
    final pts = await addPoints(pointsFocusSession, 'Focus Session: ${minutes}min 🎯');
    final streakResult = await checkAndUpdateStreak();
    return {'points': pointsFocusSession, 'total': pts, ...streakResult};
  }

  Future<Map<String, dynamic>> awardJournalEntry() async {
    final pts = await addPoints(pointsJournalEntry, 'Journal Entry ✍️');
    final streakResult = await checkAndUpdateStreak();
    return {'points': pointsJournalEntry, 'total': pts, ...streakResult};
  }

  Future<Map<String, dynamic>> awardTaskCompletion() async {
    if (_userId == null) return {'points': 0, 'bonus': 0};

    int bonus = 0;

    // Check daily bonus
    final todayTasks = await _db
        .collection('users')
        .doc(_userId)
        .collection('vision_board_tasks')
        .where('isCompleted', isEqualTo: true)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
        .get();

    if (todayTasks.docs.length == dailyBonusThreshold) {
      bonus = bonusDailyTasks;
    }

    int totalAdded = pointsVisionGoal + bonus;
    final pts = await addPoints(totalAdded, 'Completed Vision Goal 🏆');
    final streakResult = await checkAndUpdateStreak();

    return {'points': pointsVisionGoal, 'bonus': bonus, 'total': pts, ...streakResult};
  }

  Future<int> awardDailyEngagement() async {
    if (_userId == null) return 0;

    final snapshot = await _userRef.get();
    if (!snapshot.exists) return 0;

    final data = snapshot.data() as Map<String, dynamic>;
    final lastEngagedDate = data['lastEngagedDate'];
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    if (lastEngagedDate != todayStr) {
      await _userRef.update({'lastEngagedDate': todayStr});
      return await addPoints(pointsDailyLogin, 'Daily login reward 📱');
    }

    return 0;
  }

  // ═══════════════════════════════════════════════════════════
  //  STREAMS
  // ═══════════════════════════════════════════════════════════
  Stream<int> getTotalPointsStream() {
    if (_userId == null) return Stream.value(0);
    return _db.collection('users').doc(_userId).snapshots().map((snapshot) {
      if (!snapshot.exists) return 0;
      final data = snapshot.data() as Map<String, dynamic>;
      return data['totalPoints'] ?? 0;
    });
  }

  Stream<Map<String, dynamic>> getGamificationDataStream() {
    if (_userId == null) {
      return Stream.value({
        'totalPoints': 0,
        'currentStreak': 0,
        'monthlyLivesRemaining': 1,
        'streakBrokenAt': 0,
        'unlockedSections': <String>[],
      });
    }

    return _db.collection('users').doc(_userId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return {
          'totalPoints': 0,
          'currentStreak': 0,
          'monthlyLivesRemaining': 1,
          'streakBrokenAt': 0,
          'unlockedSections': <String>[],
        };
      }
      final data = snapshot.data() as Map<String, dynamic>;

      // Auto-reset monthly life if needed
      final currentMonthStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
      final lastResetMonth = data['lastLifeResetMonth'] as String?;
      int lives = data['monthlyLivesRemaining'] ?? 1;
      if (lastResetMonth != currentMonthStr) {
        lives = 1; // will be synced on next write
      }

      return {
        'totalPoints': data['totalPoints'] ?? 0,
        'currentStreak': data['currentStreak'] ?? 0,
        'monthlyLivesRemaining': lives,
        'streakBrokenAt': data['streakBrokenAt'] ?? 0,
        'unlockedSections': List<String>.from(data['unlockedSections'] ?? []),
        'lastActiveDate': data['lastActiveDate'],
      };
    });
  }

  Stream<List<Map<String, dynamic>>> getPointHistoryStream() {
    if (_userId == null) return Stream.value([]);
    return _userRef
        .collection('point_history')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'amount': data['amount'] ?? 0,
                'reason': data['reason'] ?? '',
                'timestamp': data['timestamp'],
              };
            }).toList());
  }
}
