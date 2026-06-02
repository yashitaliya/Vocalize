import '../models/session_data.dart';
import '../screens/call/call_summary_screen.dart';

class CallAnalysisService {
  /// Analyzes a completed call session to generate performance metrics
  SessionData analyzeSession({
    required List<ConversationMessage> messages,
    required int durationSeconds,
    required List<VocabularyItem> vocabulary,
    required InstructorInfo instructor,
  }) {
    // 1. Calculate Score (0-100)
    // Base score on duration (up to 30 pts) + Exchanges (up to 30 pts) + Vocab (up to 20 pts) + Quality (up to 20 pts)
    double durationScore =
        (durationSeconds / 300).clamp(0.0, 1.0) * 30; // Max 30 pts for 5 mins
    double exchangeScore =
        (messages.length / 10).clamp(0.0, 1.0) *
        30; // Max 30 pts for 10 exchanges
    double vocabScore =
        (vocabulary.length / 5).clamp(0.0, 1.0) * 20; // Max 20 pts for 5 words

    // Add quality score based on message content (unique per user based on what they heard)
    double qualityScore = 0;
    if (messages.isNotEmpty) {
      // Calculate total characters transcribed (unique per user)
      final totalChars = messages.fold(
        0,
        (sum, msg) => sum + msg.original.length,
      );
      // Messages with translations get bonus points
      final translatedCount = messages
          .where((m) => m.translated.isNotEmpty)
          .length;
      // Quality factors
      qualityScore =
          ((totalChars / 100).clamp(0.0, 1.0) *
              10) + // Up to 10 pts for content length
          ((translatedCount / messages.length) *
              10); // Up to 10 pts for translation coverage
    }

    int totalScore = (durationScore + exchangeScore + vocabScore + qualityScore)
        .round()
        .clamp(10, 100);

    // 2. Calculate Skill Progress (0.0 - 1.0)
    // Heuristics based on message complexity
    double avgWordCount = messages.isEmpty
        ? 0
        : messages.fold(0, (sum, msg) => sum + msg.original.split(' ').length) /
              messages.length;

    // Vocabulary: specific words used + variety
    double vocabProgress =
        ((vocabulary.length * 0.1) + (avgWordCount * 0.05) + 0.4).clamp(
          0.1,
          0.95,
        );

    // Grammar: sentence length as proxy for complexity (longer = better usually)
    double grammarProgress = ((avgWordCount * 0.08) + 0.5).clamp(0.1, 0.92);

    // Pronunciation: Hard to measure from text, give a "good" standard score based on flow
    double pronunciationProgress = 0.85; // Static "Good" for now

    // 3. Generate corrections/timeline from messages (deduplicated)
    List<Correction> corrections = [];
    String? lastOriginal;
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      // Skip duplicates
      if (msg.original == lastOriginal) continue;
      lastOriginal = msg.original;

      // Add each message as a timeline item
      corrections.add(
        Correction(
          speaker: 'Partner',
          originalText: msg.original,
          correctedText: msg.translated.isNotEmpty
              ? msg.translated
              : msg.original,
          explanation: msg.translated.isNotEmpty
              ? 'Translation'
              : 'Transcription',
        ),
      );
    }

    // 4. Create Session Data
    return SessionData(
      score: totalScore,
      minutes: (durationSeconds / 60).ceil(),
      exchanges: messages.length,
      newWords: vocabulary.length,
      skills: [
        SkillProgress(name: 'Vocabulary', percentage: vocabProgress),
        SkillProgress(name: 'Grammar', percentage: grammarProgress),
        SkillProgress(name: 'Pronunciation', percentage: pronunciationProgress),
      ],
      corrections: corrections,
      vocabulary: vocabulary,
      instructor: instructor,
    );
  }
}
