import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:focus_app/models/mood_entry.dart';
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
    await _moodsCollection.add({
      'moodIndex': moodIndex,
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
        
        // Simple Logic: If lastFocusDate is not today, check if it was yesterday.
        if (lastFocusDate != null) {
           final lastDate = DateTime.parse(lastFocusDate);
           final difference = DateTime.now().difference(lastDate).inDays;
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
}
