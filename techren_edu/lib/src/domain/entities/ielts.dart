class IeltsTimers {
  const IeltsTimers({
    this.listeningMinutes = 30,
    this.readingMinutes = 60,
    this.writingMinutes = 60,
    this.speakingMinutes = 14,
  });

  final int listeningMinutes;
  final int readingMinutes;
  final int writingMinutes;
  final int speakingMinutes;

  factory IeltsTimers.fromJson(Map<String, dynamic>? json) => IeltsTimers(
        listeningMinutes: (json?['listeningMinutes'] as num?)?.toInt() ?? 30,
        readingMinutes: (json?['readingMinutes'] as num?)?.toInt() ?? 60,
        writingMinutes: (json?['writingMinutes'] as num?)?.toInt() ?? 60,
        speakingMinutes: (json?['speakingMinutes'] as num?)?.toInt() ?? 14,
      );

  Map<String, dynamic> toJson() => {
        'listeningMinutes': listeningMinutes,
        'readingMinutes': readingMinutes,
        'writingMinutes': writingMinutes,
        'speakingMinutes': speakingMinutes,
      };

  int secondsForSkill(String skill) {
    switch (skill) {
      case 'listening':
        return listeningMinutes * 60;
      case 'reading':
        return readingMinutes * 60;
      case 'writing':
        return writingMinutes * 60;
      case 'speaking':
        return speakingMinutes * 60;
      default:
        return listeningMinutes * 60;
    }
  }

  int totalSecondsForMode(String mode) {
    if (mode == 'listening' || mode == 'reading' || mode == 'writing' || mode == 'speaking') {
      return secondsForSkill(mode);
    }
    // Full Mock uses per-skill phases; initial clock is Listening.
    return secondsForSkill('listening');
  }
}

/// Real IELTS Full Mock skill order.
const kIeltsSkillOrder = ['listening', 'reading', 'writing', 'speaking'];

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
    this.archived = false,
    this.publishAt,
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
  final bool archived;
  final DateTime? publishAt;
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
        archived: json['archived'] == true,
        publishAt: json['publishAt'] != null ? DateTime.tryParse(json['publishAt'].toString()) : null,
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
    this.part,
    this.transcript = '',
    this.hasAudio = false,
    this.sourceId,
    this.passage = '',
    this.passageFormat = 'plain',
    this.answerHighlights = '',
    this.prompt = '',
    this.imageUrl,
    this.writingTask,
    this.writingSubtype,
    this.minWords = 0,
    this.suggestedMinutes = 0,
    this.speakingPrompt = '',
    this.speakingPart = 2,
    this.questions = const [],
  });

  final String id;
  final String examId;
  final String skill;
  final int order;
  final String title;
  final String instructions;
  final int? part;
  final String transcript;
  final bool hasAudio;
  final String? sourceId;
  final String passage;
  final String passageFormat;
  final String answerHighlights;
  final String prompt;
  final String? imageUrl;
  final String? writingTask;
  final String? writingSubtype;
  final int minWords;
  final int suggestedMinutes;
  final String speakingPrompt;
  final int speakingPart;
  final List<IeltsQuestion> questions;

  bool get isHtmlPassage => passageFormat == 'html';

  factory IeltsSection.fromJson(Map<String, dynamic> json) => IeltsSection(
        id: json['id']?.toString() ?? '',
        examId: json['examId']?.toString() ?? '',
        skill: json['skill'] as String? ?? 'listening',
        order: (json['order'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        instructions: json['instructions'] as String? ?? '',
        part: (json['part'] as num?)?.toInt(),
        transcript: json['transcript'] as String? ?? '',
        hasAudio: json['hasAudio'] == true,
        sourceId: json['sourceId']?.toString(),
        passage: json['passage'] as String? ?? '',
        passageFormat: json['passageFormat'] as String? ?? 'plain',
        answerHighlights: json['answerHighlights'] as String? ?? '',
        prompt: json['prompt'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        writingTask: json['writingTask'] as String?,
        writingSubtype: json['writingSubtype'] as String?,
        minWords: (json['minWords'] as num?)?.toInt() ?? 0,
        suggestedMinutes: (json['suggestedMinutes'] as num?)?.toInt() ?? 0,
        speakingPrompt: json['speakingPrompt'] as String? ?? '',
        speakingPart: (json['speakingPart'] as num?)?.toInt() ?? 2,
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((e) => IeltsQuestion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class IeltsBlank {
  const IeltsBlank({required this.id, this.label = '', this.order = 0});

  final String id;
  final String label;
  final int order;

  factory IeltsBlank.fromJson(Map<String, dynamic> json) => IeltsBlank(
        id: json['id']?.toString() ?? '',
        label: json['label'] as String? ?? '',
        order: (json['order'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'order': order};
}

class IeltsAcceptedAnswers {
  const IeltsAcceptedAnswers({
    this.primary = '',
    this.alternatives = const [],
    this.synonyms = const [],
    this.rejected = const [],
    this.explanation = '',
  });

  final String primary;
  final List<String> alternatives;
  final List<String> synonyms;
  final List<String> rejected;
  final String explanation;

  factory IeltsAcceptedAnswers.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const IeltsAcceptedAnswers();
    return IeltsAcceptedAnswers(
      primary: json['primary']?.toString() ?? '',
      alternatives: (json['alternatives'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      synonyms: (json['synonyms'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      rejected: (json['rejected'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'primary': primary,
        'alternatives': alternatives,
        'synonyms': synonyms,
        'rejected': rejected,
        'explanation': explanation,
      };
}

class IeltsQuestion {
  const IeltsQuestion({
    required this.id,
    required this.sectionId,
    required this.type,
    this.order = 0,
    this.number = 1,
    this.prompt = '',
    this.instruction = '',
    this.options = const [],
    this.answers = const [],
    this.acceptedAnswers = const IeltsAcceptedAnswers(),
    this.blanks = const [],
    this.wordLimit,
    this.allowArticles = false,
    this.allowPlurals = false,
    this.selectionMode = 'single',
    this.matchingStyle = 'dropdown',
    this.contentHtml = '',
    this.layout = 'default',
    this.points = 1,
    this.metadata = const {},
  });

  final String id;
  final String sectionId;
  final String type;
  final int order;
  final int number;
  final String prompt;
  final String instruction;
  final List<String> options;
  final List<String> answers;
  final IeltsAcceptedAnswers acceptedAnswers;
  final List<IeltsBlank> blanks;
  final String? wordLimit;
  final bool allowArticles;
  final bool allowPlurals;
  final String selectionMode;
  final String matchingStyle;
  final String contentHtml;
  final String layout;
  final int points;
  final Map<String, dynamic> metadata;

  bool get isWriting => type == 'task1' || type == 'task2';
  bool get isChoice => type == 'mcq' || type == 'tfng' || type == 'ynng';
  bool get isMatching => type == 'matching' || type == 'matching_headings';
  bool get isCompletion =>
      type == 'sentence_completion' ||
      type == 'form_completion' ||
      type == 'summary_completion' ||
      type == 'table_completion' ||
      type == 'short_answer';
  bool get isFutureLabeling => type == 'map_labeling' || type == 'diagram_labeling';

  List<String> get effectiveOptions {
    if (options.isNotEmpty) return options;
    if (type == 'tfng') return const ['True', 'False', 'Not Given'];
    if (type == 'ynng') return const ['Yes', 'No', 'Not Given'];
    return const [];
  }

  List<String> get matchingChoices {
    final fromMeta = metadata['choices'] ?? metadata['headings'] ?? metadata['options'];
    if (fromMeta is List) return fromMeta.map((e) => e.toString()).toList();
    return options;
  }

  factory IeltsQuestion.fromJson(Map<String, dynamic> json) {
    final meta = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : <String, dynamic>{};
    return IeltsQuestion(
      id: json['id']?.toString() ?? '',
      sectionId: json['sectionId']?.toString() ?? '',
      type: json['type'] as String? ?? 'mcq',
      order: (json['order'] as num?)?.toInt() ?? 0,
      number: (json['number'] as num?)?.toInt() ?? 1,
      prompt: json['prompt'] as String? ?? '',
      instruction: json['instruction'] as String? ?? meta['instruction']?.toString() ?? '',
      options: (json['options'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      answers: (json['answers'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      acceptedAnswers: IeltsAcceptedAnswers.fromJson(
        json['acceptedAnswers'] is Map ? Map<String, dynamic>.from(json['acceptedAnswers'] as Map) : null,
      ),
      blanks: (json['blanks'] as List<dynamic>? ?? [])
          .map((e) => IeltsBlank.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      wordLimit: json['wordLimit']?.toString() ?? meta['wordLimit']?.toString(),
      allowArticles: json['allowArticles'] == true || meta['allowArticles'] == true,
      allowPlurals: json['allowPlurals'] == true || meta['allowPlurals'] == true,
      selectionMode: json['selectionMode']?.toString() ?? meta['selectionMode']?.toString() ?? 'single',
      matchingStyle: json['matchingStyle']?.toString() ?? meta['matchingStyle']?.toString() ?? 'dropdown',
      contentHtml: json['contentHtml'] as String? ?? meta['contentHtml']?.toString() ?? '',
      layout: json['layout']?.toString() ?? meta['layout']?.toString() ?? 'default',
      points: (json['points'] as num?)?.toInt() ?? 1,
      metadata: meta,
    );
  }
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
    this.speakingBand,
    this.overallBand,
  });

  final int? listeningRaw;
  final int? listeningMax;
  final double? listeningBand;
  final int? readingRaw;
  final int? readingMax;
  final double? readingBand;
  final double? writingBand;
  final double? speakingBand;
  final double? overallBand;

  factory IeltsScores.fromJson(Map<String, dynamic>? json) => IeltsScores(
        listeningRaw: (json?['listeningRaw'] as num?)?.toInt(),
        listeningMax: (json?['listeningMax'] as num?)?.toInt(),
        listeningBand: (json?['listeningBand'] as num?)?.toDouble(),
        readingRaw: (json?['readingRaw'] as num?)?.toInt(),
        readingMax: (json?['readingMax'] as num?)?.toInt(),
        readingBand: (json?['readingBand'] as num?)?.toDouble(),
        writingBand: (json?['writingBand'] as num?)?.toDouble(),
        speakingBand: (json?['speakingBand'] as num?)?.toDouble(),
        overallBand: (json?['overallBand'] as num?)?.toDouble(),
      );
}

class IeltsSpeakingRecording {
  const IeltsSpeakingRecording({
    this.hasRecording = false,
    this.uploadedAt,
    this.durationSec,
  });

  final bool hasRecording;
  final DateTime? uploadedAt;
  final int? durationSec;

  factory IeltsSpeakingRecording.fromJson(Map<String, dynamic>? json) => IeltsSpeakingRecording(
        hasRecording: json?['hasRecording'] == true,
        uploadedAt: json?['uploadedAt'] != null ? DateTime.tryParse(json!['uploadedAt'].toString()) : null,
        durationSec: (json?['durationSec'] as num?)?.toInt(),
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
    this.speakingRecordings = const {},
    this.currentSkill,
    this.completedSkills = const [],
    this.currentSectionId,
    this.remainingSeconds,
    this.audioPlayed = false,
    this.audioPlayedBySection = const {},
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
  final Map<String, IeltsSpeakingRecording> speakingRecordings;
  final String? currentSkill;
  final List<String> completedSkills;
  final String? currentSectionId;
  final int? remainingSeconds;
  final bool audioPlayed;
  final Map<String, bool> audioPlayedBySection;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final IeltsScores scores;
  final List<IeltsQuestionReview> questionReview;
  final IeltsExam? exam;

  bool get isInProgress => status == 'in_progress';

  bool sectionAudioPlayed(String sectionId) =>
      audioPlayedBySection[sectionId] == true || (audioPlayed && audioPlayedBySection.isEmpty);

  bool speakingRecorded(String sectionId) => speakingRecordings[sectionId]?.hasRecording == true;

  factory IeltsAttempt.fromJson(Map<String, dynamic> json) {
    final answersRaw = json['answers'];
    final flagsRaw = json['flags'];
    final writingRaw = json['writingResponses'];
    final speakingRaw = json['speakingRecordings'];
    final playedRaw = json['audioPlayedBySection'];
    final completedRaw = json['completedSkills'];
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
      speakingRecordings: speakingRaw is Map
          ? speakingRaw.map(
              (k, v) => MapEntry(
                k.toString(),
                IeltsSpeakingRecording.fromJson(
                  v is Map ? Map<String, dynamic>.from(v) : null,
                ),
              ),
            )
          : const {},
      currentSkill: json['currentSkill']?.toString(),
      completedSkills: completedRaw is List
          ? completedRaw.map((e) => e.toString()).toList()
          : const [],
      currentSectionId: json['currentSectionId']?.toString(),
      remainingSeconds: (json['remainingSeconds'] as num?)?.toInt(),
      audioPlayed: json['audioPlayed'] == true,
      audioPlayedBySection: playedRaw is Map
          ? playedRaw.map((k, v) => MapEntry(k.toString(), v == true))
          : const {},
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
    this.explanation = '',
    this.reason,
    this.type = '',
    this.prompt = '',
    this.number,
    this.points = 1,
  });

  final String questionId;
  final bool correct;
  final dynamic studentAnswer;
  final List<String> correctAnswers;
  final String explanation;
  final String? reason;
  final String type;
  final String prompt;
  final int? number;
  final int points;

  factory IeltsQuestionReview.fromJson(Map<String, dynamic> json) => IeltsQuestionReview(
        questionId: json['questionId']?.toString() ?? '',
        correct: json['correct'] == true,
        studentAnswer: json['studentAnswer'],
        correctAnswers: (json['correctAnswers'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        explanation: json['explanation'] as String? ?? '',
        reason: json['reason']?.toString(),
        type: json['type']?.toString() ?? '',
        prompt: json['prompt'] as String? ?? '',
        number: (json['number'] as num?)?.toInt(),
        points: (json['points'] as num?)?.toInt() ?? 1,
      );
}

class IeltsWritingCriteria {
  const IeltsWritingCriteria({
    required this.taskAchievement,
    required this.coherenceCohesion,
    required this.lexicalResource,
    required this.grammaticalRange,
    this.mean = 0,
  });

  final double taskAchievement;
  final double coherenceCohesion;
  final double lexicalResource;
  final double grammaticalRange;
  final double mean;

  factory IeltsWritingCriteria.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const IeltsWritingCriteria(
        taskAchievement: 0,
        coherenceCohesion: 0,
        lexicalResource: 0,
        grammaticalRange: 0,
      );
    }
    return IeltsWritingCriteria(
      taskAchievement: (json['taskAchievement'] as num?)?.toDouble() ?? 0,
      coherenceCohesion: (json['coherenceCohesion'] as num?)?.toDouble() ?? 0,
      lexicalResource: (json['lexicalResource'] as num?)?.toDouble() ?? 0,
      grammaticalRange: (json['grammaticalRange'] as num?)?.toDouble() ?? 0,
      mean: (json['mean'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'taskAchievement': taskAchievement,
        'coherenceCohesion': coherenceCohesion,
        'lexicalResource': lexicalResource,
        'grammaticalRange': grammaticalRange,
      };
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
    this.task1,
    this.task2,
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
  final IeltsWritingCriteria? task1;
  final IeltsWritingCriteria? task2;
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
        task1: json['task1'] is Map<String, dynamic>
            ? IeltsWritingCriteria.fromJson(json['task1'] as Map<String, dynamic>)
            : null,
        task2: json['task2'] is Map<String, dynamic>
            ? IeltsWritingCriteria.fromJson(json['task2'] as Map<String, dynamic>)
            : null,
        comments: json['comments'] as String? ?? '',
        corrections: json['corrections'] as String? ?? '',
      );
}

class IeltsSpeakingReview {
  const IeltsSpeakingReview({
    required this.id,
    required this.attemptId,
    required this.fluencyCoherence,
    required this.lexicalResource,
    required this.grammaticalRange,
    required this.pronunciation,
    required this.overallBand,
    this.comments = '',
  });

  final String id;
  final String attemptId;
  final double fluencyCoherence;
  final double lexicalResource;
  final double grammaticalRange;
  final double pronunciation;
  final double overallBand;
  final String comments;

  factory IeltsSpeakingReview.fromJson(Map<String, dynamic> json) => IeltsSpeakingReview(
        id: json['id']?.toString() ?? '',
        attemptId: json['attemptId']?.toString() ?? '',
        fluencyCoherence: (json['fluencyCoherence'] as num?)?.toDouble() ?? 0,
        lexicalResource: (json['lexicalResource'] as num?)?.toDouble() ?? 0,
        grammaticalRange: (json['grammaticalRange'] as num?)?.toDouble() ?? 0,
        pronunciation: (json['pronunciation'] as num?)?.toDouble() ?? 0,
        overallBand: (json['overallBand'] as num?)?.toDouble() ?? 0,
        comments: json['comments'] as String? ?? '',
      );
}

class IeltsAttemptBundle {
  const IeltsAttemptBundle({
    required this.attempt,
    required this.exam,
    this.writingReview,
    this.speakingReview,
    this.finishedSkills = false,
    this.nextSkill,
  });

  final IeltsAttempt attempt;
  final IeltsExam exam;
  final IeltsWritingReview? writingReview;
  final IeltsSpeakingReview? speakingReview;
  final bool finishedSkills;
  final String? nextSkill;

  factory IeltsAttemptBundle.fromJson(Map<String, dynamic> json) => IeltsAttemptBundle(
        attempt: IeltsAttempt.fromJson(json['attempt'] as Map<String, dynamic>),
        exam: IeltsExam.fromJson(json['exam'] as Map<String, dynamic>),
        writingReview: json['writingReview'] is Map<String, dynamic>
            ? IeltsWritingReview.fromJson(json['writingReview'] as Map<String, dynamic>)
            : null,
        speakingReview: json['speakingReview'] is Map<String, dynamic>
            ? IeltsSpeakingReview.fromJson(json['speakingReview'] as Map<String, dynamic>)
            : null,
        finishedSkills: json['finishedSkills'] == true,
        nextSkill: json['nextSkill']?.toString(),
      );
}

/// Library source (book / audio / article) referenced by sections or bank items.
class IeltsSource {
  const IeltsSource({
    required this.id,
    this.subjectId,
    required this.title,
    this.author = '',
    this.publisher = '',
    this.publication = '',
    this.originalUrl = '',
    this.license = '',
    this.copyrightStatus = 'unknown',
    this.difficulty = 'Medium',
    this.topic = 'General',
    this.cefrLevel = '',
    this.wordCount = 0,
    this.durationSeconds = 0,
    this.language = 'en',
    this.country = '',
    this.kind = 'other',
    this.tags = const [],
    this.notes = '',
    this.status = 'active',
  });

  final String id;
  final String? subjectId;
  final String title;
  final String author;
  final String publisher;
  final String publication;
  final String originalUrl;
  final String license;
  final String copyrightStatus;
  final String difficulty;
  final String topic;
  final String cefrLevel;
  final int wordCount;
  final int durationSeconds;
  final String language;
  final String country;
  final String kind;
  final List<String> tags;
  final String notes;
  final String status;

  factory IeltsSource.fromJson(Map<String, dynamic> json) => IeltsSource(
        id: json['id']?.toString() ?? '',
        subjectId: json['subjectId']?.toString(),
        title: json['title'] as String? ?? '',
        author: json['author'] as String? ?? '',
        publisher: json['publisher'] as String? ?? '',
        publication: json['publication'] as String? ?? '',
        originalUrl: json['originalUrl'] as String? ?? '',
        license: json['license'] as String? ?? '',
        copyrightStatus: json['copyrightStatus'] as String? ?? 'unknown',
        difficulty: json['difficulty'] as String? ?? 'Medium',
        topic: json['topic'] as String? ?? 'General',
        cefrLevel: json['cefrLevel'] as String? ?? '',
        wordCount: (json['wordCount'] as num?)?.toInt() ?? 0,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
        language: json['language'] as String? ?? 'en',
        country: json['country'] as String? ?? '',
        kind: json['kind'] as String? ?? 'other',
        tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        notes: json['notes'] as String? ?? '',
        status: json['status'] as String? ?? 'active',
      );

  Map<String, dynamic> toJson() => {
        if (subjectId != null) 'subjectId': subjectId,
        'title': title,
        'author': author,
        'publisher': publisher,
        'publication': publication,
        'originalUrl': originalUrl,
        'license': license,
        'copyrightStatus': copyrightStatus,
        'difficulty': difficulty,
        'topic': topic,
        'cefrLevel': cefrLevel,
        'wordCount': wordCount,
        'durationSeconds': durationSeconds,
        'language': language,
        'country': country,
        'kind': kind,
        'tags': tags,
        'notes': notes,
        'status': status,
      };
}

/// Immutable snapshot of a bank question payload.
class IeltsQuestionBankVersion {
  const IeltsQuestionBankVersion({
    required this.id,
    required this.bankItemId,
    required this.version,
    required this.payload,
    this.createdAt,
  });

  final String id;
  final String bankItemId;
  final int version;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;

  factory IeltsQuestionBankVersion.fromJson(Map<String, dynamic> json) => IeltsQuestionBankVersion(
        id: json['id']?.toString() ?? '',
        bankItemId: json['bankItemId']?.toString() ?? '',
        version: (json['version'] as num?)?.toInt() ?? 1,
        payload: json['payload'] is Map
            ? Map<String, dynamic>.from(json['payload'] as Map)
            : <String, dynamic>{},
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      );
}

/// Reusable question bank item (skill/type + metadata); actual question content
/// lives in immutable [IeltsQuestionBankVersion] snapshots.
class IeltsBankItem {
  const IeltsBankItem({
    required this.id,
    this.subjectId,
    required this.skill,
    required this.type,
    this.title = '',
    this.topic = 'General',
    this.difficulty = 'Medium',
    this.tags = const [],
    this.sourceId,
    this.status = 'active',
    this.latestVersion = 1,
    this.versions = const [],
    this.latestPayload,
  });

  final String id;
  final String? subjectId;
  final String skill;
  final String type;
  final String title;
  final String topic;
  final String difficulty;
  final List<String> tags;
  final String? sourceId;
  final String status;
  final int latestVersion;
  final List<IeltsQuestionBankVersion> versions;
  final Map<String, dynamic>? latestPayload;

  factory IeltsBankItem.fromJson(Map<String, dynamic> json) => IeltsBankItem(
        id: json['id']?.toString() ?? '',
        subjectId: json['subjectId']?.toString(),
        skill: json['skill'] as String? ?? 'reading',
        type: json['type'] as String? ?? 'mcq',
        title: json['title'] as String? ?? '',
        topic: json['topic'] as String? ?? 'General',
        difficulty: json['difficulty'] as String? ?? 'Medium',
        tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
        sourceId: json['sourceId']?.toString(),
        status: json['status'] as String? ?? 'active',
        latestVersion: (json['latestVersion'] as num?)?.toInt() ?? 1,
        versions: (json['versions'] as List<dynamic>? ?? [])
            .map((e) => IeltsQuestionBankVersion.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        latestPayload: json['latestPayload'] is Map
            ? Map<String, dynamic>.from(json['latestPayload'] as Map)
            : null,
      );
}

/// Staff-facing exam-difficulty analytics for a single exam's questions.
class IeltsQuestionDifficultyRow {
  const IeltsQuestionDifficultyRow({
    required this.questionId,
    this.number,
    this.type = '',
    this.prompt = '',
    this.correct = 0,
    this.total = 0,
    this.accuracy,
    this.avgSeconds,
    this.difficultyHint = 'insufficient_data',
  });

  final String questionId;
  final int? number;
  final String type;
  final String prompt;
  final int correct;
  final int total;
  final double? accuracy;
  final int? avgSeconds;
  final String difficultyHint;

  factory IeltsQuestionDifficultyRow.fromJson(Map<String, dynamic> json) => IeltsQuestionDifficultyRow(
        questionId: json['questionId']?.toString() ?? '',
        number: (json['number'] as num?)?.toInt(),
        type: json['type'] as String? ?? '',
        prompt: json['prompt'] as String? ?? '',
        correct: (json['correct'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        avgSeconds: (json['avgSeconds'] as num?)?.toInt(),
        difficultyHint: json['difficultyHint'] as String? ?? 'insufficient_data',
      );
}

/// Staff analytics overview (aggregate across attempts).
class IeltsStaffAnalytics {
  const IeltsStaffAnalytics({
    this.totalAttempts = 0,
    this.averageListeningBand,
    this.averageReadingBand,
    this.bandDistribution = const {},
    this.questionTypeAccuracy = const [],
    this.days = 90,
  });

  final int totalAttempts;
  final double? averageListeningBand;
  final double? averageReadingBand;
  final Map<String, int> bandDistribution;
  final List<Map<String, dynamic>> questionTypeAccuracy;
  final int days;

  factory IeltsStaffAnalytics.fromJson(Map<String, dynamic> json) => IeltsStaffAnalytics(
        totalAttempts: (json['totalAttempts'] as num?)?.toInt() ?? 0,
        averageListeningBand: (json['averageListeningBand'] as num?)?.toDouble(),
        averageReadingBand: (json['averageReadingBand'] as num?)?.toDouble(),
        bandDistribution: json['bandDistribution'] is Map
            ? (json['bandDistribution'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
              )
            : const {},
        questionTypeAccuracy: (json['questionTypeAccuracy'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        days: (json['days'] as num?)?.toInt() ?? 90,
      );
}

/// Per-student strengths/weaknesses + band trend.
class IeltsStudentAnalytics {
  const IeltsStudentAnalytics({
    this.attemptsCompleted = 0,
    this.latestBands,
    this.bandTrend = const [],
    this.strengths = const [],
    this.weaknesses = const [],
    this.days = 180,
  });

  final int attemptsCompleted;
  final Map<String, dynamic>? latestBands;
  final List<Map<String, dynamic>> bandTrend;
  final List<Map<String, dynamic>> strengths;
  final List<Map<String, dynamic>> weaknesses;
  final int days;

  factory IeltsStudentAnalytics.fromJson(Map<String, dynamic> json) => IeltsStudentAnalytics(
        attemptsCompleted: (json['attemptsCompleted'] as num?)?.toInt() ?? 0,
        latestBands: json['latestBands'] is Map ? Map<String, dynamic>.from(json['latestBands'] as Map) : null,
        bandTrend: (json['bandTrend'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        strengths: (json['strengths'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        weaknesses: (json['weaknesses'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        days: (json['days'] as num?)?.toInt() ?? 180,
      );
}
