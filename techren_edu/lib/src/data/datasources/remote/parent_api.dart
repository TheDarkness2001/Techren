import '../../../core/network/dio_client.dart';
import '../../../domain/entities/paginated_result.dart';
import '../../../domain/entities/parent_portal.dart';
import '../../../domain/entities/scheduling.dart';

class ParentApi {
  ParentApi(this._client);

  final DioClient _client;

  Future<List<ParentChild>> getChildren() async {
    final response = await _client.dio.get('/parent/children');
    return (response.data['data']['children'] as List<dynamic>? ?? [])
        .map((e) => ParentChild.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ParentChildOverview> getOverview(String studentId) async {
    final response = await _client.dio.get('/parent/children/$studentId/overview');
    return ParentChildOverview.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ParentPaymentsPage> getPayments(String studentId, {int? month, int? year}) async {
    final response = await _client.dio.get('/parent/children/$studentId/payments', queryParameters: {
      if (month != null) 'month': month,
      if (year != null) 'year': year,
    });
    return ParentPaymentsPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<ParentAlert>> getAlerts(String studentId) async {
    final response = await _client.dio.get('/parent/children/$studentId/alerts');
    return (response.data['data']['alerts'] as List<dynamic>? ?? [])
        .map((e) => ParentAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> submitAbsenceExcuse(String studentId, String attendanceId, String reason) async {
    await _client.dio.post(
      '/parent/children/$studentId/attendance/$attendanceId/excuse',
      data: {'reason': reason},
    );
  }

  Future<PaginatedResult<ParentFeedbackEntry>> getFeedback(String studentId, {int page = 1, String? search}) async {
    final response = await _client.dio.get('/parent/children/$studentId/feedback', queryParameters: {
      'page': page,
      'limit': 20,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['feedback'] as List<dynamic>? ?? [])
        .map((e) => ParentFeedbackEntry.fromJson(e as Map<String, dynamic>))
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

  Future<PaginatedResult<ParentAttendanceEntry>> getAttendance(String studentId, {int page = 1}) async {
    final response = await _client.dio.get('/parent/children/$studentId/attendance', queryParameters: {
      'page': page,
      'limit': 20,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['attendance'] as List<dynamic>? ?? [])
        .map((e) => ParentAttendanceEntry.fromJson(e as Map<String, dynamic>))
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

  Future<PaginatedResult<ParentExamEntry>> getExams(String studentId, {int page = 1}) async {
    final response = await _client.dio.get('/parent/children/$studentId/exams', queryParameters: {
      'page': page,
      'limit': 20,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['exams'] as List<dynamic>? ?? [])
        .map((e) => ParentExamEntry.fromJson(e as Map<String, dynamic>))
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

  Future<ParentHomeworkProgress> getHomework(String studentId) async {
    final response = await _client.dio.get('/parent/children/$studentId/homework');
    return ParentHomeworkProgress.fromJson(response.data['data'] as Map<String, dynamic>? ?? {});
  }

  Future<TimetableData> getSchedule(String studentId) async {
    final response = await _client.dio.get('/parent/children/$studentId/schedule');
    return TimetableData.fromJson(response.data['data'] as Map<String, dynamic>? ?? {});
  }

  Future<void> addParentComment(String feedbackId, String comment) async {
    await _client.dio.put('/feedback/$feedbackId/parent-comment', data: {'comment': comment});
  }
}
