import '../../../core/network/dio_client.dart';
import '../../../domain/entities/ielts.dart';
import '../../../domain/entities/paginated_result.dart';

class IeltsApi {
  IeltsApi(this._client);

  final DioClient _client;

  Future<List<IeltsExam>> listExams({required String subjectId, String? mode}) async {
    final response = await _client.dio.get('/ielts/exams', queryParameters: {
      'subjectId': subjectId,
      if (mode != null && mode.isNotEmpty) 'mode': mode,
    });
    return (response.data['data'] as List<dynamic>)
        .map((e) => IeltsExam.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<IeltsExam> getExam(String id) async {
    final response = await _client.dio.get('/ielts/exams/$id');
    return IeltsExam.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<IeltsExam> createExam(Map<String, dynamic> body) async {
    final response = await _client.dio.post('/ielts/exams', data: body);
    return IeltsExam.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<IeltsExam> updateExam(String id, Map<String, dynamic> body) async {
    final response = await _client.dio.put('/ielts/exams/$id', data: body);
    return IeltsExam.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteExam(String id) async {
    await _client.dio.delete('/ielts/exams/$id');
  }

  Future<IeltsAttemptBundle> startAttempt(String examId) async {
    final response = await _client.dio.post('/ielts/exams/$examId/attempts');
    return IeltsAttemptBundle.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<IeltsAttemptBundle> getAttempt(String attemptId) async {
    final response = await _client.dio.get('/ielts/attempts/$attemptId');
    return IeltsAttemptBundle.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<IeltsAttempt> autosave(
    String attemptId, {
    Map<String, dynamic>? answers,
    Map<String, bool>? flags,
    Map<String, String>? writingResponses,
    String? currentSectionId,
    int? remainingSeconds,
    bool? audioPlayed,
  }) async {
    final response = await _client.dio.patch('/ielts/attempts/$attemptId/autosave', data: {
      if (answers != null) 'answers': answers,
      if (flags != null) 'flags': flags,
      if (writingResponses != null) 'writingResponses': writingResponses,
      if (currentSectionId != null) 'currentSectionId': currentSectionId,
      if (remainingSeconds != null) 'remainingSeconds': remainingSeconds,
      if (audioPlayed != null) 'audioPlayed': audioPlayed,
    });
    return IeltsAttempt.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<IeltsAttemptBundle> submitAttempt(String attemptId) async {
    final response = await _client.dio.post('/ielts/attempts/$attemptId/submit');
    return IeltsAttemptBundle.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PaginatedResult<IeltsAttempt>> history({String? subjectId, int page = 1}) async {
    final response = await _client.dio.get('/ielts/attempts/history', queryParameters: {
      if (subjectId != null) 'subjectId': subjectId,
      'page': page,
      'limit': 20,
    });
    final items = (response.data['data'] as List<dynamic>)
        .map((e) => IeltsAttempt.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = response.data['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedResult(
      items: items,
      page: meta['page'] as int? ?? page,
      limit: meta['limit'] as int? ?? 20,
      total: meta['total'] as int? ?? items.length,
      totalPages: meta['totalPages'] as int? ?? 1,
    );
  }

  Future<List<Map<String, dynamic>>> writingQueue({String? subjectId}) async {
    final response = await _client.dio.get('/ielts/writing-queue', queryParameters: {
      if (subjectId != null) 'subjectId': subjectId,
    });
    return (response.data['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> submitWritingReview(
    String attemptId, {
    required double taskAchievement,
    required double coherenceCohesion,
    required double lexicalResource,
    required double grammaticalRange,
    String comments = '',
    String corrections = '',
  }) async {
    final response = await _client.dio.put('/ielts/attempts/$attemptId/writing-review', data: {
      'taskAchievement': taskAchievement,
      'coherenceCohesion': coherenceCohesion,
      'lexicalResource': lexicalResource,
      'grammaticalRange': grammaticalRange,
      'comments': comments,
      'corrections': corrections,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> setStudentAccess(String studentId, bool enabled) async {
    await _client.dio.patch('/ielts/access/$studentId', data: {'enabled': enabled});
  }

  Future<void> bulkAccess({
    required bool enabled,
    List<String>? studentIds,
    String? examGroupId,
    String? classScheduleId,
    bool allEnglish = false,
  }) async {
    await _client.dio.post('/ielts/access/bulk', data: {
      'enabled': enabled,
      if (studentIds != null) 'studentIds': studentIds,
      if (examGroupId != null) 'examGroupId': examGroupId,
      if (classScheduleId != null) 'classScheduleId': classScheduleId,
      if (allEnglish) 'allEnglish': true,
    });
  }

  String sectionAudioUrl(String sectionId) => '/ielts/sections/$sectionId/audio';
}
