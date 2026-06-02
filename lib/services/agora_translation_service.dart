import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Service to handle Agora STT translation via Firebase Cloud Functions
class AgoraTranslationService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _currentTaskId;
  String? _currentChannelName;

  // Callbacks
  Function(String originalText, String translatedText)? onTranslation;
  Function(String error)? onError;

  /// Start transcription for a video call
  Future<bool> startTranscription({
    required String channelName,
    required String userId,
    String sourceLanguage = 'en-US',
    String targetLanguage = 'es',
  }) async {
    try {
      debugPrint(
        'AgoraTranslationService: Starting transcription for $channelName',
      );

      final callable = _functions.httpsCallable('startTranscription');
      final result = await callable.call({
        'channelName': channelName,
        'userId': userId,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
      });

      if (result.data['success'] == true) {
        _currentTaskId = result.data['agentName'];
        _currentChannelName = channelName;
        debugPrint(
          'AgoraTranslationService: Transcription started, taskId: $_currentTaskId',
        );

        // Start listening for transcription results
        _startListeningForTranscriptions();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('AgoraTranslationService: Error starting transcription: $e');
      onError?.call('Failed to start translation: $e');
      return false;
    }
  }

  /// Stop transcription
  Future<void> stopTranscription() async {
    if (_currentTaskId == null) return;

    try {
      debugPrint('AgoraTranslationService: Stopping transcription');

      final callable = _functions.httpsCallable('stopTranscription');
      await callable.call({'taskId': _currentTaskId});

      _currentTaskId = null;
      _currentChannelName = null;
      debugPrint('AgoraTranslationService: Transcription stopped');
    } catch (e) {
      debugPrint('AgoraTranslationService: Error stopping transcription: $e');
      onError?.call('Failed to stop translation: $e');
    }
  }

  /// Listen for transcription results from Firestore
  void _startListeningForTranscriptions() {
    if (_currentChannelName == null) return;

    _firestore
        .collection('transcriptions')
        .where('channelName', isEqualTo: _currentChannelName)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.docs.isNotEmpty) {
              final doc = snapshot.docs.first;
              final data = doc.data();

              final originalText = data['originalText'] as String? ?? '';
              final translatedText = data['translatedText'] as String? ?? '';

              if (originalText.isNotEmpty || translatedText.isNotEmpty) {
                onTranslation?.call(originalText, translatedText);
              }
            }
          },
          onError: (error) {
            debugPrint(
              'AgoraTranslationService: Firestore listen error: $error',
            );
            onError?.call('Translation stream error: $error');
          },
        );
  }

  /// Map language name to BCP-47 code for Agora STT
  /// Agora requires full BCP-47 format (e.g., 'gu-IN' not 'gu')
  static String mapLanguageToCode(String language) {
    switch (language.toLowerCase()) {
      case 'spanish':
        return 'es-ES';
      case 'french':
        return 'fr-FR';
      case 'german':
        return 'de-DE';
      case 'italian':
        return 'it-IT';
      case 'portuguese':
        return 'pt-PT';
      case 'hindi':
        return 'hi-IN';
      case 'japanese':
        return 'ja-JP';
      case 'korean':
        return 'ko-KR';
      case 'chinese':
        return 'zh-CN';
      case 'arabic':
        return 'ar-SA';
      case 'russian':
        return 'ru-RU';
      case 'gujarati':
        return 'gu-IN';
      case 'kannada':
        return 'kn-IN';
      case 'tamil':
        return 'ta-IN';
      case 'telugu':
        return 'te-IN';
      case 'english':
        return 'en-US';
      default:
        return 'en-US';
    }
  }

  /// Check if transcription is currently active
  bool get isActive => _currentTaskId != null;

  /// Dispose resources
  void dispose() {
    stopTranscription();
  }
}
