import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vocabulary_model.dart';

/// Utility class for setting up vocabulary data in Firebase
/// Run this once to populate the database with all vocabulary words
class FirebaseVocabSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload all vocabulary data to Firebase
  /// Call this function once to initialize the database
  static Future<void> setupVocabularyDatabase() async {
    try {
      print('Starting vocabulary database setup...');
      
      // Get all vocabulary from local data
      final allVocabData = _getAllVocabularyData();
      
      // Delete existing vocabulary data
      await _clearVocabularyCollection();
      
      // Add vocabulary data in batches
      await _addVocabularyBatch(allVocabData);
      
      print('✓ Vocabulary database setup completed successfully!');
    } catch (e) {
      print('✗ Error setting up vocabulary database: $e');
      rethrow;
    }
  }

  /// Get all vocabulary data from local models
  static List<Map<String, dynamic>> _getAllVocabularyData() {
    final allData = <Map<String, dynamic>>[];

    for (String language in VocabularySampleData.languages) {
      final words = VocabularySampleData.getSampleData(language);
      
      for (var word in words) {
        allData.add({
          'id': word.id,
          'word': word.word,
          'translation': word.translation,
          'pronunciation': word.pronunciation,
          'example': word.example,
          'category': word.category,
          'language': language,
          'isLearned': word.isLearned,
          'addedAt': word.addedAt.toIso8601String(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }

    print('Total vocabulary items to upload: ${allData.length}');
    return allData;
  }

  /// Clear existing vocabulary collection
  static Future<void> _clearVocabularyCollection() async {
    try {
      final docs = await _firestore.collection('vocabulary').get();
      for (var doc in docs.docs) {
        await doc.reference.delete();
      }
      print('Cleared existing vocabulary data');
    } catch (e) {
      print('Error clearing vocabulary collection: $e');
    }
  }

  /// Add vocabulary data in batches (Firestore has batch size limits)
  static Future<void> _addVocabularyBatch(
    List<Map<String, dynamic>> vocabularyList,
  ) async {
    const batchSize = 500; // Firestore batch size limit
    
    for (int i = 0; i < vocabularyList.length; i += batchSize) {
      final batchEnd = (i + batchSize < vocabularyList.length)
          ? i + batchSize
          : vocabularyList.length;
      
      final batch = _firestore.batch();
      
      for (int j = i; j < batchEnd; j++) {
        final docRef = _firestore.collection('vocabulary').doc();
        batch.set(docRef, vocabularyList[j]);
      }
      
      await batch.commit();
      print('Uploaded batch ${(i ~/ batchSize) + 1}');
    }
  }

  /// Get vocabulary statistics
  static Future<Map<String, dynamic>> getVocabularyStats() async {
    try {
      final snapshot = await _firestore.collection('vocabulary').get();
      final languages = <String>{};
      final categories = <String>{};
      
      for (var doc in snapshot.docs) {
        final language = doc['language'] as String?;
        final category = doc['category'] as String?;
        if (language != null) languages.add(language);
        if (category != null) categories.add(category);
      }
      
      return {
        'totalWords': snapshot.docs.length,
        'languages': languages.toList(),
        'categories': categories.toList(),
        'languageCount': languages.length,
        'categoryCount': categories.length,
      };
    } catch (e) {
      print('Error getting vocabulary stats: $e');
      return {};
    }
  }

  /// Check if vocabulary database is already populated
  static Future<bool> isVocabularyPopulated() async {
    try {
      final snapshot =
          await _firestore.collection('vocabulary').limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking vocabulary population: $e');
      return false;
    }
  }
}
