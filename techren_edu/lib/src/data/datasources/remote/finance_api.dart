import '../../../core/network/dio_client.dart';
import '../../../domain/entities/finance.dart';
import '../../../domain/entities/paginated_result.dart';

class FinanceApi {
  FinanceApi(this._client);

  final DioClient _client;

  Future<PaginatedResult<ExamEntry>> getExams({
    int page = 1,
    String search = '',
    bool archived = false,
  }) async {
    final response = await _client.dio.get('/exams', queryParameters: {
      'page': page,
      'limit': 20,
      if (search.isNotEmpty) 'search': search,
      if (archived) 'status': 'archived',
    });
    return _parsePaginated(response.data as Map<String, dynamic>, ExamEntry.fromJson);
  }

  Future<ExamEntry> createExam(Map<String, dynamic> payload) async {
    final response = await _client.dio.post('/exams', data: payload);
    return ExamEntry.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ExamEntry> updateExamResult({
    required String examId,
    required String studentId,
    required int marksObtained,
  }) async {
    final response = await _client.dio.put('/exams/$examId/results/$studentId', data: {
      'marksObtained': marksObtained,
    });
    return ExamEntry.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PaginatedResult<PaymentEntry>> getPayments({int page = 1, String search = ''}) async {
    final response = await _client.dio.get('/payments', queryParameters: {
      'page': page,
      'limit': 20,
      if (search.isNotEmpty) 'search': search,
    });
    return _parsePaginated(response.data as Map<String, dynamic>, PaymentEntry.fromJson);
  }

  Future<PaymentEntry> createPayment(Map<String, dynamic> payload) async {
    final response = await _client.dio.post('/payments', data: payload);
    return PaymentEntry.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PaymentRosterResult> getPaymentRoster({
    required int month,
    required int year,
    String search = '',
  }) async {
    final response = await _client.dio.get('/payments/roster', queryParameters: {
      'month': month,
      'year': year,
      if (search.isNotEmpty) 'search': search,
    });
    final body = response.data as Map<String, dynamic>;
    final items = body['data'] as List<dynamic>? ?? [];
    final meta = body['meta'] as Map<String, dynamic>? ?? {};
    return PaymentRosterResult.fromResponse(items, meta);
  }

  Future<RevenueSummary> getRevenueSummary({String? startDate, String? endDate}) async {
    final response = await _client.dio.get('/revenue/summary', queryParameters: {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    });
    return RevenueSummary.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PendingPaymentsSummary> getPendingPayments() async {
    final response = await _client.dio.get('/revenue/pending');
    return PendingPaymentsSummary.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<RevenueChartData> getRevenueChart({String? startDate, String? endDate}) async {
    final response = await _client.dio.get('/revenue/chart', queryParameters: {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    });
    return RevenueChartData.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<RevenueExportData> getRevenueExport({String? startDate, String? endDate}) async {
    final response = await _client.dio.get('/revenue/export', queryParameters: {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    });
    return RevenueExportData.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  PaginatedResult<T> _parsePaginated<T>(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final meta = data['meta'] as Map<String, dynamic>? ?? {};
    final items = (data['data'] as List<dynamic>).map((e) => fromJson(e as Map<String, dynamic>)).toList();
    return PaginatedResult(
      items: items,
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 20,
      total: meta['total'] as int? ?? items.length,
      totalPages: meta['totalPages'] as int? ?? 1,
    );
  }
}
