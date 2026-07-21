import '../../../core/network/dio_client.dart';
import '../../../domain/entities/paginated_result.dart';
import '../../../domain/entities/scheduling.dart';

class SchedulingApi {
  SchedulingApi(this._client);

  final DioClient _client;

  Future<PaginatedResult<UnifiedGroupView>> getUnifiedView({int page = 1, String? search}) async {
    final response = await _client.dio.get('/exam-groups/unified-view', queryParameters: {
      'page': page,
      'limit': 20,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final data = response.data as Map<String, dynamic>;
    final meta = data['meta'] as Map<String, dynamic>? ?? {};
    final items = (data['data'] as List<dynamic>? ?? [])
        .map((e) => UnifiedGroupView.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      items: items,
      page: meta['page'] as int? ?? page,
      limit: meta['limit'] as int? ?? 20,
      total: meta['total'] as int? ?? items.length,
      totalPages: meta['totalPages'] as int? ?? 1,
    );
  }

  Future<PaginatedResult<ClassSchedule>> getSchedules({int page = 1, String? search}) async {
    final response = await _client.dio.get('/class-schedules', queryParameters: {
      'page': page,
      'limit': 20,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final data = response.data as Map<String, dynamic>;
    final meta = data['meta'] as Map<String, dynamic>? ?? {};
    final items = (data['data'] as List<dynamic>)
        .map((e) => ClassSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      items: items,
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 20,
      total: meta['total'] as int? ?? items.length,
      totalPages: meta['totalPages'] as int? ?? 1,
    );
  }

  Future<TimetableData> getTimetable(String type) async {
    final response = await _client.dio.get('/timetable/$type');
    return TimetableData.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<ExamGroup>> getExamGroups() async {
    final response = await _client.dio.get('/exam-groups', queryParameters: {'limit': 100});
    return (response.data['data'] as List<dynamic>)
        .map((e) => ExamGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UnifiedGroupView> createUnified({
    required String subjectName,
    required String groupName,
    required String teacherId,
    required List<String> scheduledDays,
    required String startTime,
    required String endTime,
    List<String>? studentIds,
    String? subjectCode,
    num? pricePerClass,
  }) async {
    final response = await _client.dio.post('/exam-groups/unified', data: {
      'subject': {
        'name': subjectName,
        if (subjectCode != null) 'code': subjectCode,
        if (pricePerClass != null) 'pricePerClass': pricePerClass,
      },
      'group': {
        'groupName': groupName,
        if (studentIds != null) 'studentIds': studentIds,
        'teacherIds': [teacherId],
      },
      'schedule': {
        'className': groupName,
        'teacherId': teacherId,
        'scheduledDays': scheduledDays,
        'startTime': startTime,
        'endTime': endTime,
      },
    });
    final data = response.data['data'] as Map<String, dynamic>;
    return UnifiedGroupView(
      group: ExamGroup.fromJson(data['group'] as Map<String, dynamic>),
      schedule: data['schedule'] != null
          ? ClassSchedule.fromJson(data['schedule'] as Map<String, dynamic>)
          : null,
    );
  }

  Future<ExamGroup> updateGroup({
    required String groupId,
    String? groupName,
    List<String>? studentIds,
    List<String>? teacherIds,
  }) async {
    final response = await _client.dio.put('/exam-groups/$groupId', data: {
      if (groupName != null) 'groupName': groupName,
      if (studentIds != null) 'studentIds': studentIds,
      if (teacherIds != null) 'teacherIds': teacherIds,
    });
    return ExamGroup.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ClassSchedule> updateSchedule({
    required String scheduleId,
    String? teacherId,
    List<String>? scheduledDays,
    String? startTime,
    String? endTime,
    String? className,
  }) async {
    final response = await _client.dio.put('/class-schedules/$scheduleId', data: {
      if (teacherId != null) 'teacher': teacherId,
      if (scheduledDays != null) 'scheduledDays': scheduledDays,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (className != null) 'className': className,
    });
    return ClassSchedule.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
