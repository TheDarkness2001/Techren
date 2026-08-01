import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
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

  Future<IeltsSection> createSection(String examId, Map<String, dynamic> fields, {String? audioPath}) async {
    final form = FormData.fromMap({
      ...fields,
      if (audioPath != null) 'audio': await MultipartFile.fromFile(audioPath),
    });
    final response = await _client.dio.post('/ielts/exams/$examId/sections', data: form);
    return IeltsSection.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<IeltsSection> updateSection(String sectionId, Map<String, dynamic> fields, {String? audioPath}) async {
    final form = FormData.fromMap({
      ...fields,
      if (audioPath != null) 'audio': await MultipartFile.fromFile(audioPath),
    });
    final response = await _client.dio.put('/ielts/sections/$sectionId', data: form);
    return IeltsSection.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteSection(String sectionId) async {
    await _client.dio.delete('/ielts/sections/$sectionId');
  }

  Future<IeltsQuestion> createQuestion(String sectionId, Map<String, dynamic> body) async {
    final response = await _client.dio.post('/ielts/sections/$sectionId/questions', data: body);
    return IeltsQuestion.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<IeltsQuestion> updateQuestion(String questionId, Map<String, dynamic> body) async {
    final response = await _client.dio.put('/ielts/questions/$questionId', data: body);
    return IeltsQuestion.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteQuestion(String questionId) async {
    await _client.dio.delete('/ielts/questions/$questionId');
  }

  Future<String> getSignedAudioUrl(String sectionId) async {
    final response = await _client.dio.get('/ielts/sections/$sectionId/signed-url');
    final path = response.data['data']['url'] as String;
    final base = Uri.parse(ApiConstants.baseUrl);
    final origin = '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
    return path.startsWith('http') ? path : '$origin$path';
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
    String? playedSectionId,
    Map<String, bool>? audioPlayedBySection,
    Map<String, dynamic>? audioAnalytics,
    Map<String, int>? timePerQuestion,
  }) async {
    final response = await _client.dio.patch('/ielts/attempts/$attemptId/autosave', data: {
      if (answers != null) 'answers': answers,
      if (flags != null) 'flags': flags,
      if (writingResponses != null) 'writingResponses': writingResponses,
      if (currentSectionId != null) 'currentSectionId': currentSectionId,
      if (remainingSeconds != null) 'remainingSeconds': remainingSeconds,
      if (audioPlayed != null) 'audioPlayed': audioPlayed,
      if (playedSectionId != null) 'playedSectionId': playedSectionId,
      if (audioPlayedBySection != null) 'audioPlayedBySection': audioPlayedBySection,
      if (audioAnalytics != null) 'audioAnalytics': audioAnalytics,
      if (timePerQuestion != null) 'timePerQuestion': timePerQuestion,
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

  Future<Map<String, dynamic>> bulkAccess({
    required bool enabled,
    List<String>? studentIds,
    String? examGroupId,
    String? classScheduleId,
    bool allEnglish = false,
  }) async {
    final response = await _client.dio.post('/ielts/access/bulk', data: {
      'enabled': enabled,
      if (studentIds != null) 'studentIds': studentIds,
      if (examGroupId != null) 'examGroupId': examGroupId,
      if (classScheduleId != null) 'classScheduleId': classScheduleId,
      if (allEnglish) 'allEnglish': true,
    });
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<PaginatedResult<dynamic>> listAccess({int page = 1, String search = ''}) async {
    final response = await _client.dio.get('/ielts/access', queryParameters: {
      'page': page,
      'limit': 50,
      if (search.isNotEmpty) 'search': search,
    });
    final items = response.data['data'] as List<dynamic>? ?? [];
    final meta = response.data['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedResult(
      items: items,
      page: meta['page'] as int? ?? page,
      limit: meta['limit'] as int? ?? 50,
      total: meta['total'] as int? ?? items.length,
      totalPages: meta['totalPages'] as int? ?? 1,
    );
  }

  // —— Sources (library CMS) ——

  Future<List<IeltsSource>> listSources({String? subjectId, String? kind, String? topic, String? q}) async {
    final response = await _client.dio.get('/ielts/sources', queryParameters: {
      if (subjectId != null && subjectId.isNotEmpty) 'subjectId': subjectId,
      if (kind != null && kind.isNotEmpty) 'kind': kind,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    return (response.data['data'] as List<dynamic>)
        .map((e) => IeltsSource.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<IeltsSource> getSource(String id) async {
    final response = await _client.dio.get('/ielts/sources/$id');
    return IeltsSource.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<IeltsSource> createSource(Map<String, dynamic> body) async {
    final response = await _client.dio.post('/ielts/sources', data: body);
    return IeltsSource.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<IeltsSource> updateSource(String id, Map<String, dynamic> body) async {
    final response = await _client.dio.put('/ielts/sources/$id', data: body);
    return IeltsSource.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<void> deleteSource(String id) async {
    await _client.dio.delete('/ielts/sources/$id');
  }

  Future<Map<String, dynamic>> sourceMeta() async {
    final response = await _client.dio.get('/ielts/sources/meta');
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  // —— Question bank ——

  Future<List<IeltsBankItem>> listBank({
    String? subjectId,
    String? skill,
    String? type,
    String? topic,
    String? status,
    String? q,
  }) async {
    final response = await _client.dio.get('/ielts/bank', queryParameters: {
      if (subjectId != null && subjectId.isNotEmpty) 'subjectId': subjectId,
      if (skill != null && skill.isNotEmpty) 'skill': skill,
      if (type != null && type.isNotEmpty) 'type': type,
      if (topic != null && topic.isNotEmpty) 'topic': topic,
      if (status != null && status.isNotEmpty) 'status': status,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    return (response.data['data'] as List<dynamic>)
        .map((e) => IeltsBankItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<IeltsBankItem> getBankItem(String id) async {
    final response = await _client.dio.get('/ielts/bank/$id');
    return IeltsBankItem.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<IeltsBankItem> createBankItem(Map<String, dynamic> body) async {
    final response = await _client.dio.post('/ielts/bank', data: body);
    return IeltsBankItem.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<IeltsBankItem> updateBankItem(String id, Map<String, dynamic> body) async {
    final response = await _client.dio.put('/ielts/bank/$id', data: body);
    return IeltsBankItem.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<IeltsQuestionBankVersion> publishBankVersion(String id, Map<String, dynamic> body) async {
    final response = await _client.dio.post('/ielts/bank/$id/versions', data: body);
    return IeltsQuestionBankVersion.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<void> deleteBankItem(String id) async {
    await _client.dio.delete('/ielts/bank/$id');
  }

  Future<IeltsQuestion> addBankVersionToSection(String sectionId, String versionId, {Map<String, dynamic>? overrides}) async {
    final response = await _client.dio.post('/ielts/sections/$sectionId/questions/from-bank', data: {
      'versionId': versionId,
      ...(overrides ?? {}),
    });
    return IeltsQuestion.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<IeltsBankItem> importQuestionToBank(String questionId, Map<String, dynamic> body) async {
    final response = await _client.dio.post('/ielts/questions/$questionId/to-bank', data: body);
    return IeltsBankItem.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  // —— Analytics ——

  Future<IeltsStaffAnalytics> staffAnalytics({String? subjectId, String? examId, int days = 90}) async {
    final response = await _client.dio.get('/ielts/analytics/staff', queryParameters: {
      if (subjectId != null && subjectId.isNotEmpty) 'subjectId': subjectId,
      if (examId != null && examId.isNotEmpty) 'examId': examId,
      'days': days,
    });
    return IeltsStaffAnalytics.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<IeltsStudentAnalytics> studentAnalytics({int days = 180}) async {
    final response = await _client.dio.get('/ielts/analytics/me', queryParameters: {'days': days});
    return IeltsStudentAnalytics.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<List<IeltsQuestionDifficultyRow>> examDifficultyAnalytics(String examId) async {
    final response = await _client.dio.get('/ielts/exams/$examId/analytics/difficulty');
    return (response.data['data'] as List<dynamic>)
        .map((e) => IeltsQuestionDifficultyRow.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // —— Ops: duplicate / export / import ——

  Future<IeltsExam> duplicateExam(String examId, {Map<String, dynamic>? overrides}) async {
    final response = await _client.dio.post('/ielts/exams/$examId/duplicate', data: overrides ?? {});
    return IeltsExam.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<IeltsSection> duplicateSection(String sectionId) async {
    final response = await _client.dio.post('/ielts/sections/$sectionId/duplicate');
    return IeltsSection.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }

  Future<Map<String, dynamic>> exportExamJson(String examId) async {
    final response = await _client.dio.get('/ielts/exams/$examId/export');
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<String> exportExamCsv(String examId) async {
    final response = await _client.dio.get(
      '/ielts/exams/$examId/export.csv',
      options: Options(responseType: ResponseType.plain),
    );
    return response.data as String;
  }

  Future<IeltsExam> importExamJson(Map<String, dynamic> body, {String? subjectId}) async {
    final response = await _client.dio.post(
      '/ielts/exams/import',
      data: body,
      queryParameters: {if (subjectId != null && subjectId.isNotEmpty) 'subjectId': subjectId},
    );
    return IeltsExam.fromJson(Map<String, dynamic>.from(response.data['data'] as Map));
  }
}
