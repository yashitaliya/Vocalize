import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/session_data.dart';
import '../models/test_model.dart';
import '../models/test_result_model.dart';

/// Firestore service for user data
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Users collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Create or update user document
  Future<void> saveUser(UserModel user) async {
    await _usersCollection
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  /// Get user by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        if ((data['uid'] as String?)?.trim().isEmpty ?? true) {
          data['uid'] = doc.id;
        }
        return UserModel.fromMap(data);
      }
    } catch (e) {
      // Return null if there's an error (e.g., network issue)
      print('Error getting user: $e');
    }
    return null;
  }

  /// Stream user document for real-time updates
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        if ((data['uid'] as String?)?.trim().isEmpty ?? true) {
          data['uid'] = doc.id;
        }
        return UserModel.fromMap(data);
      }
      return null;
    });
  }

  /// Stream raw user document snapshot to distinguish
  /// "loading first snapshot" from "document does not exist".
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserDocStream(String uid) {
    return _usersCollection.doc(uid).snapshots();
  }

  /// Update user interests (creates document if doesn't exist)
  Future<void> updateInterests(String uid, List<String> interests) async {
    await _usersCollection.doc(uid).set({
      'interests': interests,
    }, SetOptions(merge: true));
  }

  /// Update user selected language (creates document if doesn't exist)
  Future<void> updateSelectedLanguage(String uid, String language) async {
    await _usersCollection.doc(uid).set({
      'selectedLanguage': language,
    }, SetOptions(merge: true));
  }

  /// Save onboarding preferences atomically to avoid partial writes.
  Future<void> saveOnboardingPreferences({
    required String uid,
    required List<String> interests,
    required String selectedLanguage,
  }) async {
    await _usersCollection.doc(uid).set({
      'interests': interests,
      'selectedLanguage': selectedLanguage,
    }, SetOptions(merge: true));
  }

  /// Update user profile
  Future<void> updateProfile({
    required String uid,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (fullName != null) updates['fullName'] = fullName;
    if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

    if (updates.isNotEmpty) {
      await _usersCollection.doc(uid).set(updates, SetOptions(merge: true));
    }
  }

  /// Delete user document
  Future<void> deleteUser(String uid) async {
    await _usersCollection.doc(uid).delete();
  }

  // --- Session Analysis Persistence ---

  /// Save session analysis data
  Future<void> saveSessionAnalysis(String sessionId, SessionData data) async {
    try {
      await _firestore
          .collection('session_analysis')
          .doc(sessionId)
          .set(data.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving session analysis: $e');
    }
  }

  /// Get session analysis data
  Future<SessionData?> getSessionAnalysis(String sessionId) async {
    try {
      final doc = await _firestore
          .collection('session_analysis')
          .doc(sessionId)
          .get();
      if (doc.exists && doc.data() != null) {
        return SessionData.fromMap(doc.data()!);
      }
    } catch (e) {
      print('Error getting session analysis: $e');
    }
    return null;
  }

  /// Update user high score if the new score is higher
  /// Returns true if a new high score was set
  Future<bool> updateUserHighScore(String uid, int newScore) async {
    try {
      final userDoc = _usersCollection.doc(uid);
      final snapshot = await userDoc.get();

      if (snapshot.exists) {
        final currentHighScore = snapshot.data()?['highScore'] as int? ?? 0;
        if (newScore > currentHighScore) {
          await userDoc.update({'highScore': newScore});
          return true;
        }
      } else {
        // If user doesn't exist (edge case), set it
        await userDoc.set({'highScore': newScore}, SetOptions(merge: true));
        return true;
      }
    } catch (e) {
      print('Error updating high score: $e');
    }
    return false;
  }

  // --- Test Methods ---

  /// Create or update a test
  Future<void> createTest(TestModel test) async {
    try {
      await _firestore
          .collection('tests')
          .doc(test.testId)
          .set(test.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error creating test: $e');
    }
  }

  /// Get all tests for a specific language
  Future<List<TestModel>> getTestsForLanguage(String language) async {
    try {
      final snapshot = await _firestore
          .collection('tests')
          .where('language', isEqualTo: language)
          .orderBy('level')
          .get();

      return snapshot.docs.map((doc) => TestModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Error getting tests: $e');
      return [];
    }
  }

  /// Delete all tests for a language
  Future<void> deleteTestsForLanguage(String language) async {
    try {
      final snapshot = await _firestore
          .collection('tests')
          .where('language', isEqualTo: language)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting tests: $e');
    }
  }

  /// Save test result
  Future<void> saveTestResult(TestResultModel result) async {
    try {
      await _firestore
          .collection('test_results')
          .doc(result.resultId)
          .set(result.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving test result: $e');
    }
  }

  /// Get test result for a user and test
  Future<TestResultModel?> getTestResult(String userId, String testId) async {
    try {
      final snapshot = await _firestore
          .collection('test_results')
          .where('userId', isEqualTo: userId)
          .where('testId', isEqualTo: testId)
          .orderBy('completedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return TestResultModel.fromMap(snapshot.docs.first.data());
      }
    } catch (e) {
      print('Error getting test result: $e');
    }
    return null;
  }

  /// Get all test results for a user (Stream)
  Stream<List<TestResultModel>> getUserTestResultsStream(String userId) {
    return _firestore
        .collection('test_results')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TestResultModel.fromMap(doc.data()))
              .toList();
        });
  }

  /// Get all test results for a user (Future)
  Future<List<TestResultModel>> getUserTestResults(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('test_results')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => TestResultModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting user test results: $e');
      return [];
    }
  }

  /// Get vocabulary words for a specific language
  Future<List<Map<String, dynamic>>> getVocabularyByLanguage(String language) async {
    try {
      final snapshot = await _firestore
          .collection('vocabulary')
          .where('language', isEqualTo: language)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting vocabulary: $e');
      return [];
    }
  }
}
