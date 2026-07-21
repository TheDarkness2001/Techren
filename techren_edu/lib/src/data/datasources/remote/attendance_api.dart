import '../../../core/network/dio_client.dart';
import '../../../domain/entities/attendance.dart';
import '../../../domain/entities/paginated_result.dart';

class AttendanceApi {
  AttendanceApi(this._client);

  final DioClient _client;

  Future<TeacherCheckInStatus> getTodayCheckInStatus() async {
    final response = await _client.dio.get('/attendance/today-status');
    final data = response.data['data'];
    if (data == null) return const TeacherCheckInStatus();
    return TeacherCheckInStatus.fromJson(data as Map<String, dynamic>);
  }

  Future<TeacherCheckInStatus> checkIn() async {
    final response = await _client.dio.post('/attendance/check-in', data: {});
    return TeacherCheckInStatus.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<TeacherCheckInStatus> checkOut() async {
    final response = await _client.dio.post('/attendance/check-out', data: {});
    return TeacherCheckInStatus.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<TodayClassSession>> getTodayClasses() async {
    final response = await _client.dio.get('/student-attendance/today-classes');
    return (response.data['data'] as List<dynamic>)
        .map((e) => TodayClassSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TodayClassSession>> getFeedbackClasses({
    String scope = 'today',
    String teacherId = 'all',
    String? date,
  }) async {
    final response = await _client.dio.get('/student-attendance/today-classes', queryParameters: {
      'scope': scope,
      'teacherId': teacherId,
      if (date != null) 'date': date,
    });
    return (response.data['data'] as List<dynamic>)
        .map((e) => TodayClassSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAttendance({
    required String classScheduleId,
    required List<Map<String, String>> records,
    String? date,
  }) async {
    await _client.dio.post('/student-attendance/mark', data: {
      'classScheduleId': classScheduleId,
      'records': records,
      if (date != null) 'date': date,
    });
  }

  Future<List<TeacherRosterRow>> getTeacherRoster({required String date, String role = 'all'}) async {
    final response = await _client.dio.get('/attendance/roster', queryParameters: {
      'date': date,
      if (role != 'all') 'role': role,
    });
    return (response.data['data'] as List<dynamic>)
        .map((e) => TeacherRosterRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TeacherRosterRow> markTeacherAttendance({
    required String teacherId,
    required String date,
    required String dailyStatus,
    String? notes,
  }) async {
    final response = await _client.dio.post('/attendance/roster/mark', data: {
      'teacherId': teacherId,
      'date': date,
      'dailyStatus': dailyStatus,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return TeacherRosterRow.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<FeedbackEntry> submitFeedback({
    required String studentId,
    required String classScheduleId,
    required int homework,
    required int behavior,
    required int participation,
    bool isExamDay = false,
    int? examPercentage,
    String? date,
    String? notes,
  }) async {
    final response = await _client.dio.post('/feedback', data: {
      'studentId': studentId,
      'classScheduleId': classScheduleId,
      'homework': homework,
      'behavior': behavior,
      'participation': participation,
      'isExamDay': isExamDay,
      if (isExamDay && examPercentage != null) 'examPercentage': examPercentage,
      if (date != null) 'date': date,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return FeedbackEntry.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PaginatedResult<FeedbackEntry>> getFeedback({String? studentId, int page = 1, String? search}) async {
    final response = await _client.dio.get('/feedback', queryParameters: {
      'page': page,
      'limit': 20,
      if (studentId != null) 'studentId': studentId,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final items = (response.data['data'] as List<dynamic>? ?? [])
        .map((e) => FeedbackEntry.fromJson(e as Map<String, dynamic>))
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
}
