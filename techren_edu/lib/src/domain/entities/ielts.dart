class IeltsTimers {
  const IeltsTimers({
    this.listeningMinutes = 40,
    this.readingMinutes = 60,
    this.writingMinutes = 60,
  });

  final int listeningMinutes;
  final int readingMinutes;
  final int writingMinutes;

  factory IeltsTimers.fromJson(Map<String, dynamic>? json) => IeltsTimers(
        listeningMinutes: (json?['listeningMinutes'] as num?)?.toInt() ?? 40,
        readingMinutes: (json?['readingMinutes'] as num?)?.toInt() ?? 60,
        writingMinutes: (json?['writingMinutes'] as num?)?.toInt() ?? 60,
      );

  Map<String, dynamic> toJson() => {
        'listeningMinutes': listeningMinutes,
        'readingMinutes': readingMinutes,
        'writingMinutes': writingMinutes,
      };

  int totalSecondsForMode(String mode) {
    if (mode == 'listening') return listeningMinutes * 60;
    if (mode == 'reading') return readingMinutes * 60;
    if (mode == 'writing') return writingMinutes * 60;
    return (listeningMinutes + readingMinutes + writingMinutes) * 60;
  }
}

class IeltsExam {
  const IeltsExam({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description = '',
    this.mode = 'full',
    this.trainingType = 'academic',
    this.difficulty = 'official',
    this.timers = const IeltsTimers(),
    this.published = false,
    this.sections = const [],
  });

  final String id;
  final String subjectId;
  final String title;
  final String description;
  final String mode;
  final String trainingType;
  final String difficulty;
  final IeltsTimers timers;
  final bool published;
  final List<IeltsSection> sections;

  factory IeltsExam.fromJson(Map<String, dynamic> json) => IeltsExam(
        id: json['id']?.toString() ?? '',
        subjectId: json['subjectId']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        mode: json['mode'] as String? ?? 'full',
        trainingType: json['trainingType'] as String? ?? 'academic',
        difficulty: json['difficulty'] as String? ?? 'official',
        timers: IeltsTimers.fromJson(json['timers'] as Map<String, dynamic>?),
        published: json['published'] == true,
        sections: (json['sections'] as List<dynamic>? ?? [])
            .map((e) => IeltsSection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class IeltsSection {
  const IeltsSection({
    required this.id,
    required this.examId,
    required this.skill,
    this.order = 0,
    this.title = '',
    this.instructions = '',
    this.hasAudio = false,
    this.passage = '',
    this.prompt = '',
    this.imageUrl,
    this.writingTask,
    this.minWords = 0,
    this.questions = const [],
  });

  final String id;
  final String examId;
  final String skill;
  final int order;
  final String title;
  final String instructions;
  final bool hasAudio;
  final String passage;
  final String prompt;
  final String? imageUrl;
  final String? writingTask;
  final int minWords;
  final List<IeltsQuestion> questions;

  factory IeltsSection.fromJson(Map<String, dynamic> json) => IeltsSection(
        id: json['id']?.toString() ?? '',
        examId: json['examId']?.toString() ?? '',
        skill: json['skill'] as String? ?? 'listening',
        order: (json['order'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        instructions: json['instructions'] as String? ?? '',
        hasAudio: json['hasAudio'] == true,
        passage: json['passage'] as String? ?? '',
        prompt: json['prompt'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        writingTask: json['writingTask'] as String?,
        minWords: (json['minWords'] as num?)?.toInt() ?? 0,
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((e) => IeltsQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class IeltsQuestion {
  const IeltsQuestion({
    required this.id,
    required this.sectionId,
    required this.type,
    this.order = 0,
    this.number = 1,
    this.prompt = '',
    this.options = const [],
    this.answers = const [],
    this.points = 1,
  });

  final String id;
  final String sectionId;
  final String type;
  final int order;
  final int number;
  final String prompt;
  final List<String> options;
  final List<String> answers;
  final int points;

  bool get isWriting => type == 'task1' || type == 'task2';

  factory IeltsQuestion.fromJson(Map<String, dynamic> json) => IeltsQuestion(
        id: json['id']?.toString() ?? '',
        sectionId: json['sectionId']?.toString() ?? '',
        type: json['type'] as String? ?? 'mcq',
        order: (json['order'] as num?)?.toInt() ?? 0,
        number: (json['number'] as num?)?.toInt() ?? 1,
        prompt: json['prompt'] as String? ?? '',
        options: (json['options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        answers: (json['answers'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        points: (json['points'] as num?)?.toInt() ?? 1,
      );
}

class IeltsScores {
  const IeltsScores({
    this.listeningRaw,
    this.listeningMax,
    this.listeningBand,
    this.readingRaw,
    this.readingMax,
    this.readingBand,
    this.writingBand,
    this.overallBand,
  });

  final int? listeningRaw;
  final int? listeningMax;
  final double? listeningBand;
  final int? readingRaw;
  final int? readingMax;
  final double? readingBand;
  final double? writingBand;
  final double? overallBand;

  factory IeltsScores.fromJson(Map<String, dynamic>? json) => IeltsScores(
        listeningRaw: (json?['listeningRaw'] as num?)?.toInt(),
        listeningMax: (json?['listeningMax'] as num?)?.toInt(),
        listeningBand: (json?['listeningBand'] as num?)?.toDouble(),
        readingRaw: (json?['readingRaw'] as num?)?.toInt(),
        readingMax: (json?['readingMax'] as num?)?.toInt(),
        readingBand: (json?['readingBand'] as num?)?.toDouble(),
        writingBand: (json?['writingBand'] as num?)?.toDouble(),
        overallBand: (json?['overallBand'] as num?)?.toDouble(),
      );
}

class IeltsAttempt {
  const IeltsAttempt({
    required this.id,
    required this.studentId,
    required this.examId,
    required this.subjectId,
    required this.status,
    this.answers = const {},
    this.flags = const {},
    this.writingResponses = const {},
    this.currentSectionId,
    this.remainingSeconds,
    this.audioPlayed = false,
    this.startedAt,
    this.submittedAt,
    this.scores = const IeltsScores(),
    this.questionReview = const [],
    this.exam,
  });

  final String id;
  final String studentId;
  final String examId;
  final String subjectId;
  final String status;
  final Map<String, dynamic> answers;
  final Map<String, bool> flags;
  final Map<String, String> writingResponses;
  final String? currentSectionId;
  final int? remainingSeconds;
  final bool audioPlayed;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final IeltsScores scores;
  final List<IeltsQuestionReview> questionReview;
  final IeltsExam? exam;

  bool get isInProgress => status == 'in_progress';

  factory IeltsAttempt.fromJson(Map<String, dynamic> json) {
    final answersRaw = json['answers'];
    final flagsRaw = json['flags'];
    final writingRaw = json['writingResponses'];
    return IeltsAttempt(
      id: json['id']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      examId: json['examId']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      status: json['status'] as String? ?? 'in_progress',
      answers: answersRaw is Map
          ? answersRaw.map((k, v) => MapEntry(k.toString(), v))
          : const {},
      flags: flagsRaw is Map
          ? flagsRaw.map((k, v) => MapEntry(k.toString(), v == true))
          : const {},
      writingResponses: writingRaw is Map
          ? writingRaw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''))
          : const {},
      currentSectionId: json['currentSectionId']?.toString(),
      remainingSeconds: (json['remainingSeconds'] as num?)?.toInt(),
      audioPlayed: json['audioPlayed'] == true,
      startedAt: json['startedAt'] != null ? DateTime.tryParse(json['startedAt'].toString()) : null,
      submittedAt: json['submittedAt'] != null ? DateTime.tryParse(json['submittedAt'].toString()) : null,
      scores: IeltsScores.fromJson(json['scores'] as Map<String, dynamic>?),
      questionReview: (json['questionReview'] as List<dynamic>? ?? [])
          .map((e) => IeltsQuestionReview.fromJson(e as Map<String, dynamic>))
          .toList(),
      exam: json['exam'] is Map<String, dynamic> ? IeltsExam.fromJson(json['exam'] as Map<String, dynamic>) : null,
    );
  }
}

class IeltsQuestionReview {
  const IeltsQuestionReview({
    required this.questionId,
    required this.correct,
    this.studentAnswer,
    this.correctAnswers = const [],
  });

  final String questionId;
  final bool correct;
  final dynamic studentAnswer;
  final List<String> correctAnswers;

  factory IeltsQuestionReview.fromJson(Map<String, dynamic> json) => IeltsQuestionReview(
        questionId: json['questionId']?.toString() ?? '',
        correct: json['correct'] == true,
        studentAnswer: json['studentAnswer'],
        correctAnswers: (json['correctAnswers'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );
}

class IeltsWritingReview {
  const IeltsWritingReview({
    required this.id,
    required this.attemptId,
    required this.taskAchievement,
    required this.coherenceCohesion,
    required this.lexicalResource,
    required this.grammaticalRange,
    required this.overallBand,
    this.comments = '',
    this.corrections = '',
  });

  final String id;
  final String attemptId;
  final double taskAchievement;
  final double coherenceCohesion;
  final double lexicalResource;
  final double grammaticalRange;
  final double overallBand;
  final String comments;
  final String corrections;

  factory IeltsWritingReview.fromJson(Map<String, dynamic> json) => IeltsWritingReview(
        id: json['id']?.toString() ?? '',
        attemptId: json['attemptId']?.toString() ?? '',
        taskAchievement: (json['taskAchievement'] as num?)?.toDouble() ?? 0,
        coherenceCohesion: (json['coherenceCohesion'] as num?)?.toDouble() ?? 0,
        lexicalResource: (json['lexicalResource'] as num?)?.toDouble() ?? 0,
        grammaticalRange: (json['grammaticalRange'] as num?)?.toDouble() ?? 0,
        overallBand: (json['overallBand'] as num?)?.toDouble() ?? 0,
        comments: json['comments'] as String? ?? '',
        corrections: json['corrections'] as String? ?? '',
      );
}

class IeltsAttemptBundle {
  const IeltsAttemptBundle({
    required this.attempt,
    required this.exam,
    this.writingReview,
  });

  final IeltsAttempt attempt;
  final IeltsExam exam;
  final IeltsWritingReview? writingReview;

  factory IeltsAttemptBundle.fromJson(Map<String, dynamic> json) => IeltsAttemptBundle(
        attempt: IeltsAttempt.fromJson(json['attempt'] as Map<String, dynamic>),
        exam: IeltsExam.fromJson(json['exam'] as Map<String, dynamic>),
        writingReview: json['writingReview'] is Map<String, dynamic>
            ? IeltsWritingReview.fromJson(json['writingReview'] as Map<String, dynamic>)
            : null,
      );
}
