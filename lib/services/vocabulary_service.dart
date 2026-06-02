import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Model for a vocabulary item
class VocabWord {
  final String id;
  final String original;
  final String translated;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime createdAt;
  final String? sessionId;

  VocabWord({
    required this.id,
    required this.original,
    required this.translated,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.createdAt,
    this.sessionId,
  });

  factory VocabWord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VocabWord(
      id: doc.id,
      original: data['original'] ?? '',
      translated: data['translated'] ?? '',
      sourceLanguage: data['sourceLanguage'] ?? 'en-US',
      targetLanguage: data['targetLanguage'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      sessionId: data['sessionId'],
    );
  }

  Map<String, dynamic> toMap() => {
    'original': original,
    'translated': translated,
    'sourceLanguage': sourceLanguage,
    'targetLanguage': targetLanguage,
    'createdAt': FieldValue.serverTimestamp(),
    'sessionId': sessionId,
  };
}

/// Service for managing vocabulary learning during calls
class VocabularyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache to prevent duplicate saves within a session
  final Set<String> _savedWords = {};

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _vocabCollection {
    if (_userId == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(_userId).collection('vocabulary');
  }

  /// Save a word pair to Firestore (with deduplication)
  Future<bool> saveWord({
    required String original,
    required String translated,
    String sourceLanguage = 'en-US',
    String targetLanguage = 'es',
    String? sessionId,
  }) async {
    if (_userId == null) return false;

    // Normalize and validate
    final normalizedOriginal = original.trim().toLowerCase();
    final normalizedTranslated = translated.trim().toLowerCase();

    if (normalizedOriginal.isEmpty || normalizedTranslated.isEmpty) {
      return false;
    }

    // Skip if already saved in this session
    final key = '$normalizedOriginal:$normalizedTranslated';
    if (_savedWords.contains(key)) {
      debugPrint('VocabularyService: Skipping duplicate: $key');
      return false;
    }

    try {
      // Check if word already exists in Firestore
      final existing = await _vocabCollection
          .where('original', isEqualTo: normalizedOriginal)
          .where('translated', isEqualTo: normalizedTranslated)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        debugPrint('VocabularyService: Word already exists in Firestore');
        _savedWords.add(key);
        return false;
      }

      // Save new word
      await _vocabCollection.add({
        'original': original.trim(),
        'translated': translated.trim(),
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
        'createdAt': FieldValue.serverTimestamp(),
        'sessionId': sessionId,
      });

      _savedWords.add(key);
      debugPrint('VocabularyService: Saved word: $original -> $translated');
      return true;
    } catch (e) {
      debugPrint('VocabularyService: Error saving word: $e');
      return false;
    }
  }

  /// Stream version of words learned today count (real-time)
  Stream<int> getWordsLearnedTodayStream() {
    if (_userId == null) return Stream.value(0);

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _vocabCollection
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get count of words learned today
  Future<int> getWordsLearnedToday() async {
    if (_userId == null) return 0;

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final snapshot = await _vocabCollection
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('VocabularyService: Error getting today count: $e');
      return 0;
    }
  }

  /// Stream version of total count of words learned
  Stream<int> getTotalWordsLearnedStream() {
    if (_userId == null) return Stream.value(0);

    return _vocabCollection.snapshots().map((snapshot) => snapshot.docs.length);
  }

  /// Get total count of words learned
  Future<int> getTotalWordsLearned() async {
    if (_userId == null) return 0;

    try {
      final snapshot = await _vocabCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('VocabularyService: Error getting total count: $e');
      return 0;
    }
  }

  /// Get recent vocabulary items
  Future<List<VocabWord>> getRecentWords({int limit = 20}) async {
    if (_userId == null) return [];

    try {
      final snapshot = await _vocabCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => VocabWord.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('VocabularyService: Error getting recent words: $e');
      return [];
    }
  }

  /// Clear session cache (call when leaving a call)
  void clearSessionCache() {
    _savedWords.clear();
  }

  // Common stop words to filter out
  static const _stopWords = {
    // English
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
    'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
    'should', 'may', 'might', 'must', 'shall', 'can', 'need', 'dare',
    'ought', 'used', 'to', 'of', 'in', 'for', 'on', 'with', 'at', 'by',
    'from', 'up', 'about', 'into', 'over', 'after', 'beneath', 'under',
    'above', 'i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves',
    'you', 'your', 'yours', 'yourself', 'yourselves', 'he', 'him', 'his',
    'himself', 'she', 'her', 'hers', 'herself', 'it', 'its', 'itself',
    'they', 'them', 'their', 'theirs', 'themselves', 'what', 'which', 'who',
    'whom', 'this', 'that', 'these', 'those', 'am', 'and', 'but', 'if',
    'or', 'because', 'as', 'until', 'while', 'not', 'no', 'nor', 'so',
    'than', 'too', 'very', 's', 't', 'just', 'don', 'now', 'ok', 'okay',
  };

  /// Save multiple words from a sentence (splits and filters)
  Future<int> saveWords({
    required String originalSentence,
    required String translatedSentence,
    String sourceLanguage = 'en-US',
    String targetLanguage = 'es',
    String? sessionId,
  }) async {
    if (_userId == null) return 0;

    // Split into words
    final originalWords = originalSentence
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !_stopWords.contains(w))
        .toList();

    final translatedWords = translatedSentence
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1)
        .toList();

    if (originalWords.isEmpty) return 0;

    int savedCount = 0;

    // Save each unique word pair
    for (int i = 0; i < originalWords.length; i++) {
      final original = originalWords[i];
      final translated = i < translatedWords.length
          ? translatedWords[i]
          : original;

      final saved = await saveWord(
        original: original,
        translated: translated,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
        sessionId: sessionId,
      );

      if (saved) savedCount++;
    }

    return savedCount;
  }

  /// Get words learned in a specific session
  Future<List<VocabWord>> getSessionWords(String sessionId) async {
    if (_userId == null) return [];

    try {
      final snapshot = await _vocabCollection
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs.map((doc) => VocabWord.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('VocabularyService: Error getting session words: $e');
      return [];
    }
  }

  // ===================== FAVORITES =====================

  CollectionReference<Map<String, dynamic>> get _favoritesCollection {
    if (_userId == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(_userId).collection('favorite_words');
  }

  /// Toggle favorite status for a vocabulary word
  Future<bool> toggleFavorite({
    required String word,
    required String translation,
    required String pronunciation,
    required String category,
    required String example,
    required String language,
  }) async {
    if (_userId == null) return false;

    try {
      // Use word+language as doc ID for deduplication
      final docId = '${word.toLowerCase().trim()}_${language.toLowerCase().trim()}';
      final docRef = _favoritesCollection.doc(docId);
      final doc = await docRef.get();

      if (doc.exists) {
        // Remove from favorites
        await docRef.delete();
        return false; // Not favorited anymore
      } else {
        // Add to favorites
        await docRef.set({
          'word': word,
          'translation': translation,
          'pronunciation': pronunciation,
          'category': category,
          'example': example,
          'language': language,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true; // Now favorited
      }
    } catch (e) {
      debugPrint('VocabularyService: Error toggling favorite: $e');
      return false;
    }
  }

  /// Check if a word is favorited
  Future<bool> isFavorite(String word, String language) async {
    if (_userId == null) return false;

    try {
      final docId = '${word.toLowerCase().trim()}_${language.toLowerCase().trim()}';
      final doc = await _favoritesCollection.doc(docId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Stream of favorite words (real-time)
  Stream<List<Map<String, dynamic>>> getFavoriteWordsStream() {
    if (_userId == null) return Stream.value([]);

    return _favoritesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Get all favorite words (future)
  Future<List<Map<String, dynamic>>> getFavoriteWords() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _favoritesCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint('VocabularyService: Error getting favorites: $e');
      return [];
    }
  }
}
