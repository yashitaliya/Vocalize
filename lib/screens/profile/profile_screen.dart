import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../settings/settings_screen.dart';
import 'achievement_screen.dart';
import '../../models/profile_models.dart' hide Achievement;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/vocabulary_service.dart';
import '../../services/matchmaking_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/achievement_service.dart';

// ============================================================================
// WIDGETS
// ============================================================================

class ProfileHeader extends StatefulWidget {
  const ProfileHeader({
    required this.user,
    required this.onAvatarUpdated,
    Key? key,
  }) : super(key: key);

  final UserProfile user;
  final VoidCallback onAvatarUpdated;

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final file = File(image.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${widget.user.uid}.jpg');

      // Upload file
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore
      await FirestoreService().updateProfile(
        uid: widget.user.uid,
        avatarUrl: downloadUrl,
      );

      // Trigger redraw
      widget.onAvatarUpdated();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.length > 0 ? parts.first[0].toUpperCase() : '';
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Widget _buildAvatarContent() {
    final initials = _getInitials(widget.user.displayName);
    final fallback = Container(
      color: AppTheme.primary.withOpacity(0.1),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: AppTheme.primary,
        ),
      ),
    );

    if (widget.user.avatarUrl.isEmpty) {
      return fallback;
    }

    if (widget.user.avatarUrl.startsWith('http')) {
      return Image.network(
        widget.user.avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return Image.asset(
      widget.user.avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          children: [
            // Avatar with Edit Button Overlay
            GestureDetector(
              onTap: _isUploading ? null : _pickAndUploadImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withOpacity(0.1),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(child: _buildAvatarContent()),
                  ),
                  if (_isUploading)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  if (!_isUploading)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Username
            Text(
              widget.user.displayName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle
            Text(
              '@${widget.user.username} • Member since ${widget.user.memberSince}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
}

class StatCard extends StatelessWidget {
  const StatCard({
    required this.value,
    required this.label,
    Key? key,
    this.cardColor,
  }) : super(key: key);

  final int value;
  final String label;
  final Color? cardColor;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor ?? AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class LanguageProgressRow extends StatelessWidget {
  const LanguageProgressRow({required this.language, Key? key})
    : super(key: key);

  final Language language;

  Color _getProgressColor(String level) {
    switch (level) {
      case 'Spanish':
        return AppTheme.spanishProgress;
      case 'French':
        return AppTheme.frenchProgress;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(language.flagEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            language.level,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: language.progress,
                minHeight: 6,
                backgroundColor: AppTheme.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(language.name),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${language.progressPercentage}%',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ],
  );
}

class AchievementGridItem extends StatelessWidget {
  const AchievementGridItem({required this.achievement, Key? key})
    : super(key: key);

  final Achievement achievement;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: achievement.isUnlocked
                ? achievement.color
                : Colors.grey.shade300,
            shape: BoxShape.circle,
            boxShadow: [
              if (achievement.isUnlocked)
                BoxShadow(
                  color: achievement.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: Icon(
              achievement.icon,
              size: 28,
              color: achievement.isUnlocked
                  ? Colors.white
                  : Colors.grey.shade500,
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        achievement.title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: achievement.isUnlocked
              ? AppTheme.textSecondary
              : AppTheme.textTertiary,
        ),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      if (!achievement.isUnlocked)
        Text(
          '${achievement.progress}/${achievement.target}',
          style: GoogleFonts.inter(fontSize: 9, color: AppTheme.textTertiary),
        ),
    ],
  );
}

// ============================================================================
// MAIN SCREEN
// ============================================================================

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final VocabularyService _vocabularyService = VocabularyService();
  final MatchmakingService _matchmakingService = MatchmakingService();

  @override
  void initState() {
    super.initState();
  }

  Stream<List<Language>> _getFluencyStream(String userId) {
    return _firestoreService.getUserTestResultsStream(userId).asyncMap((
      results,
    ) async {
      // Group by language
      final Map<String, Set<int>> passedLevelsByLanguage = {};

      for (var result in results) {
        // testId format example: test_spanish_1
        final parts = result.testId.split('_');
        if (parts.length >= 3) {
          final language = parts[1]; // spanish
          final level = int.tryParse(parts[2]) ?? 0;

          // Capitalize language name
          final langName = language[0].toUpperCase() + language.substring(1);

          if (result.percentage >= 80) {
            if (!passedLevelsByLanguage.containsKey(langName)) {
              passedLevelsByLanguage[langName] = {};
            }
            passedLevelsByLanguage[langName]!.add(level);
          }
        }
      }

      // Create Language objects
      // If no data, show selected language with 0 progress
      final user = await _firestoreService.getUser(userId);
      final selectedLang = user?.selectedLanguage ?? 'Spanish';

      if (passedLevelsByLanguage.isEmpty) {
        return [
          Language(
            name: selectedLang,
            flagEmoji: _getFlagEmoji(selectedLang),
            level: 'Beginner',
            progress: 0.0,
            progressPercentage: 0,
          ),
        ];
      }

      // Sort and convert to list
      return passedLevelsByLanguage.entries.map((entry) {
        final langName = entry.key;
        final passedCount = entry.value.length;
        final progress = passedCount / 10.0; // Assuming 10 levels

        String levelLabel = 'Beginner';
        if (passedCount >= 8)
          levelLabel = 'Expert';
        else if (passedCount >= 4)
          levelLabel = 'Intermediate';

        return Language(
          name: langName,
          flagEmoji: _getFlagEmoji(langName),
          level: levelLabel,
          progress: progress.clamp(0.0, 1.0),
          progressPercentage: (progress * 100).toInt().clamp(0, 100),
        );
      }).toList();
    });
  }

  String _getFlagEmoji(String language) {
    switch (language.toLowerCase()) {
      case 'spanish':
        return '🇪🇸';
      case 'french':
        return '🇫🇷';
      case 'german':
        return '🇩🇪';
      case 'italian':
        return '🇮🇹';
      case 'portuguese':
        return '🇵🇹';
      case 'mandarin':
        return '🇨🇳';
      case 'japanese':
        return '🇯🇵';
      case 'korean':
        return '🇰🇷';
      case 'russian':
        return '🇷🇺';
      case 'arabic':
        return '🇸🇦';
      case 'hindi':
        return '🇮🇳';
      case 'english':
        return '🇺🇸';
      default:
        return '🏳️';
    }
  }

  final AchievementService _achievementService = AchievementService();

  String _formatDate(DateTime date) {
    // Simple formatter: Jan 2024
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Calculate consecutive days with at least one call
  int _calculateDayStreak(List<Match> matches) {
    if (matches.isEmpty) return 0;

    // Get unique days with calls (dates only, no time)
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
          ..sort(
            (a, b) => b.compareTo(a),
          ); // Sort descending (most recent first)

    if (daysWithCalls.isEmpty) return 0;

    // Check if today or yesterday has a call (streak needs to be current)
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final yesterday = today.subtract(const Duration(days: 1));

    if (daysWithCalls.first != today && daysWithCalls.first != yesterday) {
      return 0; // Streak broken
    }

    // Count consecutive days
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: StreamBuilder<User?>(
        stream: _authService.authStateChanges,
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentUser = authSnapshot.data;
          if (currentUser == null) {
            return const Center(child: Text('Please log in'));
          }

          return StreamBuilder<UserModel?>(
            stream: _firestoreService.getUserStream(currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Use fetched data or fallback to User object or hardcoded defaults
              final userData = snapshot.data;

              return StreamBuilder<int>(
                stream: _vocabularyService.getTotalWordsLearnedStream(),
                builder: (context, vocabSnapshot) {
                  final totalWords = vocabSnapshot.data ?? 0;

                  return StreamBuilder<List<Match>>(
                    stream: _matchmakingService.getAllMatchesStream(
                      currentUser.uid,
                    ),
                    builder: (context, matchSnapshot) {
                      final matches = matchSnapshot.data ?? [];
                      final sessionCount = matches.length;
                      final dayStreak = _calculateDayStreak(matches);

                      final userProfile = UserProfile(
                        uid: currentUser.uid,
                        username:
                            userData?.fullName.split(' ').first.toLowerCase() ??
                            'user',
                        displayName:
                            userData?.fullName ??
                            currentUser.displayName ??
                            'User',
                        email: userData?.email ?? currentUser.email ?? '',
                        avatarUrl:
                            userData?.avatarUrl ??
                            currentUser.photoURL ??
                            'assets/images/avatar.png',
                        memberSince: userData != null
                            ? _formatDate(userData.createdAt)
                            : _formatDate(
                                currentUser.metadata.creationTime ??
                                    DateTime.now(),
                              ),
                        isPro: false,
                        sessions: sessionCount,
                        dayStreak: dayStreak,
                        totalWords: totalWords,
                      );

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Header
                            ProfileHeader(
                              user: userProfile,
                              onAvatarUpdated: () {
                                // Avatar updates via Firebase Storage -> Firestore,
                                // the user stream will automatically rebuild this view
                              },
                            ),
                            const SizedBox(height: 32),

                            // Stats Cards
                            Row(
                              children: [
                                StatCard(
                                  value: userProfile.sessions,
                                  label: 'Sessions',
                                ),
                                const SizedBox(width: 12),
                                StatCard(
                                  value: userProfile.dayStreak,
                                  label: 'Day Streak',
                                ),
                                const SizedBox(width: 12),
                                StatCard(
                                  value: userProfile.totalWords,
                                  label: 'Words',
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Fluency Progress Section
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppTheme.shadowColor,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Fluency Progress',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  StreamBuilder<List<Language>>(
                                    stream: _getFluencyStream(currentUser.uid),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(16.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }

                                      if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      }

                                      final languages = snapshot.data ?? [];
                                      if (languages.isEmpty) {
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Start taking tests to see your progress!',
                                            style: GoogleFonts.inter(
                                              color: AppTheme.textSecondary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }

                                      return Column(
                                        children: languages.map((lang) {
                                          return LanguageProgressRow(
                                            language: lang,
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Achievement Showcase Section
                            Text(
                              'Achievement Showcase',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FutureBuilder<List<Achievement>>(
                              future: _achievementService.getAchievements(
                                currentUser.uid,
                              ),
                              builder: (context, achieveSnapshot) {
                                final achievements = achieveSnapshot.data ?? [];
                                return Column(
                                  children: [
                                    GridView.count(
                                      crossAxisCount: 4,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      childAspectRatio: 0.75,
                                      children: achievements
                                          .take(4)
                                          .map(
                                            (achievement) =>
                                                AchievementGridItem(
                                                  achievement: achievement,
                                                ),
                                          )
                                          .toList(),
                                    ),
                                    const SizedBox(height: 16),
                                    // All Achievement Button
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AchievementScreen(
                                                    achievements: achievements,
                                                  ),
                                            ),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          side: const BorderSide(
                                            color: AppTheme.primary,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          'All Achievements',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'Profile',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
          child: const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.settings_outlined,
              color: AppTheme.textPrimary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}
