class ModuleProgressSummary {
  const ModuleProgressSummary({
    required this.words,
    required this.sentences,
    required this.listening,
    required this.video,
    required this.vocabLessons,
  });

  final WordsProgressSummary words;
  final SentencesProgressSummary sentences;
  final ListeningProgressSummary listening;
  final VideoProgressSummary video;
  final VocabLessonsSummary vocabLessons;

  factory ModuleProgressSummary.fromJson(Map<String, dynamic> json) => ModuleProgressSummary(
        words: WordsProgressSummary.fromJson(json['words'] as Map<String, dynamic>? ?? {}),
        sentences: SentencesProgressSummary.fromJson(json['sentences'] as Map<String, dynamic>? ?? {}),
        listening: ListeningProgressSummary.fromJson(json['listening'] as Map<String, dynamic>? ?? {}),
        video: VideoProgressSummary.fromJson(json['video'] as Map<String, dynamic>? ?? {}),
        vocabLessons: VocabLessonsSummary.fromJson(json['vocabLessons'] as Map<String, dynamic>? ?? {}),
      );
}

class WordsProgressSummary {
  const WordsProgressSummary({
    this.totalAttempts = 0,
    this.correctAnswers = 0,
    this.accuracy = 0,
    this.enToUzAccuracy = 0,
    this.uzToEnAccuracy = 0,
  });

  final int totalAttempts;
  final int correctAnswers;
  final int accuracy;
  final int enToUzAccuracy;
  final int uzToEnAccuracy;

  factory WordsProgressSummary.fromJson(Map<String, dynamic> json) => WordsProgressSummary(
        totalAttempts: json['totalAttempts'] as int? ?? 0,
        correctAnswers: json['correctAnswers'] as int? ?? 0,
        accuracy: json['accuracy'] as int? ?? 0,
        enToUzAccuracy: json['enToUzAccuracy'] as int? ?? 0,
        uzToEnAccuracy: json['uzToEnAccuracy'] as int? ?? 0,
      );
}

class SentencesProgressSummary {
  const SentencesProgressSummary({
    this.totalAttempts = 0,
    this.totalCorrect = 0,
    this.accuracy = 0,
    this.exercisesPracticed = 0,
  });

  final int totalAttempts;
  final int totalCorrect;
  final int accuracy;
  final int exercisesPracticed;

  factory SentencesProgressSummary.fromJson(Map<String, dynamic> json) => SentencesProgressSummary(
        totalAttempts: json['totalAttempts'] as int? ?? 0,
        totalCorrect: json['totalCorrect'] as int? ?? 0,
        accuracy: json['accuracy'] as int? ?? 0,
        exercisesPracticed: json['exercisesPracticed'] as int? ?? 0,
      );
}

class ListeningProgressSummary {
  const ListeningProgressSummary({
    this.totalAttempts = 0,
    this.avgBestAccuracy = 0,
    this.exercisesPracticed = 0,
  });

  final int totalAttempts;
  final int avgBestAccuracy;
  final int exercisesPracticed;

  factory ListeningProgressSummary.fromJson(Map<String, dynamic> json) => ListeningProgressSummary(
        totalAttempts: json['totalAttempts'] as int? ?? 0,
        avgBestAccuracy: json['avgBestAccuracy'] as int? ?? 0,
        exercisesPracticed: json['exercisesPracticed'] as int? ?? 0,
      );
}

class VideoProgressSummary {
  const VideoProgressSummary({
    this.videosStarted = 0,
    this.videosCompleted = 0,
    this.avgWatchPercent = 0,
  });

  final int videosStarted;
  final int videosCompleted;
  final int avgWatchPercent;

  factory VideoProgressSummary.fromJson(Map<String, dynamic> json) => VideoProgressSummary(
        videosStarted: json['videosStarted'] as int? ?? 0,
        videosCompleted: json['videosCompleted'] as int? ?? 0,
        avgWatchPercent: json['avgWatchPercent'] as int? ?? 0,
      );
}

class VocabLessonsSummary {
  const VocabLessonsSummary({
    this.lessonsTracked = 0,
    this.lessonsPassed = 0,
    this.lessonsInProgress = 0,
  });

  final int lessonsTracked;
  final int lessonsPassed;
  final int lessonsInProgress;

  factory VocabLessonsSummary.fromJson(Map<String, dynamic> json) => VocabLessonsSummary(
        lessonsTracked: json['lessonsTracked'] as int? ?? 0,
        lessonsPassed: json['lessonsPassed'] as int? ?? 0,
        lessonsInProgress: json['lessonsInProgress'] as int? ?? 0,
      );
}

class ProgressOverview {
  const ProgressOverview({
    required this.student,
    required this.modules,
    this.gamification,
  });

  final ProgressStudent student;
  final ModuleProgressSummary modules;
  final Map<String, dynamic>? gamification;

  factory ProgressOverview.fromJson(Map<String, dynamic> json) => ProgressOverview(
        student: ProgressStudent.fromJson(json['student'] as Map<String, dynamic>),
        modules: ModuleProgressSummary.fromJson(json['modules'] as Map<String, dynamic>),
        gamification: json['gamification'] as Map<String, dynamic>?,
      );
}

class ProgressStudent {
  const ProgressStudent({
    required this.id,
    required this.name,
    this.studentCode,
    this.status,
    this.profileImage,
  });

  final String id;
  final String name;
  final String? studentCode;
  final String? status;
  final String? profileImage;

  factory ProgressStudent.fromJson(Map<String, dynamic> json) => ProgressStudent(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        studentCode: json['studentCode'] as String?,
        status: json['status'] as String?,
        profileImage: json['profileImage'] as String?,
      );
}

class StudentVocabLessonProgress {
  const StudentVocabLessonProgress({
    required this.lessonId,
    required this.lessonName,
    this.lessonOrder = 0,
    this.status = 'locked',
    this.bestExamScore = 0,
    this.examAttempts = 0,
    this.practiceAttempts = 0,
    this.practiceCorrect = 0,
    this.wordsMemorized = 0,
    this.wordsTotal = 0,
  });

  final String lessonId;
  final String lessonName;
  final int lessonOrder;
  final String status;
  final int bestExamScore;
  final int examAttempts;
  final int practiceAttempts;
  final int practiceCorrect;
  final int wordsMemorized;
  final int wordsTotal;

  factory StudentVocabLessonProgress.fromJson(Map<String, dynamic> json) => StudentVocabLessonProgress(
        lessonId: json['lessonId']?.toString() ?? '',
        lessonName: json['lessonName'] as String? ?? 'Lesson',
        lessonOrder: json['lessonOrder'] as int? ?? 0,
        status: json['status'] as String? ?? 'locked',
        bestExamScore: json['bestExamScore'] as int? ?? 0,
        examAttempts: json['examAttempts'] as int? ?? 0,
        practiceAttempts: json['practiceAttempts'] as int? ?? 0,
        practiceCorrect: json['practiceCorrect'] as int? ?? 0,
        wordsMemorized: json['wordsMemorized'] as int? ?? 0,
        wordsTotal: json['wordsTotal'] as int? ?? 0,
      );
}

class StudentVocabLessonsReport {
  const StudentVocabLessonsReport({
    required this.studentId,
    required this.lessons,
  });

  final String studentId;
  final List<StudentVocabLessonProgress> lessons;

  factory StudentVocabLessonsReport.fromJson(Map<String, dynamic> json) => StudentVocabLessonsReport(
        studentId: json['studentId']?.toString() ?? '',
        lessons: (json['lessons'] as List<dynamic>? ?? [])
            .map((e) => StudentVocabLessonProgress.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StudentProgressSummary {
  const StudentProgressSummary({
    required this.studentId,
    required this.name,
    this.studentCode,
    this.status,
    this.profileImage,
    this.wordsAccuracy = 0,
    this.wordsAttempts = 0,
    this.sentencesAccuracy = 0,
    this.listeningExercises = 0,
    this.videosCompleted = 0,
    this.lessonsPassed = 0,
    this.totalXp = 0,
    this.level = 1,
  });

  final String studentId;
  final String name;
  final String? studentCode;
  final String? status;
  final String? profileImage;
  final int wordsAccuracy;
  final int wordsAttempts;
  final int sentencesAccuracy;
  final int listeningExercises;
  final int videosCompleted;
  final int lessonsPassed;
  final int totalXp;
  final int level;

  factory StudentProgressSummary.fromJson(Map<String, dynamic> json) => StudentProgressSummary(
        studentId: json['studentId']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        studentCode: json['studentCode'] as String?,
        status: json['status'] as String?,
        profileImage: json['profileImage'] as String?,
        wordsAccuracy: json['wordsAccuracy'] as int? ?? 0,
        wordsAttempts: json['wordsAttempts'] as int? ?? 0,
        sentencesAccuracy: json['sentencesAccuracy'] as int? ?? 0,
        listeningExercises: json['listeningExercises'] as int? ?? 0,
        videosCompleted: json['videosCompleted'] as int? ?? 0,
        lessonsPassed: json['lessonsPassed'] as int? ?? 0,
        totalXp: json['totalXp'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
      );
}

class GroupProgressReport {
  const GroupProgressReport({
    required this.group,
    required this.aggregate,
    required this.students,
  });

  final Map<String, dynamic> group;
  final Map<String, dynamic> aggregate;
  final List<StudentProgressSummary> students;

  factory GroupProgressReport.fromJson(Map<String, dynamic> json) => GroupProgressReport(
        group: json['group'] as Map<String, dynamic>? ?? {},
        aggregate: json['aggregate'] as Map<String, dynamic>? ?? {},
        students: (json['students'] as List<dynamic>? ?? [])
            .map((e) => StudentProgressSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
