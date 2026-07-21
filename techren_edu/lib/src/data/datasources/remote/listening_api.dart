import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../domain/entities/learning_cms.dart';
import '../../../domain/entities/listening.dart';
import '../../../domain/entities/words.dart';

class ListeningApi {
  ListeningApi(this._client);

  final DioClient _client;

  Future<List<ListeningLevel>> getStudentLevels() async {
    final response = await _client.dio.get('/listening/student-levels');
    return (response.data['data'] as List<dynamic>)
        .map((e) => ListeningLevel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ListeningExerciseSummary> getRandomExercise(String levelId) async {
    final response = await _client.dio.get('/listening/random', queryParameters: {'levelId': levelId});
    return ListeningExerciseSummary.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<String> getSignedAudioUrl(String exerciseId) async {
    final response = await _client.dio.get('/listening/exercises/$exerciseId/signed-url');
    final path = response.data['data']['url'] as String;
    final base = Uri.parse(ApiConstants.baseUrl);
    final origin = '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
    return '$origin$path';
  }

  Future<ListeningCheckResult> checkAnswer({
    required String listeningId,
    required String answer,
  }) async {
    final response = await _client.dio.post('/listening/check', data: {
      'listeningId': listeningId,
      'answer': answer,
    });
    return ListeningCheckResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ListeningLeaderboard> getLeaderboard() async {
    final response = await _client.dio.get('/listening/leaderboard');
    return ListeningLeaderboard.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<LearningLanguage>> getCmsLanguages() async {
    final response = await _client.dio.get('/listening/languages');
    return (response.data['data'] as List<dynamic>)
        .map((e) => LearningLanguage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CmsLevel>> getCmsLevels(String languageId) async {
    final response = await _client.dio.get('/homework/levels', queryParameters: {
      'languageId': languageId,
      'moduleType': 'listening',
    });
    return (response.data['data'] as List<dynamic>)
        .map((e) => CmsLevel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CmsListeningExercise>> getLevelExercises(String levelId) async {
    final response = await _client.dio.get('/listening/exercises', queryParameters: {'levelId': levelId});
    return (response.data['data'] as List<dynamic>)
        .map((e) => CmsListeningExercise.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CmsListeningExercise> createExercise({
    required String levelId,
    required String title,
    required String script,
    int order = 1,
    String? audioPath,
    String? audioFileName,
    String? remoteAudioUrl,
  }) async {
    final form = FormData.fromMap({
      'levelId': levelId,
      'title': title,
      'script': script,
      'order': order,
      if (remoteAudioUrl != null) 'audioFile': remoteAudioUrl,
      if (audioPath != null)
        'audio': await MultipartFile.fromFile(audioPath, filename: audioFileName ?? 'audio.mp3'),
    });
    final response = await _client.dio.post('/listening/exercises', data: form);
    return CmsListeningExercise.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<CmsListeningExercise> updateExercise({
    required String id,
    String? title,
    String? script,
    int? order,
    String? audioPath,
    String? audioFileName,
  }) async {
    final form = FormData.fromMap({
      if (title != null) 'title': title,
      if (script != null) 'script': script,
      if (order != null) 'order': order,
      if (audioPath != null)
        'audio': await MultipartFile.fromFile(audioPath, filename: audioFileName ?? 'audio.mp3'),
    });
    final response = await _client.dio.put('/listening/exercises/$id', data: form);
    return CmsListeningExercise.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteExercise(String id) async {
    await _client.dio.delete('/listening/exercises/$id');
  }
}
