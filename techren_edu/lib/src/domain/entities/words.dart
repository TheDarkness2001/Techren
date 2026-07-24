class LearningLanguage {
  const LearningLanguage({required this.id, required this.name, required this.moduleType});

  final String id;
  final String name;
  final String moduleType;

  factory LearningLanguage.fromJson(Map<String, dynamic> json) => LearningLanguage(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        moduleType: json['moduleType'] as String? ?? 'words',
      );
}

class LearningLevel {
  const LearningLevel({
    required this.id,
    required this.name,
    required this.languageId,
    this.minPassScore = 70,
    this.lessons = const [],
  });

  final String id;
  final String name;
  final String languageId;
  final int minPassScore;
  final List<StudentLesson> lessons;

  factory LearningLevel.fromJson(Map<String, dynamic> json) => LearningLevel(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        languageId: json['languageId']?.toString() ?? '',
        minPassScore: json['minPassScore'] as int? ?? 70,
        lessons: (json['lessons'] as List<dynamic>? ?? [])
            .map((e) => StudentLesson.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StudentLesson {
  const StudentLesson({
    required this.id,
    required this.name,
    required this.order,
    required this.status,
    required this.wordCount,
    required this.examUnlocked,
    this.bestExamScore = 0,
  });

  final String id;
  final String name;
  final int order;
  final String status;
  final int wordCount;
  final bool examUnlocked;
  final int bestExamScore;

  bool get isLocked => status == 'locked';
  bool get isPassed => status == 'passed';

  factory StudentLesson.fromJson(Map<String, dynamic> json) => StudentLesson(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        order: json['order'] as int? ?? 0,
        status: json['status'] as String? ?? 'locked',
        wordCount: json['wordCount'] as int? ?? 0,
        examUnlocked: json['examUnlocked'] as bool? ?? false,
        bestExamScore: json['bestExamScore'] as int? ?? 0,
      );
}

class WordPrompt {
  const WordPrompt({
    required this.id,
    required this.english,
    required this.uzbek,
    required this.direction,
    this.uzbekMeanings = const [],
    this.englishForms = const [],
  });

  final String id;
  final String english;
  final String uzbek;
  final String direction;
  final List<String> uzbekMeanings;
  final List<String> englishForms;

  String get promptText => direction == 'en-to-uz' ? english : uzbek.split(',').first.trim();

  factory WordPrompt.fromJson(Map<String, dynamic> json) => WordPrompt(
        id: json['id']?.toString() ?? '',
        english: json['english'] as String? ?? '',
        uzbek: json['uzbek'] as String? ?? '',
        direction: json['direction'] as String? ?? 'en-to-uz',
        uzbekMeanings: (json['uzbekMeanings'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        englishForms: (json['englishForms'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );
}

class AnswerCheckResult {
  const AnswerCheckResult({
    required this.isCorrect,
    required this.correctAnswer,
    required this.userAnswer,
    required this.direction,
  });

  final bool isCorrect;
  final String correctAnswer;
  final String userAnswer;
  final String direction;

  factory AnswerCheckResult.fromJson(Map<String, dynamic> json) => AnswerCheckResult(
        isCorrect: json['isCorrect'] as bool? ?? false,
        correctAnswer: json['correctAnswer'] as String? ?? '',
        userAnswer: json['userAnswer'] as String? ?? '',
        direction: json['direction'] as String? ?? '',
      );
}

class HomeworkProgressStats {
  const HomeworkProgressStats({
    required this.totalAttempts,
    required this.correctAnswers,
    required this.accuracy,
  });

  final int totalAttempts;
  final int correctAnswers;
  final int accuracy;

  factory HomeworkProgressStats.fromJson(Map<String, dynamic> json) => HomeworkProgressStats(
        totalAttempts: json['totalAttempts'] as int? ?? 0,
        correctAnswers: json['correctAnswers'] as int? ?? 0,
        accuracy: json['accuracy'] as int? ?? 0,
      );
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.studentCode,
    required this.accuracy,
    required this.correctAnswers,
    this.profileImage,
  });

  final int rank;
  final String name;
  final String studentCode;
  final int accuracy;
  final int correctAnswers;
  final String? profileImage;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        rank: json['rank'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        studentCode: json['studentCode'] as String? ?? '',
        accuracy: json['accuracy'] as int? ?? 0,
        correctAnswers: json['correctAnswers'] as int? ?? 0,
        profileImage: json['profileImage'] as String?,
      );
}

class WordsLeaderboard {
  const WordsLeaderboard({required this.leaderboard, this.currentStudent});

  final List<LeaderboardEntry> leaderboard;
  final LeaderboardEntry? currentStudent;

  factory WordsLeaderboard.fromJson(Map<String, dynamic> json) => WordsLeaderboard(
        leaderboard: (json['leaderboard'] as List<dynamic>? ?? [])
            .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentStudent: json['currentStudent'] != null
            ? LeaderboardEntry.fromJson(json['currentStudent'] as Map<String, dynamic>)
            : null,
      );
}
