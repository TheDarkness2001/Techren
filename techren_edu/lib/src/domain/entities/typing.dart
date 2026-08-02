class TypingDashboard {
  const TypingDashboard({
    required this.subjectId,
    required this.level,
    required this.xp,
    required this.xpInLevel,
    required this.xpToNextLevel,
    this.currentRank,
    this.leaderboardSize = 0,
    this.bestWpm = 0,
    this.averageWpm = 0,
    this.accuracy = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.timePracticedSec = 0,
    this.wordsTyped = 0,
    this.testsCompleted = 0,
    this.favoriteMode,
    this.dailyChallengeCompleted = false,
    this.staffView = false,
    this.message,
  });

  final String subjectId;
  final int level;
  final int xp;
  final int xpInLevel;
  final int xpToNextLevel;
  final int? currentRank;
  final int leaderboardSize;
  final double bestWpm;
  final double averageWpm;
  final double accuracy;
  final int currentStreak;
  final int longestStreak;
  final int timePracticedSec;
  final int wordsTyped;
  final int testsCompleted;
  final String? favoriteMode;
  final bool dailyChallengeCompleted;
  final bool staffView;
  final String? message;

  factory TypingDashboard.fromJson(Map<String, dynamic> json) => TypingDashboard(
        subjectId: json['subjectId']?.toString() ?? '',
        level: (json['level'] as num?)?.toInt() ?? 1,
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        xpInLevel: (json['xpInLevel'] as num?)?.toInt() ?? 0,
        xpToNextLevel: (json['xpToNextLevel'] as num?)?.toInt() ?? 100,
        currentRank: (json['currentRank'] as num?)?.toInt(),
        leaderboardSize: (json['leaderboardSize'] as num?)?.toInt() ?? 0,
        bestWpm: (json['bestWpm'] as num?)?.toDouble() ?? 0,
        averageWpm: (json['averageWpm'] as num?)?.toDouble() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
        currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
        longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
        timePracticedSec: (json['timePracticedSec'] as num?)?.toInt() ?? 0,
        wordsTyped: (json['wordsTyped'] as num?)?.toInt() ?? 0,
        testsCompleted: (json['testsCompleted'] as num?)?.toInt() ?? 0,
        favoriteMode: json['favoriteMode'] as String?,
        dailyChallengeCompleted: json['dailyChallengeCompleted'] == true,
        staffView: json['staffView'] == true,
        message: json['message'] as String?,
      );
}

class TypingPrompt {
  const TypingPrompt({
    this.contentId,
    required this.mode,
    required this.difficulty,
    required this.text,
    this.title = '',
    this.language,
    this.words = const [],
  });

  final String? contentId;
  final String mode;
  final String difficulty;
  final String text;
  final String title;
  final String? language;
  final List<String> words;

  factory TypingPrompt.fromJson(Map<String, dynamic> json) => TypingPrompt(
        contentId: json['contentId']?.toString(),
        mode: json['mode'] as String? ?? 'programming',
        difficulty: json['difficulty'] as String? ?? 'medium',
        text: json['text'] as String? ?? '',
        title: json['title'] as String? ?? '',
        language: json['language'] as String?,
        words: (json['words'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );
}

class TypingSessionConfig {
  const TypingSessionConfig({
    required this.subjectId,
    required this.mode,
    required this.difficulty,
    required this.durationSec,
    this.unlimited = false,
    this.isDaily = false,
  });

  final String subjectId;
  final String mode;
  final String difficulty;
  final int durationSec;
  final bool unlimited;
  final bool isDaily;
}

class TypingStartPayload {
  const TypingStartPayload({required this.session, required this.prompt});

  final TypingSessionConfig session;
  final TypingPrompt prompt;

  factory TypingStartPayload.fromJson(Map<String, dynamic> json) {
    final s = json['session'] as Map<String, dynamic>? ?? {};
    return TypingStartPayload(
      session: TypingSessionConfig(
        subjectId: s['subjectId']?.toString() ?? '',
        mode: s['mode'] as String? ?? 'programming',
        difficulty: s['difficulty'] as String? ?? 'medium',
        durationSec: (s['durationSec'] as num?)?.toInt() ?? 60,
        unlimited: s['unlimited'] == true,
        isDaily: s['isDaily'] == true,
      ),
      prompt: TypingPrompt.fromJson(json['prompt'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class TypingResultCard {
  const TypingResultCard({
    required this.id,
    required this.wpm,
    required this.rawWpm,
    required this.accuracy,
    required this.xpEarned,
    this.xpReasons = const [],
    this.correctWords = 0,
    this.wrongWords = 0,
    this.totalChars = 0,
    this.mistakes = 0,
    this.improvementVsLast = 0,
    this.previousWpm = 0,
    this.mode = 'programming',
    this.isDaily = false,
    this.level = 1,
    this.totalXp = 0,
    this.currentStreak = 0,
  });

  final String id;
  final double wpm;
  final double rawWpm;
  final double accuracy;
  final int xpEarned;
  final List<String> xpReasons;
  final int correctWords;
  final int wrongWords;
  final int totalChars;
  final int mistakes;
  final double improvementVsLast;
  final double previousWpm;
  final String mode;
  final bool isDaily;
  final int level;
  final int totalXp;
  final int currentStreak;

  factory TypingResultCard.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>? ?? json;
    return TypingResultCard(
      id: result['id']?.toString() ?? '',
      wpm: (result['wpm'] as num?)?.toDouble() ?? 0,
      rawWpm: (result['rawWpm'] as num?)?.toDouble() ?? 0,
      accuracy: (result['accuracy'] as num?)?.toDouble() ?? 0,
      xpEarned: (result['xpEarned'] as num?)?.toInt() ?? 0,
      xpReasons: (result['xpReasons'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      correctWords: (result['correctWords'] as num?)?.toInt() ?? 0,
      wrongWords: (result['wrongWords'] as num?)?.toInt() ?? 0,
      totalChars: (result['totalChars'] as num?)?.toInt() ?? 0,
      mistakes: (result['mistakes'] as num?)?.toInt() ?? 0,
      improvementVsLast: (result['improvementVsLast'] as num?)?.toDouble() ?? 0,
      previousWpm: (result['previousWpm'] as num?)?.toDouble() ?? 0,
      mode: result['mode'] as String? ?? 'programming',
      isDaily: result['isDaily'] == true,
      level: (json['level'] as num?)?.toInt() ?? 1,
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
    );
  }
}

class TypingLeaderboardEntry {
  const TypingLeaderboardEntry({
    required this.rank,
    required this.studentId,
    required this.name,
    required this.level,
    required this.wpm,
    required this.accuracy,
    this.avatar,
    this.tests = 0,
  });

  final int rank;
  final String studentId;
  final String name;
  final int level;
  final double wpm;
  final double accuracy;
  final String? avatar;
  final int tests;

  factory TypingLeaderboardEntry.fromJson(Map<String, dynamic> json) => TypingLeaderboardEntry(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        studentId: json['studentId']?.toString() ?? '',
        name: json['name'] as String? ?? 'Student',
        level: (json['level'] as num?)?.toInt() ?? 1,
        wpm: (json['wpm'] as num?)?.toDouble() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
        avatar: json['avatar'] as String?,
        tests: (json['tests'] as num?)?.toInt() ?? 0,
      );
}
