import '../../../core/network/dio_client.dart';
import '../../../domain/entities/learning_cms.dart';
import '../../../domain/entities/sentences.dart';
import '../../../domain/entities/words.dart';

class SentencesApi {
  SentencesApi(this._client);

  final DioClient _client;

  Future<List<SentenceLevel>> getStudentLessons() async {
    final response = await _client.dio.get('/sentences/student-lessons');
    return (response.data['data'] as List<dynamic>)
        .map((e) => SentenceLevel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SentencePrompt> getRandomSentence(String lessonId, {String direction = 'enToUz'}) async {
    final response = await _client.dio.get('/sentences/random', queryParameters: {
      'lessonId': lessonId,
      'direction': direction,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    return SentencePrompt.fromSentenceJson(data, data['direction'] as String? ?? direction);
  }

  Future<SentenceCheckResult> checkAnswer({
    required String sentenceId,
    required String answer,
    required String direction,
  }) async {
    final response = await _client.dio.post('/sentences/check', data: {
      'sentenceId': sentenceId,
      'answer': answer,
      'direction': direction,
    });
    return SentenceCheckResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<SentencesLeaderboard> getLeaderboard() async {
    final response = await _client.dio.get('/sentences/leaderboard');
    return SentencesLeaderboard.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<LearningLanguage>> getCmsLanguages() async {
    final response = await _client.dio.get('/sentences/languages');
    return (response.data['data'] as List<dynamic>)
        .map((e) => LearningLanguage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CmsLevel>> getCmsLevels(String languageId) async {
    final response = await _client.dio.get('/sentences/levels', queryParameters: {
      'languageId': languageId,
      'moduleType': 'sentences',
    });
    return (response.data['data'] as List<dynamic>)
        .map((e) => CmsLevel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CmsLesson>> getCmsLessons(String levelId) async {
    final response = await _client.dio.get('/sentences/lessons', queryParameters: {'levelId': levelId});
    return (response.data['data'] as List<dynamic>)
        .map((e) => CmsLesson.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CmsSentence>> getLessonSentences(String lessonId) async {
    final response = await _client.dio.get('/sentences', queryParameters: {'lessonId': lessonId});
    return (response.data['data'] as List<dynamic>)
        .map((e) => CmsSentence.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CmsSentence> addSentence({
    required String lessonId,
    required String english,
    required String uzbek,
    String? task,
    String? imageUrl,
  }) async {
    final response = await _client.dio.post('/sentences', data: {
      'lessonId': lessonId,
      'english': english,
      'uzbek': uzbek,
      if (task != null) 'task': task,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    return CmsSentence.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<CmsSentence> updateSentence(
    String id, {
    required String english,
    required String uzbek,
    String? task,
    String? imageUrl,
  }) async {
    final response = await _client.dio.put('/sentences/$id', data: {
      'english': english,
      'uzbek': uzbek,
      if (task != null) 'task': task,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    return CmsSentence.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteSentence(String id) async {
    await _client.dio.delete('/sentences/$id');
  }
}
