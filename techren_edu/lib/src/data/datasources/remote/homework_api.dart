import '../../../core/network/dio_client.dart';
import '../../../domain/entities/words.dart';
import '../../../domain/entities/learning_cms.dart';

class HomeworkApi {
  HomeworkApi(this._client);

  final DioClient _client;

  Future<List<LearningLanguage>> getLanguages() async {
    final response = await _client.dio.get('/homework/languages', queryParameters: {'moduleType': 'words'});
    return (response.data['data'] as List<dynamic>)
        .map((e) => LearningLanguage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LearningLevel>> getStudentLessons() async {
    final response = await _client.dio.get('/homework/student-lessons');
    return (response.data['data'] as List<dynamic>)
        .map((e) => LearningLevel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WordPrompt> getRandomWord(String lessonId) async {
    final response = await _client.dio.get('/homework/words/random', queryParameters: {'lessonId': lessonId});
    return WordPrompt.fromJson(response.data['data']['word'] as Map<String, dynamic>);
  }

  Future<AnswerCheckResult> checkAnswer({
    required String wordId,
    required String answer,
    required String direction,
  }) async {
    final response = await _client.dio.post('/homework/check-answer', data: {
      'wordId': wordId,
      'answer': answer,
      'direction': direction,
    });
    return AnswerCheckResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<HomeworkProgressStats> submitSession({
    required int totalAttempts,
    required int correctAnswers,
    required int enToUzCorrect,
    required int enToUzTotal,
    required int uzToEnCorrect,
    required int uzToEnTotal,
  }) async {
    final response = await _client.dio.post('/homework/submit-result', data: {
      'sessionStats': {
        'totalAttempts': totalAttempts,
        'correctAnswers': correctAnswers,
        'enToUzCorrect': enToUzCorrect,
        'enToUzTotal': enToUzTotal,
        'uzToEnCorrect': uzToEnCorrect,
        'uzToEnTotal': uzToEnTotal,
      },
    });
    return HomeworkProgressStats.fromJson(response.data['data']['progress'] as Map<String, dynamic>);
  }

  Future<void> updatePracticeStats(String lessonId, {required int attempts, required int correct}) async {
    await _client.dio.post('/homework/practice-stats', data: {
      'lessonId': lessonId,
      'attempts': attempts,
      'correct': correct,
    });
  }

  Future<WordsLeaderboard> getLeaderboard() async {
    final response = await _client.dio.get('/homework/leaderboard');
    return WordsLeaderboard.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<CmsLevel>> getLevels(String languageId) async {
    final response = await _client.dio.get('/homework/levels', queryParameters: {
      'languageId': languageId,
      'moduleType': 'words',
    });
    return (response.data['data'] as List<dynamic>)
        .map((e) => CmsLevel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CmsLesson>> getLessons(String levelId) async {
    final response = await _client.dio.get('/homework/lessons', queryParameters: {
      'levelId': levelId,
      'type': 'words',
    });
    return (response.data['data'] as List<dynamic>)
        .map((e) => CmsLesson.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CmsWord>> getLessonWords(String lessonId) async {
    final response = await _client.dio.get('/homework/words', queryParameters: {'lessonId': lessonId});
    return (response.data['data'] as List<dynamic>)
        .map((e) => CmsWord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CmsWord> addWord({required String lessonId, required String english, required String uzbek}) async {
    final response = await _client.dio.post('/homework/words', data: {
      'lessonId': lessonId,
      'english': english,
      'uzbek': uzbek,
    });
    return CmsWord.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<CmsWord> updateWord(String id, {required String english, required String uzbek}) async {
    final response = await _client.dio.put('/homework/words/$id', data: {
      'english': english,
      'uzbek': uzbek,
    });
    return CmsWord.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteWord(String id) async {
    await _client.dio.delete('/homework/words/$id');
  }

  Future<CmsLevel> togglePracticeUnlock({
    required String levelId,
    required String groupId,
    required bool unlock,
  }) async {
    final response = await _client.dio.post('/homework/levels/$levelId/practice-unlock', data: {
      'groupId': groupId,
      'unlock': unlock,
    });
    return CmsLevel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<CmsLesson> toggleExamLock({
    required String lessonId,
    required String groupId,
    required bool unlock,
  }) async {
    final response = await _client.dio.post('/homework/lessons/$lessonId/toggle-exam-lock', data: {
      'groupId': groupId,
      'unlock': unlock,
    });
    return CmsLesson.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<LearningLanguage> createLanguage({required String name, required String moduleType}) async {
    final response = await _client.dio.post('/homework/languages', data: {
      'name': name,
      'moduleType': moduleType,
    });
    return LearningLanguage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<LearningLanguage> updateLanguage(String id, {required String name}) async {
    final response = await _client.dio.put('/homework/languages/$id', data: {'name': name});
    return LearningLanguage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteLanguage(String id) async {
    await _client.dio.delete('/homework/languages/$id');
  }

  Future<CmsLevel> createLevel({
    required String languageId,
    required String name,
    required String moduleType,
  }) async {
    final response = await _client.dio.post('/homework/levels', data: {
      'languageId': languageId,
      'name': name,
      'moduleType': moduleType,
    });
    return CmsLevel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<CmsLevel> updateLevel(String id, {required String name}) async {
    final response = await _client.dio.put('/homework/levels/$id', data: {'name': name});
    return CmsLevel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteLevel(String id) async {
    await _client.dio.delete('/homework/levels/$id');
  }

  Future<CmsLesson> createLesson({
    required String levelId,
    required String name,
    required String type,
    int order = 1,
  }) async {
    final response = await _client.dio.post('/homework/lessons', data: {
      'levelId': levelId,
      'name': name,
      'type': type,
      'order': order,
    });
    return CmsLesson.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<CmsLesson> updateLesson(String id, {required String name, int? order}) async {
    final response = await _client.dio.put('/homework/lessons/$id', data: {
      'name': name,
      if (order != null) 'order': order,
    });
    return CmsLesson.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteLesson(String id) async {
    await _client.dio.delete('/homework/lessons/$id');
  }
}
