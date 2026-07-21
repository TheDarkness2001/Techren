import '../../../core/network/dio_client.dart';
import '../../../domain/entities/gamification.dart';

class GamificationApi {
  GamificationApi(this._client);

  final DioClient _client;

  Future<GamificationProfile> getProfile({String? studentId}) async {
    final response = await _client.dio.get('/gamification/profile', queryParameters: {
      if (studentId != null) 'studentId': studentId,
    });
    return GamificationProfile.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<AchievementEntry>> getAchievements({String? studentId}) async {
    final response = await _client.dio.get('/gamification/achievements', queryParameters: {
      if (studentId != null) 'studentId': studentId,
    });
    return (response.data['data']['achievements'] as List<dynamic>? ?? [])
        .map((e) => AchievementEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<XpLeaderboardEntry>> getLeaderboard({int limit = 50}) async {
    final response = await _client.dio.get('/gamification/leaderboard', queryParameters: {'limit': limit});
    return (response.data['data']['leaderboard'] as List<dynamic>? ?? [])
        .map((e) => XpLeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PracticeRecommendation> getRecommendations({String? studentId}) async {
    final response = await _client.dio.get('/gamification/recommendations', queryParameters: {
      if (studentId != null) 'studentId': studentId,
    });
    return PracticeRecommendation.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
