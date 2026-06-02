import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/matchmaking_service.dart';
import '../../services/firestore_service.dart';
import '../../services/vocabulary_service.dart';
import '../../services/schedule_service.dart';
import '../../models/call_models.dart';
import '../../models/user_model.dart';
import '../../models/schedule_models.dart';
import '../call/finding_match_screen.dart';
import '../schedule/schedule_screen.dart';
import '../call/call_summary_screen.dart';
import '../flashcards/flashcards_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MatchmakingService _matchmakingService = MatchmakingService();
  final AuthService _authService = AuthService();
  final VocabularyService _vocabularyService = VocabularyService();
  final FirestoreService _firestoreService = FirestoreService();
  final ScheduleService _scheduleService = ScheduleService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final userName = user?.displayName ?? 'User';
    final firstName = userName.split(' ').first;

    // Get greeting based on time of day
    String greeting = _getGreeting();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: StreamBuilder<List<Match>>(
              stream: _matchmakingService.getAllMatchesStream(user?.uid ?? ''),
              builder: (context, snapshot) {
                final matches = snapshot.data ?? [];
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting;

                // Filter for today's matches only
                final now = DateTime.now();
                final startOfToday = DateTime(now.year, now.month, now.day);
                final todayMatches = matches
                    .where(
                      (m) =>
                          m.createdAt.isAfter(startOfToday) ||
                          m.createdAt.isAtSameMomentAs(startOfToday),
                    )
                    .toList();

                // Calculate today's stats
                final todayMinutes = todayMatches.fold<int>(
                  0,
                  (sum, match) => sum + match.durationMinutes,
                );
                final recentMatches = matches
                    .take(5)
                    .toList(); // Show top 5 recent

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Real-Time User Name and Notification Icon
                    StreamBuilder<UserModel?>(
                      stream: _firestoreService.getUserStream(user?.uid ?? ''),
                      builder: (context, userSnapshot) {
                        final currentName =
                            userSnapshot.data?.fullName ?? firstName;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$greeting,',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  currentName,
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ready to practice today?',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            // Notification Icon with Badge
                            StreamBuilder<List<ScheduledSession>>(
                              stream: _scheduleService.getPendingRequests(
                                user?.uid ?? '',
                              ),
                              builder: (context, requestSnapshot) {
                                final pendingCount =
                                    requestSnapshot.data?.length ?? 0;
                                return Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.08,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.notifications_outlined,
                                          color: AppColors.textPrimary,
                                          size: 26,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const ScheduleScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    if (pendingCount > 0)
                                      Positioned(
                                        right: 6,
                                        top: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
                                          child: Text(
                                            pendingCount > 9
                                                ? '9+'
                                                : '$pendingCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Quick Match Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28.0),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready to speak?',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Match with a native speaker now',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: SizedBox(
                              width: 180,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const FindingMatchScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.chat_bubble_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                label: const Text(
                                  'Quick Match',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Today's Progress Header
                    Text(
                      "Today's Progress",
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Practice Time Card
                    _buildPracticeTimeCard(todayMinutes),
                    const SizedBox(height: 16),

                    // Stat Cards (Real-time vocab stream)
                    StreamBuilder<int>(
                      stream: _vocabularyService.getWordsLearnedTodayStream(),
                      builder: (context, snapshot) {
                        final wordsLearned = snapshot.data ?? 0;
                        return Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.chat_bubble,
                                iconColor: Colors.orange,
                                count: todayMatches.length.toString(),
                                label: 'Conversations',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                icon: Icons.book,
                                iconColor: Colors.green,
                                count: wordsLearned.toString(),
                                label: 'Words Learned',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Quick Actions Section
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.calendar_today,
                            iconColor: Colors.purple,
                            title: 'Schedule Call',
                            subtitle: 'Book a session',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ScheduleScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.style,
                            iconColor: Colors.blue,
                            title: 'Flashcards',
                            subtitle: 'Practice vocab',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const FlashcardsHubScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Recent Sessions Section
                    Text(
                      'Recent Sessions',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (recentMatches.isEmpty && !isLoading)
                      _buildEmptyState(
                        'No calls yet.\nTap Quick Match to start!',
                      )
                    else
                      for (var match in recentMatches) ...[
                        Builder(
                          builder: (context) {
                            final partnerName = match.getPartnerName(
                              user?.uid ?? '',
                            );
                            final partnerAvatar = match.getPartnerAvatar(
                              user?.uid ?? '',
                            );
                            final color =
                                Colors.primaries[partnerName.hashCode %
                                    Colors.primaries.length];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildRecentSessionCard(
                                name: partnerName,
                                sessionType: 'Speaking Practice',
                                duration: match.formattedDuration,
                                rating: match.rating ?? 0,
                                timeAgo: _getTimeAgo(match.createdAt),
                                avatarColor: color,
                                avatarUrl: partnerAvatar,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CallSummaryScreen(
                                        partner: SpeakerMatch(
                                          id: match.user1Id == user?.uid
                                              ? match.user2Id
                                              : match.user1Id,
                                          name: partnerName,
                                          language: 'General',
                                          level: 'Intermediate',
                                          topic: 'Conversation',
                                          avatarUrl: partnerAvatar.isNotEmpty
                                              ? partnerAvatar
                                              : null,
                                          languageFlag: '🌐',
                                          topicEmoji: '💬',
                                        ),
                                        matchId: match.matchId,
                                        channelName: match.channelName,
                                        durationSeconds: match.durationSeconds,
                                        messages: const [],
                                        isReadOnly: true,
                                        initialRating: match.rating,
                                        initialFeedback: match.feedback,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Methods ---

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 0) return '${diff.inDays} days ago';
    if (diff.inHours > 0) return '${diff.inHours} hours ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} mins ago';
    return 'Just now';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildPracticeTimeCard(int totalMinutes) {
    // Cap at goal for progress bar
    const dailyGoal = 30;
    final progress = (totalMinutes / dailyGoal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Icon(
                  Icons.access_time_filled,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Practice Time',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Daily goal: $dailyGoal min',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    totalMinutes.toString(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  Text(
                    'minutes',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 8,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String count,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            count,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required MaterialColor iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [iconColor.shade400, iconColor.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSessionCard({
    required String name,
    required String sessionType,
    required String duration,
    required int rating,
    required String timeAgo,
    required Color avatarColor,
    String? avatarUrl,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.person, color: avatarColor, size: 24),
                      ),
                    )
                  : Icon(Icons.person, color: avatarColor, size: 24),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            duration,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      if (rating > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            rating > 5 ? 5 : rating,
                            (_) => const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Connect button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.call, color: AppColors.primary, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
