// ============================================================================
// MODELS
// ============================================================================

class UserProfile {
  UserProfile({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.memberSince,
    this.isPro = false,
    this.sessions = 47,
    this.dayStreak = 7,
    this.totalWords = 324,
  });
  final String uid;
  final String username;
  final String displayName;
  final String email;
  final String avatarUrl;
  final String memberSince;
  final bool isPro;
  final int sessions;
  final int dayStreak;
  final int totalWords;
}

class Language {
  Language({
    required this.name,
    required this.flagEmoji,
    required this.level,
    required this.progress,
    required this.progressPercentage,
  });
  final String name;
  final String flagEmoji;
  final String level;
  final double progress; // 0.0 to 1.0
  final int progressPercentage;
}

class Achievement {
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
    this.progress = 0,
    this.target = 1,
  });
  final String id;
  final String title;
  final String description;
  final int icon; // IconData codePoint
  final int color;
  final bool isUnlocked;
  final int progress;
  final int target;

  double get progressPercent => (progress / target).clamp(0.0, 1.0);
}
