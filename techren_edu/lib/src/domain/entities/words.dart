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
    this.xp = 0,
    this.bestStreak = 0,
  });

  final int rank;
  final String name;
  final String studentCode;
  final int accuracy;
  final int correctAnswers;
  final String? profileImage;
  final int xp;
  final int bestStreak;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        rank: json['rank'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        studentCode: json['studentCode'] as String? ?? '',
        accuracy: json['accuracy'] as int? ?? 0,
        correctAnswers: json['correctAnswers'] as int? ?? 0,
        profileImage: json['profileImage'] as String?,
        xp: (json['xp'] as num?)?.toInt() ?? 0,
        bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      );
}

class PracticeQuestionCard {
  const PracticeQuestionCard({
    required this.id,
    required this.wordId,
    required this.side,
    required this.text,
  });

  final String id;
  final String wordId;
  final String side;
  final String text;

  factory PracticeQuestionCard.fromJson(Map<String, dynamic> json) => PracticeQuestionCard(
        id: json['id']?.toString() ?? '',
        wordId: json['wordId']?.toString() ?? '',
        side: json['side'] as String? ?? 'en',
        text: json['text'] as String? ?? '',
      );
}

class PracticeQuestion {
  const PracticeQuestion({
    required this.questionId,
    required this.mode,
    required this.direction,
    required this.promptText,
    this.hint,
    this.timeLimitMs,
    this.choices = const [],
    this.statement,
    this.masked,
    this.scrambled,
    this.cards = const [],
  });

  final String questionId;
  final String mode;
  final String direction;
  final String promptText;
  final String? hint;
  final int? timeLimitMs;
  final List<String> choices;
  final String? statement;
  final String? masked;
  final String? scrambled;
  final List<PracticeQuestionCard> cards;

  factory PracticeQuestion.fromJson(Map<String, dynamic> json) => PracticeQuestion(
        questionId: json['questionId']?.toString() ?? '',
        mode: json['mode'] as String? ?? 'classic',
        direction: json['direction'] as String? ?? 'en-to-uz',
        promptText: json['promptText'] as String? ?? '',
        hint: json['hint'] as String?,
        timeLimitMs: (json['timeLimitMs'] as num?)?.toInt(),
        choices: (json['choices'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        statement: json['statement'] as String?,
        masked: json['masked'] as String?,
        scrambled: json['scrambled'] as String?,
        cards: (json['cards'] as List<dynamic>? ?? [])
            .map((e) => PracticeQuestionCard.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class PracticeAnswerStats {
  const PracticeAnswerStats({
    this.xpAwarded = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.accuracy = 0,
    this.correctAnswers = 0,
    this.totalAttempts = 0,
    this.dailyXpRemaining = 0,
    this.bestWordRush = 0,
  });

  final int xpAwarded;
  final int currentStreak;
  final int bestStreak;
  final int accuracy;
  final int correctAnswers;
  final int totalAttempts;
  final int dailyXpRemaining;
  final int bestWordRush;

  factory PracticeAnswerStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PracticeAnswerStats();
    return PracticeAnswerStats(
      xpAwarded: (json['xpAwarded'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      totalAttempts: (json['totalAttempts'] as num?)?.toInt() ?? 0,
      dailyXpRemaining: (json['dailyXpRemaining'] as num?)?.toInt() ?? 0,
      bestWordRush: (json['bestWordRush'] as num?)?.toInt() ?? 0,
    );
  }
}

class PracticeAnswerResult {
  const PracticeAnswerResult({
    required this.isCorrect,
    required this.correctAnswer,
    required this.userAnswer,
    this.timedOut = false,
    this.resolved = true,
    this.triesLeft = 0,
    this.stats = const PracticeAnswerStats(),
  });

  final bool isCorrect;
  final String correctAnswer;
  final String userAnswer;
  final bool timedOut;
  final bool resolved;
  final int triesLeft;
  final PracticeAnswerStats stats;

  factory PracticeAnswerResult.fromJson(Map<String, dynamic> json) {
    final isCorrect = json['isCorrect'] as bool? ?? false;
    final correctAnswer = json['correctAnswer'] as String? ?? '';
    final timedOut = json['timedOut'] as bool? ?? false;
    return PracticeAnswerResult(
      isCorrect: isCorrect,
      correctAnswer: correctAnswer,
      userAnswer: json['userAnswer'] as String? ?? '',
      timedOut: timedOut,
      resolved: json['resolved'] as bool? ?? (isCorrect || timedOut || correctAnswer.isNotEmpty),
      triesLeft: (json['triesLeft'] as num?)?.toInt() ?? 0,
      stats: PracticeAnswerStats.fromJson(json['stats'] as Map<String, dynamic>?),
    );
  }
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
