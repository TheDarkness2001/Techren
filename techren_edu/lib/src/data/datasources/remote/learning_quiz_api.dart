import '../../../core/network/dio_client.dart';
import '../../../domain/entities/learning_quiz.dart';

class LearningQuizApi {
  LearningQuizApi(this._client);

  final DioClient _client;

  Future<List<LearningQuiz>> listQuizzes({
    required String subjectId,
    String? level,
    String? topic,
  }) async {
    final response = await _client.dio.get('/quizzes', queryParameters: {
      'subjectId': subjectId,
      if (level != null && level.isNotEmpty) 'level': level,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
    });
    return (response.data['data'] as List<dynamic>)
        .map((e) => LearningQuiz.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<LearningQuiz> getQuiz(String id) async {
    final response = await _client.dio.get('/quizzes/$id');
    return LearningQuiz.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<LearningQuiz> createQuiz(Map<String, dynamic> body) async {
    final response = await _client.dio.post('/quizzes', data: body);
    return LearningQuiz.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<LearningQuiz> updateQuiz(String id, Map<String, dynamic> body) async {
    final response = await _client.dio.put('/quizzes/$id', data: body);
    return LearningQuiz.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<void> deleteQuiz(String id) async {
    await _client.dio.delete('/quizzes/$id');
  }

  Future<LearningQuiz> toggleUnlock({
    required String quizId,
    required String groupId,
    required bool unlock,
  }) async {
    final response = await _client.dio.post('/quizzes/$quizId/unlock', data: {
      'groupId': groupId,
      'unlock': unlock,
    });
    return LearningQuiz.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<LearningQuizAttempt> startAttempt(String quizId) async {
    final response = await _client.dio.post('/quizzes/$quizId/attempts');
    return LearningQuizAttempt.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<LearningQuizAttempt> submitAttempt({
    required String attemptId,
    required List<LearningQuizAttemptAnswer> answers,
  }) async {
    final response = await _client.dio.post('/quizzes/attempts/$attemptId/submit', data: {
      'answers': answers.map((a) => a.toJson()).toList(),
    });
    return LearningQuizAttempt.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<LearningQuizAttempt> getAttempt(String attemptId) async {
    final response = await _client.dio.get('/quizzes/attempts/$attemptId');
    return LearningQuizAttempt.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<List<LearningQuizAttempt>> history({String? subjectId}) async {
    final response = await _client.dio.get('/quizzes/history', queryParameters: {
      if (subjectId != null && subjectId.isNotEmpty) 'subjectId': subjectId,
    });
    return (response.data['data'] as List<dynamic>)
        .map((e) => LearningQuizAttempt.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
