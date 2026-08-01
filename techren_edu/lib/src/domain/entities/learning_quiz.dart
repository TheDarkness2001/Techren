class LearningQuizQuestion {
  const LearningQuizQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    required this.options,
    required this.points,
    this.correctOptionIndex,
    this.answers = const [],
  });

  final String id;
  final String type; // mcq | form_completion
  final String prompt;
  final List<String> options;
  final int points;
  final int? correctOptionIndex;
  final List<String> answers;

  bool get isMcq => type == 'mcq';
  bool get isFormCompletion => type == 'form_completion';

  factory LearningQuizQuestion.fromJson(Map<String, dynamic> json) {
    return LearningQuizQuestion(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'mcq',
      prompt: json['prompt']?.toString() ?? '',
      options: (json['options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      points: (json['points'] as num?)?.toInt() ?? 1,
      correctOptionIndex: (json['correctOptionIndex'] as num?)?.toInt(),
      answers: (json['answers'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson({bool includeAnswers = true}) => {
        if (id.isNotEmpty) 'id': id,
        'type': type,
        'prompt': prompt,
        'options': options,
        'points': points,
        if (includeAnswers && correctOptionIndex != null) 'correctOptionIndex': correctOptionIndex,
        if (includeAnswers) 'answers': answers,
      };
}

class LearningQuiz {
  const LearningQuiz({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.topic,
    required this.level,
    required this.description,
    required this.published,
    required this.unlockedFor,
    required this.passingScore,
    required this.timeLimitMinutes,
    required this.questionCount,
    required this.questions,
    this.unlocked,
  });

  final String id;
  final String subjectId;
  final String title;
  final String topic;
  final String level;
  final String description;
  final bool published;
  final List<String> unlockedFor;
  final int passingScore;
  final int timeLimitMinutes;
  final int questionCount;
  final List<LearningQuizQuestion> questions;
  final bool? unlocked;

  bool get isUnlocked => unlocked != false;

  factory LearningQuiz.fromJson(Map<String, dynamic> json) {
    return LearningQuiz(
      id: json['id']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      topic: json['topic']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      published: json['published'] == true,
      unlockedFor: (json['unlockedFor'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      passingScore: (json['passingScore'] as num?)?.toInt() ?? 70,
      timeLimitMinutes: (json['timeLimitMinutes'] as num?)?.toInt() ?? 0,
      questionCount: (json['questionCount'] as num?)?.toInt() ??
          (json['questions'] as List<dynamic>? ?? []).length,
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((e) => LearningQuizQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      unlocked: json['unlocked'] as bool?,
    );
  }
}

class LearningQuizAttemptAnswer {
  const LearningQuizAttemptAnswer({
    required this.questionId,
    this.selectedOptionIndex,
    this.textAnswers = const [],
    this.correct,
    this.pointsAwarded,
  });

  final String questionId;
  final int? selectedOptionIndex;
  final List<String> textAnswers;
  final bool? correct;
  final int? pointsAwarded;

  factory LearningQuizAttemptAnswer.fromJson(Map<String, dynamic> json) {
    return LearningQuizAttemptAnswer(
      questionId: json['questionId']?.toString() ?? '',
      selectedOptionIndex: (json['selectedOptionIndex'] as num?)?.toInt(),
      textAnswers: (json['textAnswers'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      correct: json['correct'] as bool?,
      pointsAwarded: (json['pointsAwarded'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        if (selectedOptionIndex != null) 'selectedOptionIndex': selectedOptionIndex,
        if (textAnswers.isNotEmpty) 'textAnswers': textAnswers,
      };
}

class LearningQuizAttempt {
  const LearningQuizAttempt({
    required this.id,
    required this.quizId,
    required this.subjectId,
    required this.studentId,
    required this.status,
    required this.answers,
    required this.scorePercent,
    required this.pointsEarned,
    required this.pointsPossible,
    required this.passed,
    this.startedAt,
    this.submittedAt,
    this.quiz,
  });

  final String id;
  final String quizId;
  final String subjectId;
  final String studentId;
  final String status;
  final List<LearningQuizAttemptAnswer> answers;
  final int scorePercent;
  final int pointsEarned;
  final int pointsPossible;
  final bool passed;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final LearningQuiz? quiz;

  factory LearningQuizAttempt.fromJson(Map<String, dynamic> json) {
    return LearningQuizAttempt(
      id: json['id']?.toString() ?? '',
      quizId: json['quizId']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'in_progress',
      answers: (json['answers'] as List<dynamic>? ?? [])
          .map((e) => LearningQuizAttemptAnswer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      scorePercent: (json['scorePercent'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      pointsPossible: (json['pointsPossible'] as num?)?.toInt() ?? 0,
      passed: json['passed'] == true,
      startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt'].toString()) : null,
      submittedAt: json['submittedAt'] != null ? DateTime.tryParse(json['submittedAt'].toString()) : null,
      quiz: json['quiz'] is Map
          ? LearningQuiz.fromJson(Map<String, dynamic>.from(json['quiz'] as Map))
          : null,
    );
  }
}
