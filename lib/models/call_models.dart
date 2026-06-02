/// Models for the call/matching feature

/// Enum representing the current status during match finding
enum MatchStatus { scanning, foundSpeakers, matchingPreferences, matchFound }

/// Represents a matched speaker for a call
class SpeakerMatch {
  final String id;
  final String name;
  final String language;
  final String languageFlag;
  final String level;
  final String topic;
  final String topicEmoji;
  final String? avatarUrl;

  const SpeakerMatch({
    required this.id,
    required this.name,
    required this.language,
    required this.languageFlag,
    required this.level,
    required this.topic,
    required this.topicEmoji,
    this.avatarUrl,
  });
}

/// Represents a translation message during a call
class TranslationMessage {
  final String speakerName;
  final String originalText;
  final String translatedText;
  final DateTime timestamp;

  const TranslationMessage({
    required this.speakerName,
    required this.originalText,
    required this.translatedText,
    required this.timestamp,
  });
}

/// Represents an active call session
class CallSession {
  final String sessionId;
  final SpeakerMatch partner;
  final DateTime startTime;
  final List<TranslationMessage> messages;

  const CallSession({
    required this.sessionId,
    required this.partner,
    required this.startTime,
    this.messages = const [],
  });

  Duration get duration => DateTime.now().difference(startTime);
}

/// Sample data for testing
SpeakerMatch getSampleMatch() {
  return const SpeakerMatch(
    id: '1',
    name: 'Maria Rodriguez',
    language: 'Spanish',
    languageFlag: '🇪🇸',
    level: 'Intermediate',
    topic: 'Travel & Adventure',
    topicEmoji: '✈️',
  );
}

List<TranslationMessage> getSampleMessages() {
  return [
    TranslationMessage(
      speakerName: 'Maria',
      originalText: 'Tengo veinte años',
      translatedText: 'I am twenty years old',
      timestamp: DateTime.now(),
    ),
  ];
}
