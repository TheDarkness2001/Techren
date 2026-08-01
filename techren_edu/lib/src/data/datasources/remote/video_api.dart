import '../../../core/network/dio_client.dart';
import '../../../domain/entities/video.dart';

class VideoTreeLevel {
  const VideoTreeLevel({
    required this.id,
    required this.name,
    required this.languageId,
    required this.classesCount,
  });

  final String id;
  final String name;
  final String languageId;
  final int classesCount;

  factory VideoTreeLevel.fromJson(Map<String, dynamic> json) => VideoTreeLevel(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        languageId: json['languageId']?.toString() ?? '',
        classesCount: (json['classesCount'] as num?)?.toInt() ?? 11,
      );
}

class VideoSubjectTree {
  const VideoSubjectTree({
    required this.languageId,
    required this.languageName,
    required this.subjectId,
    required this.subjectName,
    required this.levels,
  });

  final String languageId;
  final String languageName;
  final String subjectId;
  final String subjectName;
  final List<VideoTreeLevel> levels;

  factory VideoSubjectTree.fromJson(Map<String, dynamic> json) {
    final language = json['language'] is Map
        ? Map<String, dynamic>.from(json['language'] as Map)
        : <String, dynamic>{};
    return VideoSubjectTree(
      languageId: language['id']?.toString() ?? '',
      languageName: language['name'] as String? ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      levels: (json['levels'] as List<dynamic>? ?? [])
          .map((e) => VideoTreeLevel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class VideoApi {
  VideoApi(this._client);

  final DioClient _client;

  Future<List<VideoLessonSummary>> listVideos({
    String? languageId,
    String? levelId,
    String? subjectId,
  }) async {
    final response = await _client.dio.get('/video-lessons', queryParameters: {
      if (languageId != null && languageId.isNotEmpty) 'languageId': languageId,
      if (levelId != null && levelId.isNotEmpty) 'levelId': levelId,
      if (subjectId != null && subjectId.isNotEmpty) 'subjectId': subjectId,
    });
    final data = response.data['data'];
    final list = data is Map
        ? (data['videoLessons'] as List<dynamic>? ?? [])
        : (data as List<dynamic>? ?? []);
    return list.map((e) => VideoLessonSummary.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<VideoSubjectTree> ensureTree(String subjectId) async {
    final response = await _client.dio.get('/video-lessons/tree', queryParameters: {
      'subjectId': subjectId,
    });
    return VideoSubjectTree.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<VideoTreeLevel> createLevel({
    required String subjectId,
    required String name,
    int classesCount = 11,
  }) async {
    final response = await _client.dio.post('/video-lessons/levels', data: {
      'subjectId': subjectId,
      'name': name,
      'classesCount': classesCount,
    });
    return VideoTreeLevel.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<VideoLessonSummary> createVideo(Map<String, dynamic> body) async {
    final response = await _client.dio.post('/video-lessons', data: body);
    final data = response.data['data'];
    final map = data is Map && data['videoLesson'] != null
        ? Map<String, dynamic>.from(data['videoLesson'] as Map)
        : Map<String, dynamic>.from(data as Map);
    return VideoLessonSummary.fromJson(map);
  }

  Future<VideoLessonSummary> updateVideo(String id, Map<String, dynamic> body) async {
    final response = await _client.dio.put('/video-lessons/$id', data: body);
    final data = response.data['data'];
    final map = data is Map && data['videoLesson'] != null
        ? Map<String, dynamic>.from(data['videoLesson'] as Map)
        : Map<String, dynamic>.from(data as Map);
    return VideoLessonSummary.fromJson(map);
  }

  Future<void> deleteVideo(String id) async {
    await _client.dio.delete('/video-lessons/$id');
  }

  Future<VideoLessonSummary> toggleWatchUnlock({
    required String videoId,
    required String groupId,
    required bool unlock,
  }) async {
    final response = await _client.dio.patch('/video-lessons/$videoId/toggle-watch-unlock', data: {
      'groupId': groupId,
      'unlock': unlock,
    });
    final data = response.data['data'];
    final video = data is Map ? data['video'] : null;
    return VideoLessonSummary.fromJson(Map<String, dynamic>.from(video as Map));
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
