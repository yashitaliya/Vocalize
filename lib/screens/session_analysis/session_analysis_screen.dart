import 'package:flutter/material.dart';
import '../../models/session_data.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/session_widgets.dart';

class SessionAnalysisScreen extends StatelessWidget {
  final SessionData sessionData;

  const SessionAnalysisScreen({Key? key, required this.sessionData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sessionBackground, // Mapped
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Session Analysis',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textPrimary),
            onPressed: () {
              // Handle share action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality coming soon!'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular Score Widget
            Center(
              child: CircularScoreWidget(
                score: sessionData.score,
                isNewHighScore: true,
              ),
            ),
            const SizedBox(height: 32),

            // Session Stats Section
            const Text(
              'Session Stats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SessionStatsCard(
                  icon: Icons.access_time,
                  value: '${sessionData.minutes}',
                  label: 'Minutes',
                  iconColor: AppColors.iconBlue,
                ),
                const SizedBox(width: 12),
                SessionStatsCard(
                  icon: Icons.chat_bubble_outline,
                  value: '${sessionData.exchanges}',
                  label: 'Exchanges',
                  iconColor: AppColors.iconGreen,
                ),
                const SizedBox(width: 12),
                SessionStatsCard(
                  icon: Icons.library_books,
                  value: '${sessionData.newWords}',
                  label: 'New Words',
                  iconColor: AppColors.iconPurple,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Skills Progress Section
            const Text(
              'Your Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: sessionData.skills
                    .map(
                      (skill) => SkillProgressBar(
                        skillName: skill.name,
                        percentage: skill.percentage,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 32),

            // Corrections Timeline Section
            const Text(
              'Corrections Timeline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CorrectionsTimeline(corrections: sessionData.corrections),
            ),
            const SizedBox(height: 32),

            // New Vocabulary Section
            const Text(
              'New Vocabulary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: sessionData.vocabulary.length,
              itemBuilder: (context, index) {
                return VocabularyCard(
                  item: sessionData.vocabulary[index],
                  index: index,
                );
              },
            ),
            const SizedBox(height: 20),

            // Practice with Flashcards Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Handle flashcards navigation
                },
                icon: const Icon(Icons.style),
                label: const Text(
                  'Practice with Flashcards',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sessionNavy, // Mapped
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Rate Instructor Section
            RateInstructorWidget(instructor: sessionData.instructor),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
