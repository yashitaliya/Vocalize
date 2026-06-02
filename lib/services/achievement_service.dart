import 'package:flutter/material.dart';
import 'matchmaking_service.dart';
import 'vocabulary_service.dart';

/// Achievement definition
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final int progress;
  final int target;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
    this.progress = 0,
    this.target = 1,
  });

  double get progressPercent => (progress / target).clamp(0.0, 1.0);
}

/// Service to calculate achievements from real user data
class AchievementService {
  final MatchmakingService _matchmakingService = MatchmakingService();
  final VocabularyService _vocabularyService = VocabularyService();

  /// Get all achievements with real unlock status
  Future<List<Achievement>> getAchievements(String userId) async {
    // Fetch real data
    final matches = await _matchmakingService.getAllMatchesFuture(userId);
    final totalWords = await _vocabularyService.getTotalWordsLearned();

    // Calculate stats
    final totalCalls = matches.length;
    final uniquePartners = _getUniquePartners(matches, userId);
    final dayStreak = _calculateDayStreak(matches);
    final fiveStarRatings = matches.where((m) => m.rating == 5).length;

    return [
      Achievement(
        id: 'first_words',
        title: 'First Words',
        description: 'Complete your first call',
        icon: Icons.mic,
        color: const Color(0xFF10B981),
        isUnlocked: totalCalls >= 1,
        progress: totalCalls.clamp(0, 1),
        target: 1,
      ),
      Achievement(
        id: 'on_fire',
        title: 'On Fire',
        description: '3-day practice streak',
        icon: Icons.local_fire_department,
        color: const Color(0xFFF97316),
        isUnlocked: dayStreak >= 3,
        progress: dayStreak.clamp(0, 3),
        target: 3,
      ),
      Achievement(
        id: 'dedicated',
        title: 'Dedicated',
        description: '7-day practice streak',
        icon: Icons.emoji_events,
        color: const Color(0xFFEAB308),
        isUnlocked: dayStreak >= 7,
        progress: dayStreak.clamp(0, 7),
        target: 7,
      ),
      Achievement(
        id: 'vocab_pro',
        title: 'Vocabulary Pro',
        description: 'Learn 25 new words',
        icon: Icons.menu_book,
        color: const Color(0xFF3B82F6),
        isUnlocked: totalWords >= 25,
        progress: totalWords.clamp(0, 25),
        target: 25,
      ),
      Achievement(
        id: 'scholar',
        title: 'Scholar',
        description: 'Learn 100 new words',
        icon: Icons.school,
        color: const Color(0xFFA855F7),
        isUnlocked: totalWords >= 100,
        progress: totalWords.clamp(0, 100),
        target: 100,
      ),
      Achievement(
        id: 'conversationalist',
        title: 'Conversationalist',
        description: 'Complete 10 calls',
        icon: Icons.chat,
        color: const Color(0xFF06B6D4),
        isUnlocked: totalCalls >= 10,
        progress: totalCalls.clamp(0, 10),
        target: 10,
      ),
      Achievement(
        id: 'explorer',
        title: 'Explorer',
        description: 'Talk to 5 different people',
        icon: Icons.explore,
        color: const Color(0xFF8B5CF6),
        isUnlocked: uniquePartners >= 5,
        progress: uniquePartners.clamp(0, 5),
        target: 5,
      ),
      Achievement(
        id: 'top_rated',
        title: 'Top Rated',
        description: 'Receive 5 five-star ratings',
        icon: Icons.star,
        color: const Color(0xFFEC4899),
        isUnlocked: fiveStarRatings >= 5,
        progress: fiveStarRatings.clamp(0, 5),
        target: 5,
      ),
    ];
  }

  int _getUniquePartners(List<Match> matches, String userId) {
    final partners = <String>{};
    for (var match in matches) {
      final partnerId = match.user1Id == userId ? match.user2Id : match.user1Id;
      partners.add(partnerId);
    }
    return partners.length;
  }

  int _calculateDayStreak(List<Match> matches) {
    if (matches.isEmpty) return 0;

    final daysWithCalls =
        matches
            .map(
              (m) => DateTime(
                m.createdAt.year,
                m.createdAt.month,
                m.createdAt.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (daysWithCalls.isEmpty) return 0;

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final yesterday = today.subtract(const Duration(days: 1));

    if (daysWithCalls.first != today && daysWithCalls.first != yesterday) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < daysWithCalls.length - 1; i++) {
      final diff = daysWithCalls[i].difference(daysWithCalls[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }
}
