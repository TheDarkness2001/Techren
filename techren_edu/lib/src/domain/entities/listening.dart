class ListeningExerciseSummary {
  const ListeningExerciseSummary({
    required this.id,
    required this.title,
    required this.lessonId,
    required this.order,
    required this.hasAudio,
  });

  final String id;
  final String title;
  final String lessonId;
  final int order;
  final bool hasAudio;

  factory ListeningExerciseSummary.fromJson(Map<String, dynamic> json) => ListeningExerciseSummary(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        lessonId: json['lessonId']?.toString() ?? '',
        order: json['order'] as int? ?? 0,
        hasAudio: json['hasAudio'] as bool? ?? false,
      );
}

class ListeningLevel {
  const ListeningLevel({required this.id, required this.name, required this.exercises});

  final String id;
  final String name;
  final List<ListeningExerciseSummary> exercises;

  factory ListeningLevel.fromJson(Map<String, dynamic> json) => ListeningLevel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        exercises: (json['exercises'] as List<dynamic>? ?? [])
            .map((e) => ListeningExerciseSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class ListeningCheckResult {
  const ListeningCheckResult({
    required this.accuracyPercent,
    required this.correctWords,
    required this.totalWords,
    required this.missingWords,
    required this.tier,
    required this.passed,
    required this.taskFailed,
    required this.tryAgain,
    required this.isCorrect,
    required this.formattedResult,
  });

  final int accuracyPercent;
  final int correctWords;
  final int totalWords;
  final List<String> missingWords;
  final String tier;
  final bool passed;
  final bool taskFailed;
  final bool tryAgain;
  final bool isCorrect;
  final String formattedResult;

  factory ListeningCheckResult.fromJson(Map<String, dynamic> json) => ListeningCheckResult(
        accuracyPercent: json['accuracyPercent'] as int? ?? 0,
        correctWords: json['correctWords'] as int? ?? 0,
        totalWords: json['totalWords'] as int? ?? 0,
        missingWords: (json['missingWords'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        tier: json['tier'] as String? ?? json['resultTier'] as String? ?? 'failed',
        passed: json['passed'] as bool? ?? false,
        taskFailed: json['taskFailed'] as bool? ?? false,
        tryAgain: json['tryAgain'] as bool? ?? false,
        isCorrect: json['isCorrect'] as bool? ?? false,
        formattedResult: json['formattedResult'] as String? ?? '',
      );
}

class ListeningLeaderboardEntry {
  const ListeningLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.studentCode,
    required this.avgBestAccuracy,
    required this.totalAttempts,
  });

  final int rank;
  final String name;
  final String studentCode;
  final int avgBestAccuracy;
  final int totalAttempts;

  factory ListeningLeaderboardEntry.fromJson(Map<String, dynamic> json) => ListeningLeaderboardEntry(
        rank: json['rank'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        studentCode: json['studentCode'] as String? ?? '',
        avgBestAccuracy: json['avgBestAccuracy'] as int? ?? 0,
        totalAttempts: json['totalAttempts'] as int? ?? 0,
      );
}

class ListeningLeaderboard {
  const ListeningLeaderboard({required this.leaderboard, this.currentStudent});

  final List<ListeningLeaderboardEntry> leaderboard;
  final ListeningLeaderboardEntry? currentStudent;

  factory ListeningLeaderboard.fromJson(Map<String, dynamic> json) => ListeningLeaderboard(
        leaderboard: (json['leaderboard'] as List<dynamic>? ?? [])
            .map((e) => ListeningLeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentStudent: json['currentStudent'] != null
            ? ListeningLeaderboardEntry.fromJson(json['currentStudent'] as Map<String, dynamic>)
            : null,
      );
}
