class GamificationProfile {
  const GamificationProfile({
    required this.studentId,
    this.studentName,
    required this.totalXp,
    required this.level,
    required this.xpInLevel,
    required this.xpToNextLevel,
    required this.levelCap,
    required this.currentStreak,
    required this.longestStreak,
    required this.moduleXp,
    this.rank,
    this.enabled = true,
  });

  final String studentId;
  final String? studentName;
  final int totalXp;
  final int level;
  final int xpInLevel;
  final int xpToNextLevel;
  final int levelCap;
  final int currentStreak;
  final int longestStreak;
  final ModuleXp moduleXp;
  final int? rank;
  final bool enabled;

  double get levelProgress => levelCap > 0 ? xpInLevel / levelCap : 0;

  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    return GamificationProfile(
      studentId: (json['studentId'] ?? '').toString(),
      studentName: json['studentName'] as String?,
      totalXp: json['totalXp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      xpInLevel: json['xpInLevel'] as int? ?? 0,
      xpToNextLevel: json['xpToNextLevel'] as int? ?? 300,
      levelCap: json['levelCap'] as int? ?? 300,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      moduleXp: ModuleXp.fromJson(json['moduleXp'] as Map<String, dynamic>? ?? {}),
      rank: json['rank'] as int?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class ModuleXp {
  const ModuleXp({
    required this.words,
    required this.sentences,
    required this.listening,
    required this.video,
  });

  final int words;
  final int sentences;
  final int listening;
  final int video;

  factory ModuleXp.fromJson(Map<String, dynamic> json) {
    return ModuleXp(
      words: json['words'] as int? ?? 0,
      sentences: json['sentences'] as int? ?? 0,
      listening: json['listening'] as int? ?? 0,
      video: json['video'] as int? ?? 0,
    );
  }
}

class AchievementEntry {
  const AchievementEntry({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.xpReward,
    required this.unlocked,
    this.unlockedAt,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final String icon;
  final String category;
  final int xpReward;
  final bool unlocked;
  final DateTime? unlockedAt;

  factory AchievementEntry.fromJson(Map<String, dynamic> json) {
    return AchievementEntry(
      id: json['id'] as String,
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? 'emoji_events',
      category: json['category'] as String? ?? 'milestone',
      xpReward: json['xpReward'] as int? ?? 0,
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null ? DateTime.tryParse(json['unlockedAt'].toString()) : null,
    );
  }
}

class XpLeaderboardEntry {
  const XpLeaderboardEntry({
    required this.rank,
    required this.studentId,
    required this.name,
    required this.totalXp,
    required this.level,
    required this.currentStreak,
    this.studentCode,
  });

  final int rank;
  final String studentId;
  final String name;
  final int totalXp;
  final int level;
  final int currentStreak;
  final String? studentCode;

  factory XpLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return XpLeaderboardEntry(
      rank: json['rank'] as int? ?? 0,
      studentId: (json['studentId'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      totalXp: json['totalXp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentStreak: json['currentStreak'] as int? ?? 0,
      studentCode: json['studentCode'] as String?,
    );
  }
}

class PracticeRecommendation {
  const PracticeRecommendation({
    required this.recommendedModule,
    required this.title,
    required this.reason,
    required this.moduleXp,
  });

  final String recommendedModule;
  final String title;
  final String reason;
  final ModuleXp moduleXp;

  factory PracticeRecommendation.fromJson(Map<String, dynamic> json) {
    return PracticeRecommendation(
      recommendedModule: json['recommendedModule'] as String? ?? 'words',
      title: json['title'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      moduleXp: ModuleXp.fromJson(json['moduleXp'] as Map<String, dynamic>? ?? {}),
    );
  }
}
