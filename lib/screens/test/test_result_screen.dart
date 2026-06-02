import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/test_model.dart';
import '../../models/test_result_model.dart';

import 'dart:math' as math;

class TestResultScreen extends StatelessWidget {
  final TestModel test;
  final TestResultModel result;

  const TestResultScreen({Key? key, required this.test, required this.result})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildScoreCard(),
            const SizedBox(height: 24),

            _buildReviewSection(),
            const SizedBox(height: 32),
            _buildBackButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppTheme.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Test Results',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildScoreCard() {
    final percentage = result.percentage;
    final color = _getScoreColor(percentage);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildScoreCircle(percentage, color),
          const SizedBox(height: 24),
          Text(
            _getScoreMessage(percentage),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You scored ${result.score} out of ${result.totalQuestions}',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.white.withValues(alpha: 0.9),
            ),
          ),
          if (percentage < 80) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Score 80% or higher to unlock the next level',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.white,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreCircle(double percentage, Color color) {
    return SizedBox(
      width: 120,
      height: 120,
      child: CustomPaint(
        painter: _CircleProgressPainter(
          percentage: percentage,
          backgroundColor: AppTheme.white.withValues(alpha: 0.3),
          foregroundColor: AppTheme.white,
        ),
        child: Center(
          child: Text(
            '${percentage.toStringAsFixed(0)}%',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Answers',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          test.questions.length,
          (index) => _buildQuestionReview(index),
        ),
      ],
    );
  }

  Widget _buildQuestionReview(int index) {
    final question = test.questions[index];
    final userAnswerIndex = result.userAnswers[index];
    final isCorrect = userAnswerIndex == question.correctAnswerIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCorrect
              ? AppTheme.achievementGreen.withValues(alpha: 0.3)
              : AppTheme.achievementRed.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppTheme.achievementGreen.withValues(alpha: 0.1)
                      : AppTheme.achievementRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: isCorrect
                          ? AppTheme.achievementGreen
                          : AppTheme.achievementRed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCorrect ? 'Correct' : 'Incorrect',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isCorrect
                            ? AppTheme.achievementGreen
                            : AppTheme.achievementRed,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Q${index + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.questionText,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            question.options.length,
            (optionIndex) => _buildOptionReview(
              question.options[optionIndex],
              optionIndex,
              userAnswerIndex,
              question.correctAnswerIndex,
            ),
          ),
          if (question.explanation != null && !isCorrect) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explanation!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionReview(
    String option,
    int optionIndex,
    int? userAnswerIndex,
    int correctAnswerIndex,
  ) {
    final isUserAnswer = optionIndex == userAnswerIndex;
    final isCorrectAnswer = optionIndex == correctAnswerIndex;

    Color? backgroundColor;
    Color? borderColor;
    Color? textColor;
    IconData? icon;

    if (isCorrectAnswer) {
      backgroundColor = AppTheme.achievementGreen.withValues(alpha: 0.1);
      borderColor = AppTheme.achievementGreen;
      textColor = AppTheme.achievementGreen;
      icon = Icons.check_circle;
    } else if (isUserAnswer && !isCorrectAnswer) {
      backgroundColor = AppTheme.achievementRed.withValues(alpha: 0.1);
      borderColor = AppTheme.achievementRed;
      textColor = AppTheme.achievementRed;
      icon = Icons.cancel;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? AppTheme.divider,
          width: borderColor != null ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 20, color: textColor),
          if (icon != null) const SizedBox(width: 12),
          Expanded(
            child: Text(
              option,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: textColor ?? AppTheme.textPrimary,
                fontWeight: (isUserAnswer || isCorrectAnswer)
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          'Back to Tests',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.white,
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return AppTheme.achievementGreen;
    if (percentage >= 60) return AppTheme.achievementGold;
    return AppTheme.achievementRed;
  }

  String _getScoreMessage(double percentage) {
    if (percentage >= 90) return 'Excellent! 🎉';
    if (percentage >= 80) return 'Great Job! 👏';
    if (percentage >= 70) return 'Good Work! 👍';
    if (percentage >= 60) return 'Not Bad! 💪';
    return 'Keep Practicing! 📚';
  }
}

class _CircleProgressPainter extends CustomPainter {
  final double percentage;
  final Color backgroundColor;
  final Color foregroundColor;

  _CircleProgressPainter({
    required this.percentage,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 8.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    // Foreground arc
    final foregroundPaint = Paint()
      ..color = foregroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * (percentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2,
      sweepAngle,
      false,
      foregroundPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
