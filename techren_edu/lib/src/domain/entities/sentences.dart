class SentencePrompt {
  const SentencePrompt({
    required this.id,
    required this.english,
    required this.uzbek,
    required this.direction,
  });

  final String id;
  final String english;
  final String uzbek;
  final String direction;

  String get promptText => direction == 'uzToEn' ? uzbek : english;

  factory SentencePrompt.fromSentenceJson(Map<String, dynamic> json, String direction) {
    final sentence = json['sentence'] as Map<String, dynamic>? ?? json;
    return SentencePrompt(
      id: sentence['id']?.toString() ?? '',
      english: sentence['english'] as String? ?? '',
      uzbek: sentence['uzbek'] as String? ?? '',
      direction: direction,
    );
  }
}

class SentenceCheckResult {
  const SentenceCheckResult({
    required this.isCorrect,
    required this.correctAnswer,
    required this.yourAnswer,
    required this.similarityScore,
    required this.categories,
    required this.diff,
  });

  final bool isCorrect;
  final String correctAnswer;
  final String yourAnswer;
  final int similarityScore;
  final List<String> categories;
  final List<Map<String, dynamic>> diff;

  factory SentenceCheckResult.fromJson(Map<String, dynamic> json) => SentenceCheckResult(
        isCorrect: json['isCorrect'] as bool? ?? false,
        correctAnswer: json['correctAnswer'] as String? ?? '',
        yourAnswer: json['yourAnswer'] as String? ?? '',
        similarityScore: json['similarityScore'] as int? ?? 0,
        categories: (json['categories'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        diff: (json['diff'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );
}

class SentenceLesson {
  const SentenceLesson({
    required this.id,
    required this.name,
    required this.order,
    required this.sentenceCount,
    required this.status,
  });

  final String id;
  final String name;
  final int order;
  final int sentenceCount;
  final String status;

  bool get isLocked => status == 'locked';

  factory SentenceLesson.fromJson(Map<String, dynamic> json) => SentenceLesson(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        order: json['order'] as int? ?? 0,
        sentenceCount: json['sentenceCount'] as int? ?? 0,
        status: json['status'] as String? ?? 'locked',
      );
}

class SentenceLevel {
  const SentenceLevel({required this.id, required this.name, required this.lessons});

  final String id;
  final String name;
  final List<SentenceLesson> lessons;

  factory SentenceLevel.fromJson(Map<String, dynamic> json) => SentenceLevel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        lessons: (json['lessons'] as List<dynamic>? ?? [])
            .map((e) => SentenceLesson.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SentencesLeaderboardEntry {
  const SentencesLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.studentCode,
    required this.accuracy,
    required this.totalCorrect,
    this.totalAttempts = 0,
  });

  final int rank;
  final String name;
  final String studentCode;
  final int accuracy;
  final int totalCorrect;
  final int totalAttempts;

  factory SentencesLeaderboardEntry.fromJson(Map<String, dynamic> json) => SentencesLeaderboardEntry(
        rank: json['rank'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        studentCode: json['studentCode'] as String? ?? '',
        accuracy: json['accuracy'] as int? ?? 0,
        totalCorrect: json['totalCorrect'] as int? ?? 0,
        totalAttempts: json['totalAttempts'] as int? ?? 0,
      );
}

class SentencesLeaderboard {
  const SentencesLeaderboard({required this.leaderboard, this.currentStudent});

  final List<SentencesLeaderboardEntry> leaderboard;
  final SentencesLeaderboardEntry? currentStudent;

  factory SentencesLeaderboard.fromJson(Map<String, dynamic> json) => SentencesLeaderboard(
        leaderboard: (json['leaderboard'] as List<dynamic>? ?? [])
            .map((e) => SentencesLeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentStudent: json['currentStudent'] != null
            ? SentencesLeaderboardEntry.fromJson(json['currentStudent'] as Map<String, dynamic>)
            : null,
      );
}
