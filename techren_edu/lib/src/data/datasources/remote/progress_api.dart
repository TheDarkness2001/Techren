import '../../../core/network/dio_client.dart';
import '../../../domain/entities/paginated_result.dart';
import '../../../domain/entities/student_progress.dart';

class ProgressApi {
  ProgressApi(this._client);

  final DioClient _client;

  Future<ProgressOverview> getOverview({String? studentId}) async {
    final response = await _client.dio.get(
      '/progress/overview',
      queryParameters: studentId != null ? {'studentId': studentId} : null,
    );
    return ProgressOverview.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PaginatedResult<StudentProgressSummary>> listStudents({
    int page = 1,
    String? search,
    String? status,
  }) async {
    final response = await _client.dio.get('/progress/students', queryParameters: {
      'page': page,
      'limit': 20,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => StudentProgressSummary.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = data['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedResult(
      items: items,
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 20,
      total: meta['total'] as int? ?? items.length,
      totalPages: meta['totalPages'] as int? ?? 1,
    );
  }

  Future<GroupProgressReport> getGroupProgress(String groupId) async {
    final response = await _client.dio.get('/progress/groups/$groupId');
    return GroupProgressReport.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<GroupProgressReport>> getMyGroupsProgress() async {
    final response = await _client.dio.get('/progress/my-groups');
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return (data['items'] as List<dynamic>? ?? [])
        .map((e) => GroupProgressReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GroupLessonProgressReport> getGroupLessonProgress({
    required String groupId,
    required String lessonId,
  }) async {
    final response = await _client.dio.get('/progress/groups/$groupId/lessons/$lessonId');
    return GroupLessonProgressReport.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<ProgressLessonOption>> getLessonOptions({String? subject}) async {
    final response = await _client.dio.get('/progress/lesson-options', queryParameters: {
      if (subject != null && subject.trim().isNotEmpty) 'subject': subject.trim(),
    });
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return (data['items'] as List<dynamic>? ?? [])
        .map((e) => ProgressLessonOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StudentVocabLessonsReport> getStudentVocabLessons(String studentId) async {
    final response = await _client.dio.get('/progress/students/$studentId/vocab-lessons');
    return StudentVocabLessonsReport.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
