import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/achievement_service.dart';
import 'profile_screen.dart'; // For AchievementGridItem reuse

class AchievementScreen extends StatelessWidget {
  const AchievementScreen({required this.achievements, Key? key})
    : super(key: key);

  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    appBar: _buildAppBar(context),
    body: SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'All Achievements',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have earned ${achievements.where((a) => a.isUnlocked).length} of ${achievements.length} achievements',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Achievements Grid
            GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.9,
              children: achievements
                  .map(
                    (achievement) =>
                        AchievementGridItem(achievement: achievement),
                  )
                  .toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );

  PreferredSizeWidget _buildAppBar(BuildContext context) => AppBar(
    backgroundColor: AppTheme.white,
    elevation: 0,
    leading: InkWell(
      onTap: () => Navigator.pop(context),
      child: const Icon(
        Icons.arrow_back_ios,
        color: AppTheme.textPrimary,
        size: 20,
      ),
    ),
    title: Text(
      'Achievements',
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    ),
    centerTitle: true,
  );
}
