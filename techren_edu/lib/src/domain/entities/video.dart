class VideoProgress {
  const VideoProgress({
    required this.watchPercent,
    required this.completed,
    this.completedAt,
    this.lastTimestamp = 0,
    this.rewatchCount = 0,
  });

  final int watchPercent;
  final bool completed;
  final DateTime? completedAt;
  final int lastTimestamp;
  final int rewatchCount;

  factory VideoProgress.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const VideoProgress(watchPercent: 0, completed: false);
    }
    return VideoProgress(
      watchPercent: json['watchPercent'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null,
      lastTimestamp: json['lastTimestamp'] as int? ?? 0,
      rewatchCount: json['rewatchCount'] as int? ?? 0,
    );
  }
}

class VideoLessonSummary {
  const VideoLessonSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.youtubeUrl,
    required this.youtubeVideoId,
    required this.levelName,
    required this.requireWatchPercent,
    required this.hasTest,
    this.progress,
  });

  final String id;
  final String title;
  final String description;
  final String thumbnail;
  final String youtubeUrl;
  final String youtubeVideoId;
  final String levelName;
  final int requireWatchPercent;
  final bool hasTest;
  final VideoProgress? progress;

  factory VideoLessonSummary.fromJson(Map<String, dynamic> json, {bool hasTest = false}) => VideoLessonSummary(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        thumbnail: json['thumbnail'] as String? ?? '',
        youtubeUrl: json['youtubeUrl'] as String? ?? '',
        youtubeVideoId: json['youtubeVideoId'] as String? ?? '',
        levelName: json['levelName'] as String? ?? '',
        requireWatchPercent: json['requireWatchPercent'] as int? ?? 70,
        hasTest: hasTest,
        progress: json['progress'] != null ? VideoProgress.fromJson(json['progress'] as Map<String, dynamic>) : null,
      );
}

class VideoLessonDetail {
  const VideoLessonDetail({
    required this.lesson,
    required this.hasTest,
    this.testMeta,
    this.progress,
  });

  final VideoLessonSummary lesson;
  final bool hasTest;
  final VideoTestMeta? testMeta;
  final VideoProgress? progress;

  factory VideoLessonDetail.fromJson(Map<String, dynamic> json) {
    final hasTest = json['hasTest'] as bool? ?? false;
    return VideoLessonDetail(
      lesson: VideoLessonSummary.fromJson(json['videoLesson'] as Map<String, dynamic>, hasTest: hasTest),
      hasTest: hasTest,
      testMeta: json['testMeta'] != null ? VideoTestMeta.fromJson(json['testMeta'] as Map<String, dynamic>) : null,
      progress: json['progress'] != null ? VideoProgress.fromJson(json['progress'] as Map<String, dynamic>) : null,
    );
  }
}

class VideoTestMeta {
  const VideoTestMeta({
    required this.id,
    required this.title,
    required this.practiceEnabled,
    required this.examEnabled,
    required this.timerSeconds,
    required this.passingScore,
    required this.questionCount,
  });

  final String id;
  final String title;
  final bool practiceEnabled;
  final bool examEnabled;
  final int timerSeconds;
  final int passingScore;
  final int questionCount;

  factory VideoTestMeta.fromJson(Map<String, dynamic> json) => VideoTestMeta(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        practiceEnabled: json['practiceEnabled'] as bool? ?? true,
        examEnabled: json['examEnabled'] as bool? ?? true,
        timerSeconds: json['timerSeconds'] as int? ?? 300,
        passingScore: json['passingScore'] as int? ?? 70,
        questionCount: json['questionCount'] as int? ?? 0,
      );
}

class VideoTestQuestion {
  const VideoTestQuestion({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.points,
  });

  final String id;
  final String type;
  final String question;
  final List<String> options;
  final int points;

  factory VideoTestQuestion.fromJson(Map<String, dynamic> json) => VideoTestQuestion(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        type: json['type'] as String? ?? 'multiple-choice',
        question: json['question'] as String? ?? '',
        options: (json['options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        points: json['points'] as int? ?? 1,
      );
}

class VideoTopicTest {
  const VideoTopicTest({
    required this.id,
    required this.title,
    required this.practiceEnabled,
    required this.examEnabled,
    required this.timerSeconds,
    required this.passingScore,
    required this.questions,
  });

  final String id;
  final String title;
  final bool practiceEnabled;
  final bool examEnabled;
  final int timerSeconds;
  final int passingScore;
  final List<VideoTestQuestion> questions;

  factory VideoTopicTest.fromJson(Map<String, dynamic> json) => VideoTopicTest(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        practiceEnabled: json['practiceEnabled'] as bool? ?? true,
        examEnabled: json['examEnabled'] as bool? ?? true,
        timerSeconds: json['timerSeconds'] as int? ?? 300,
        passingScore: json['passingScore'] as int? ?? 70,
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((e) => VideoTestQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class VideoTestFeedback {
  const VideoTestFeedback({
    required this.questionId,
    required this.isCorrect,
    this.userAnswer,
    this.correctAnswer,
    this.explanation,
  });

  final String questionId;
  final bool isCorrect;
  final dynamic userAnswer;
  final dynamic correctAnswer;
  final String? explanation;

  factory VideoTestFeedback.fromJson(Map<String, dynamic> json) => VideoTestFeedback(
        questionId: json['questionId']?.toString() ?? '',
        isCorrect: json['isCorrect'] as bool? ?? false,
        userAnswer: json['userAnswer'],
        correctAnswer: json['correctAnswer'],
        explanation: json['explanation'] as String?,
      );
}

class VideoTestAttemptResult {
  const VideoTestAttemptResult({
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.passed,
    required this.bestScore,
    required this.attempts,
    required this.feedback,
  });

  final int score;
  final int correctCount;
  final int totalQuestions;
  final bool passed;
  final int bestScore;
  final int attempts;
  final List<VideoTestFeedback> feedback;

  factory VideoTestAttemptResult.fromJson(Map<String, dynamic> json) => VideoTestAttemptResult(
        score: json['score'] as int? ?? 0,
        correctCount: json['correctCount'] as int? ?? 0,
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        passed: json['passed'] as bool? ?? false,
        bestScore: json['bestScore'] as int? ?? 0,
        attempts: json['attempts'] as int? ?? 0,
        feedback: (json['feedback'] as List<dynamic>? ?? [])
            .map((e) => VideoTestFeedback.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class VideoTestLeaderboardEntry {
  const VideoTestLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.studentCode,
    required this.bestScore,
    required this.attempts,
    required this.passed,
  });

  final int rank;
  final String name;
  final String studentCode;
  final int bestScore;
  final int attempts;
  final bool passed;

  factory VideoTestLeaderboardEntry.fromJson(Map<String, dynamic> json) => VideoTestLeaderboardEntry(
        rank: json['rank'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        studentCode: json['studentCode'] as String? ?? '',
        bestScore: json['bestScore'] as int? ?? 0,
        attempts: json['attempts'] as int? ?? 0,
        passed: json['passed'] as bool? ?? false,
      );
}
