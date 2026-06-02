import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../models/test_model.dart';
import '../../models/test_result_model.dart';
import '../../services/auth_service.dart';
import '../../services/test_service.dart';
import 'test_result_screen.dart';

class TestTakingScreen extends StatefulWidget {
  final TestModel test;

  const TestTakingScreen({Key? key, required this.test}) : super(key: key);

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen> {
  final AuthService _authService = AuthService();
  final TestService _testService = TestService();

  int _currentQuestionIndex = 0;
  final Map<int, int> _userAnswers = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final question = widget.test.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / widget.test.questions.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _onBackPressed();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildProgressBar(progress),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuestionNumber(),
                    const SizedBox(height: 16),
                    _buildQuestionText(question.questionText),
                    const SizedBox(height: 32),
                    _buildOptions(question),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppTheme.textPrimary),
        onPressed: () => _onBackPressed(),
      ),
      title: Text(
        widget.test.title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 4,
      color: AppTheme.divider,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.secondary],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionNumber() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Question ${_currentQuestionIndex + 1} of ${widget.test.questions.length}',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  Widget _buildQuestionText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
        height: 1.4,
      ),
    );
  }

  Widget _buildOptions(QuestionModel question) {
    return Column(
      children: List.generate(
        question.options.length,
        (index) => _buildOptionCard(index, question.options[index]),
      ),
    );
  }

  Widget _buildOptionCard(int index, String option) {
    final isSelected = _userAnswers[_currentQuestionIndex] == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _userAnswers[_currentQuestionIndex] = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.1)
              : AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.primary : AppTheme.textTertiary,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: AppTheme.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isLastQuestion =
        _currentQuestionIndex == widget.test.questions.length - 1;
    final hasAnswered = _userAnswers.containsKey(_currentQuestionIndex);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentQuestionIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentQuestionIndex--);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: AppTheme.primary),
                ),
                child: Text(
                  'Previous',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          if (_currentQuestionIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: hasAnswered
                  ? (isLastQuestion ? _submitTest : _nextQuestion)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                disabledBackgroundColor: AppTheme.textTertiary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.white,
                        ),
                      ),
                    )
                  : Text(
                      isLastQuestion ? 'Submit Test' : 'Next',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.test.questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    }
  }

  Future<void> _submitTest() async {
    // Check if all questions are answered
    if (_userAnswers.length != widget.test.questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before submitting'),
          backgroundColor: AppTheme.achievementRed,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Submit Test?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to submit your answers? You cannot change them after submission.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Review',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Submit',
              style: GoogleFonts.inter(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );

    if (shouldSubmit != true) return;

    try {
      // Calculate score
      int score = 0;
      for (int i = 0; i < widget.test.questions.length; i++) {
        if (_userAnswers[i] == widget.test.questions[i].correctAnswerIndex) {
          score++;
        }
      }

      // Create result
      final user = _authService.currentUser;
      final result = TestResultModel(
        resultId: const Uuid().v4(),
        userId: user!.uid,
        testId: widget.test.testId,
        score: score,
        totalQuestions: widget.test.questions.length,
        userAnswers: _userAnswers,
        completedAt: DateTime.now(),
      );

      // Save to Firestore optimistically in background
      _testService.submitTestResult(result).catchError((e) {
        debugPrint('Failed to submit test result in background: $e');
      });

      if (mounted) {
        // Navigate to result screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TestResultScreen(test: widget.test, result: result),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process test submission: $e'),
            backgroundColor: AppTheme.achievementRed,
          ),
        );
      }
    }
  }

  Future<bool> _onBackPressed() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Exit Test?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Your progress will be lost if you exit now.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Continue Test',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Exit',
              style: GoogleFonts.inter(color: AppTheme.achievementRed),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      Navigator.pop(context);
      return true;
    }
    return false;
  }
}
