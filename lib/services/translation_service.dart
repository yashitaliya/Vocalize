import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Service for on-device speech recognition and translation.
/// Uses device's built-in speech engine (Siri/Google) and ML Kit for translation.
/// Cost: Completely FREE - no server bills!
class TranslationService {
  final SpeechToText _speechToText = SpeechToText();
  OnDeviceTranslator? _translator;

  bool _isInitialized = false;
  bool _isListening = false;

  String _sourceLanguage = 'en'; // BCP-47 code

  // Callbacks
  Function(String spokenText)? onSpeechResult;
  Function(String translatedText)? onTranslation;
  Function(String error)? onError;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
          onError?.call(error.errorMsg);
        },
        onStatus: (status) {
          debugPrint('Speech status: $status');
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize speech: $e');
      onError?.call('Failed to initialize speech recognition');
      return false;
    }
  }

  /// Set the language pair for translation
  /// [sourceCode] and [targetCode] should be BCP-47 codes like 'en', 'es', 'hi', 'fr'
  Future<void> setLanguages({
    required String sourceCode,
    required String targetCode,
  }) async {
    _sourceLanguage = sourceCode;

    try {
      // Create new translator with the language pair
      _translator?.close();
      _translator = OnDeviceTranslator(
        sourceLanguage: _mapToTranslateLanguage(sourceCode),
        targetLanguage: _mapToTranslateLanguage(targetCode),
      );

      // Download models in background - don't block the call
      _downloadModelsInBackground(sourceCode, targetCode);
    } catch (e) {
      debugPrint('Failed to set up translator: $e');
    }
  }

  /// Download translation models in background (fire-and-forget)
  void _downloadModelsInBackground(String sourceCode, String targetCode) async {
    try {
      final modelManager = OnDeviceTranslatorModelManager();

      final sourceDownloaded = await modelManager.isModelDownloaded(
        _mapToTranslateLanguage(sourceCode).bcpCode,
      );
      final targetDownloaded = await modelManager.isModelDownloaded(
        _mapToTranslateLanguage(targetCode).bcpCode,
      );

      if (!sourceDownloaded) {
        debugPrint(
          'Downloading $sourceCode translation model in background...',
        );
        modelManager.downloadModel(_mapToTranslateLanguage(sourceCode).bcpCode);
      }

      if (!targetDownloaded) {
        debugPrint(
          'Downloading $targetCode translation model in background...',
        );
        modelManager.downloadModel(_mapToTranslateLanguage(targetCode).bcpCode);
      }
    } catch (e) {
      debugPrint('Model download check failed: $e');
    }
  }

  /// Start listening for speech
  Future<void> startListening() async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    _isListening = true;

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      // Don't specify locale - use device's default language
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    _isListening = false;
    await _speechToText.stop();
  }

  /// Handle speech recognition result
  void _onSpeechResult(SpeechRecognitionResult result) async {
    final spokenText = result.recognizedWords;

    if (spokenText.isEmpty) return;

    // Notify spoken text
    onSpeechResult?.call(spokenText);

    // Only translate final results to avoid flickering
    if (result.finalResult && _translator != null) {
      try {
        final translated = await _translator!.translateText(spokenText);
        onTranslation?.call(translated);
      } catch (e) {
        debugPrint('Translation error: $e');
        onError?.call('Translation failed');
      }
    }
  }

  /// Map BCP-47 code to TranslateLanguage enum
  TranslateLanguage _mapToTranslateLanguage(String code) {
    switch (code.toLowerCase()) {
      case 'en':
        return TranslateLanguage.english;
      case 'es':
        return TranslateLanguage.spanish;
      case 'fr':
        return TranslateLanguage.french;
      case 'de':
        return TranslateLanguage.german;
      case 'it':
        return TranslateLanguage.italian;
      case 'pt':
        return TranslateLanguage.portuguese;
      case 'hi':
        return TranslateLanguage.hindi;
      case 'ja':
        return TranslateLanguage.japanese;
      case 'ko':
        return TranslateLanguage.korean;
      case 'zh':
        return TranslateLanguage.chinese;
      case 'ar':
        return TranslateLanguage.arabic;
      case 'ru':
        return TranslateLanguage.russian;
      default:
        return TranslateLanguage.english;
    }
  }

  /// Clean up resources
  void dispose() {
    _speechToText.stop();
    _translator?.close();
  }
}
