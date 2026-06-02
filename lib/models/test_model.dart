/// Model for a test question
class QuestionModel {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String? explanation;

  const QuestionModel({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      explanation: map['explanation'],
    );
  }
}

/// Model for a language test
class TestModel {
  final String testId;
  final String language;
  final int level;
  final String title;
  final String description;
  final List<QuestionModel> questions;
  final DateTime createdAt;

  const TestModel({
    required this.testId,
    required this.language,
    required this.level,
    required this.title,
    required this.description,
    required this.questions,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'testId': testId,
      'language': language,
      'level': level,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TestModel.fromMap(Map<String, dynamic> map) {
    return TestModel(
      testId: map['testId'] ?? '',
      language: map['language'] ?? '',
      level: map['level'] ?? 1,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      questions:
          (map['questions'] as List<dynamic>?)
              ?.map((q) => QuestionModel.fromMap(q as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
