/// Model for a user's test result
class TestResultModel {
  final String resultId;
  final String userId;
  final String testId;
  final int score;
  final int totalQuestions;
  final Map<int, int> userAnswers; // questionIndex -> selectedOptionIndex
  final DateTime completedAt;

  const TestResultModel({
    required this.resultId,
    required this.userId,
    required this.testId,
    required this.score,
    required this.totalQuestions,
    required this.userAnswers,
    required this.completedAt,
  });

  double get percentage => (score / totalQuestions) * 100;

  Map<String, dynamic> toMap() {
    return {
      'resultId': resultId,
      'userId': userId,
      'testId': testId,
      'score': score,
      'totalQuestions': totalQuestions,
      'userAnswers': userAnswers.map((k, v) => MapEntry(k.toString(), v)),
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory TestResultModel.fromMap(Map<String, dynamic> map) {
    final answersMap = map['userAnswers'] as Map<String, dynamic>? ?? {};
    return TestResultModel(
      resultId: map['resultId'] ?? '',
      userId: map['userId'] ?? '',
      testId: map['testId'] ?? '',
      score: map['score'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      userAnswers: answersMap.map((k, v) => MapEntry(int.parse(k), v as int)),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : DateTime.now(),
    );
  }
}
