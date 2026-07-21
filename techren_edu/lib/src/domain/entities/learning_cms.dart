class CmsListeningExercise {
  const CmsListeningExercise({
    required this.id,
    required this.title,
    required this.script,
    required this.lessonId,
    required this.order,
    required this.hasAudio,
    this.audioFile,
  });

  final String id;
  final String title;
  final String script;
  final String lessonId;
  final int order;
  final bool hasAudio;
  final String? audioFile;

  factory CmsListeningExercise.fromJson(Map<String, dynamic> json) => CmsListeningExercise(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        script: json['script'] as String? ?? '',
        lessonId: json['lessonId']?.toString() ?? '',
        order: json['order'] as int? ?? 1,
        hasAudio: json['hasAudio'] as bool? ?? false,
        audioFile: json['audioFile'] as String?,
      );
}

class CmsSentence {
  const CmsSentence({
    required this.id,
    required this.english,
    required this.uzbek,
    required this.lessonId,
    this.task = '',
    this.imageUrl = '',
  });

  final String id;
  final String english;
  final String uzbek;
  final String lessonId;
  final String task;
  final String imageUrl;

  factory CmsSentence.fromJson(Map<String, dynamic> json) => CmsSentence(
        id: json['id']?.toString() ?? '',
        english: json['english'] as String? ?? '',
        uzbek: json['uzbek'] as String? ?? '',
        lessonId: json['lessonId']?.toString() ?? '',
        task: json['task'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
      );
}

class CmsWord {
  const CmsWord({
    required this.id,
    required this.english,
    required this.uzbek,
    required this.lessonId,
  });

  final String id;
  final String english;
  final String uzbek;
  final String lessonId;

  factory CmsWord.fromJson(Map<String, dynamic> json) => CmsWord(
        id: json['id']?.toString() ?? '',
        english: json['english'] as String? ?? '',
        uzbek: json['uzbek'] as String? ?? '',
        lessonId: json['lessonId']?.toString() ?? '',
      );
}

class CmsLesson {
  const CmsLesson({
    required this.id,
    required this.name,
    required this.levelId,
    this.order = 1,
    this.wordCount = 0,
    this.type = 'words',
    this.examUnlockedFor = const [],
  });

  final String id;
  final String name;
  final String levelId;
  final int order;
  final int wordCount;
  final String type;
  final List<String> examUnlockedFor;

  bool isExamUnlockedFor(String groupId) => examUnlockedFor.contains(groupId);

  factory CmsLesson.fromJson(Map<String, dynamic> json) => CmsLesson(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        levelId: json['levelId']?.toString() ?? '',
        order: json['order'] as int? ?? 1,
        wordCount: json['wordCount'] as int? ?? 0,
        type: json['type'] as String? ?? 'words',
        examUnlockedFor: (json['examUnlockedFor'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}

class CmsLevel {
  const CmsLevel({
    required this.id,
    required this.name,
    required this.languageId,
    this.moduleType = 'words',
    this.practiceUnlockedFor = const [],
  });

  final String id;
  final String name;
  final String languageId;
  final String moduleType;
  final List<String> practiceUnlockedFor;

  bool isPracticeUnlockedFor(String groupId) => practiceUnlockedFor.contains(groupId);

  factory CmsLevel.fromJson(Map<String, dynamic> json) => CmsLevel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        languageId: json['languageId']?.toString() ?? '',
        moduleType: json['moduleType'] as String? ?? 'words',
        practiceUnlockedFor: (json['practiceUnlockedFor'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
      );
}
