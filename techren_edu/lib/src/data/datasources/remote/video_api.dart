import '../../../core/network/dio_client.dart';
import '../../../domain/entities/video.dart';

class VideoApi {
  VideoApi(this._client);

  final DioClient _client;

  Future<List<VideoLessonSummary>> listVideos() async {
    final response = await _client.dio.get('/video-lessons');
    final data = response.data['data'] as Map<String, dynamic>;
    return (data['videoLessons'] as List<dynamic>? ?? [])
        .map((e) => VideoLessonSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VideoLessonDetail> getVideo(String id) async {
    final response = await _client.dio.get('/video-lessons/$id');
    return VideoLessonDetail.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<VideoProgress> trackProgress(String id, {
    required int watchPercent,
    int lastTimestamp = 0,
    int delta = 0,
    bool newSession = false,
  }) async {
    final response = await _client.dio.post('/video-lessons/$id/track', data: {
      'watchPercent': watchPercent,
      'lastTimestamp': lastTimestamp,
      'delta': delta,
      'newSession': newSession,
    });
    return VideoProgress.fromJson(response.data['data']['progress'] as Map<String, dynamic>);
  }

  Future<VideoTopicTest?> getTest(String videoId, {String? mode}) async {
    final response = await _client.dio.get(
      '/video-lessons/$videoId/test',
      queryParameters: mode != null ? {'mode': mode} : null,
    );
    final test = response.data['data']['test'];
    if (test == null) return null;
    return VideoTopicTest.fromJson(test as Map<String, dynamic>);
  }

  Future<VideoTestAttemptResult> submitAttempt(
    String videoId, {
    required String mode,
    required List<Map<String, dynamic>> answers,
    int warnings = 0,
    bool terminated = false,
  }) async {
    final response = await _client.dio.post('/video-lessons/$videoId/test/attempt', data: {
      'mode': mode,
      'answers': answers,
      'warnings': warnings,
      'terminated': terminated,
    });
    return VideoTestAttemptResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<bool> recordWarning(String videoId, int warnings) async {
    final response = await _client.dio.post('/video-lessons/$videoId/test/warning', data: {'warnings': warnings});
    return response.data['data']['terminate'] as bool? ?? false;
  }

  Future<List<VideoTestLeaderboardEntry>> getLeaderboard(String videoId) async {
    final response = await _client.dio.get('/video-lessons/$videoId/test/leaderboard');
    return (response.data['data']['leaderboard'] as List<dynamic>? ?? [])
        .map((e) => VideoTestLeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
