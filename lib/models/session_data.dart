class SessionData {
  final int score;
  final int minutes;
  final int exchanges;
  final int newWords;
  final List<SkillProgress> skills;
  final List<Correction> corrections;
  final List<VocabularyItem> vocabulary;
  final InstructorInfo instructor;

  SessionData({
    required this.score,
    required this.minutes,
    required this.exchanges,
    required this.newWords,
    required this.skills,
    required this.corrections,
    required this.vocabulary,
    required this.instructor,
  });

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'minutes': minutes,
      'exchanges': exchanges,
      'newWords': newWords,
      'skills': skills.map((x) => x.toMap()).toList(),
      'corrections': corrections.map((x) => x.toMap()).toList(),
      'vocabulary': vocabulary.map((x) => x.toMap()).toList(),
      'instructor': instructor.toMap(),
    };
  }

  factory SessionData.fromMap(Map<String, dynamic> map) {
    return SessionData(
      score: map['score']?.toInt() ?? 0,
      minutes: map['minutes']?.toInt() ?? 0,
      exchanges: map['exchanges']?.toInt() ?? 0,
      newWords: map['newWords']?.toInt() ?? 0,
      skills: List<SkillProgress>.from(
        (map['skills'] ?? []).map((x) => SkillProgress.fromMap(x)),
      ),
      corrections: List<Correction>.from(
        (map['corrections'] ?? []).map((x) => Correction.fromMap(x)),
      ),
      vocabulary: List<VocabularyItem>.from(
        (map['vocabulary'] ?? []).map((x) => VocabularyItem.fromMap(x)),
      ),
      instructor: InstructorInfo.fromMap(map['instructor'] ?? {}),
    );
  }
}

class SkillProgress {
  final String name;
  final double percentage;

  SkillProgress({required this.name, required this.percentage});

  Map<String, dynamic> toMap() {
    return {'name': name, 'percentage': percentage};
  }

  factory SkillProgress.fromMap(Map<String, dynamic> map) {
    return SkillProgress(
      name: map['name'] ?? '',
      percentage: map['percentage']?.toDouble() ?? 0.0,
    );
  }
}

class Correction {
  final String speaker;
  final String originalText;
  final String correctedText;
  final String explanation;

  Correction({
    required this.speaker,
    required this.originalText,
    required this.correctedText,
    required this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'speaker': speaker,
      'originalText': originalText,
      'correctedText': correctedText,
      'explanation': explanation,
    };
  }

  factory Correction.fromMap(Map<String, dynamic> map) {
    return Correction(
      speaker: map['speaker'] ?? '',
      originalText: map['originalText'] ?? '',
      correctedText: map['correctedText'] ?? '',
      explanation: map['explanation'] ?? '',
    );
  }
}

class VocabularyItem {
  final String word;
  final String translation;

  VocabularyItem({required this.word, required this.translation});

  Map<String, dynamic> toMap() {
    return {'word': word, 'translation': translation};
  }

  factory VocabularyItem.fromMap(Map<String, dynamic> map) {
    return VocabularyItem(
      word: map['word'] ?? '',
      translation: map['translation'] ?? '',
    );
  }
}

class InstructorInfo {
  final String name;
  final String imageUrl;

  InstructorInfo({required this.name, required this.imageUrl});

  Map<String, dynamic> toMap() {
    return {'name': name, 'imageUrl': imageUrl};
  }

  factory InstructorInfo.fromMap(Map<String, dynamic> map) {
    return InstructorInfo(
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}

// Sample data for demonstration
SessionData getSampleSessionData() {
  return SessionData(
    score: 72,
    minutes: 28,
    exchanges: 45,
    newWords: 8,
    skills: [
      SkillProgress(name: 'Vocabulary', percentage: 0.72),
      SkillProgress(name: 'Grammar', percentage: 0.68),
      SkillProgress(name: 'Pronunciation', percentage: 0.76),
    ],
    corrections: [
      Correction(
        speaker: 'You said:',
        originalText: '¿Me gustaría viajar allá?',
        correctedText: 'Me gustaría viajar allá.',
        explanation: 'Statements don\'t need question marks',
      ),
      Correction(
        speaker: 'You said:',
        originalText: '¿Más grande viaje?',
        correctedText: 'Me encanta viajar',
        explanation: 'A feminine noun needs an strong form',
      ),
      Correction(
        speaker: 'You said:',
        originalText: '¿Cuál es tu película favorita?',
        correctedText: '¿Cuál es tu película favorita?',
        explanation: 'Correct! No correction needed',
      ),
      Correction(
        speaker: 'You said:',
        originalText: '¿Estoy de acuerdo contigo?',
        correctedText: 'Estoy de acuerdo contigo',
        explanation: 'Statements don\'t need question marks',
      ),
    ],
    vocabulary: [
      VocabularyItem(word: 'aeropuerto', translation: 'airport'),
      VocabularyItem(word: 'boleto', translation: 'ticket'),
      VocabularyItem(word: 'viaje', translation: 'trip'),
      VocabularyItem(word: 'equipaje', translation: 'luggage'),
      VocabularyItem(word: 'maleta', translation: 'suitcase'),
    ],
    instructor: InstructorInfo(
      name: 'Isela Maria',
      imageUrl: 'https://via.placeholder.com/50',
    ),
  );
}
