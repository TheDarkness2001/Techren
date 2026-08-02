import '../../../core/network/dio_client.dart';
import '../../../domain/entities/typing.dart';

class TypingApi {
  TypingApi(this._client);

  final DioClient _client;

  Future<TypingDashboard> getDashboard(String subjectId) async {
    final response = await _client.dio.get(
      '/typing/dashboard',
      queryParameters: {'subjectId': subjectId},
    );
    return TypingDashboard.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<TypingStartPayload> start({
    required String subjectId,
    required String mode,
    required String difficulty,
    required int durationSec,
    bool unlimited = false,
    bool isDaily = false,
  }) async {
    final response = await _client.dio.post('/typing/start', data: {
      'subjectId': subjectId,
      'mode': mode,
      'difficulty': difficulty,
      'durationSec': durationSec,
      'unlimited': unlimited,
      'isDaily': isDaily,
    });
    return TypingStartPayload.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<TypingResultCard> finish({
    required String subjectId,
    required String mode,
    required String difficulty,
    required int durationSec,
    required bool unlimited,
    required bool isDaily,
    required double wpm,
    required double rawWpm,
    required double accuracy,
    required int correctChars,
    required int incorrectChars,
    required int totalChars,
    required int mistakes,
    required int wordsTyped,
    required int correctWords,
    required int wrongWords,
    required int elapsedSec,
    String? contentId,
  }) async {
    final response = await _client.dio.post('/typing/finish', data: {
      'subjectId': subjectId,
      'mode': mode,
      'difficulty': difficulty,
      'durationSec': durationSec,
      'unlimited': unlimited,
      'isDaily': isDaily,
      'wpm': wpm,
      'rawWpm': rawWpm,
      'accuracy': accuracy,
      'correctChars': correctChars,
      'incorrectChars': incorrectChars,
      'totalChars': totalChars,
      'mistakes': mistakes,
      'wordsTyped': wordsTyped,
      'correctWords': correctWords,
      'wrongWords': wrongWords,
      'elapsedSec': elapsedSec,
      if (contentId != null) 'contentId': contentId,
    });
    return TypingResultCard.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<TypingLeaderboardEntry>> getLeaderboard({
    required String subjectId,
    String period = 'all',
  }) async {
    final response = await _client.dio.get(
      '/typing/leaderboard',
      queryParameters: {'subjectId': subjectId, 'period': period},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => TypingLeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getDaily(String subjectId) async {
    final response = await _client.dio.get(
      '/typing/daily',
      queryParameters: {'subjectId': subjectId},
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}
