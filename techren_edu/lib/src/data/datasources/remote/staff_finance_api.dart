import '../../../core/network/dio_client.dart';
import '../../../domain/entities/paginated_result.dart';
import '../../../domain/entities/staff_finance.dart';

class StaffFinanceApi {
  StaffFinanceApi(this._client);

  final DioClient _client;

  Future<PaginatedResult<StaffEarningEntry>> getEarnings({
    String? staffId,
    String? status,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final response = await _client.dio.get('/staff-earnings', queryParameters: {
      if (staffId != null) 'staffId': staffId,
      if (status != null) 'status': status,
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['earnings'] as List<dynamic>? ?? [])
        .map((e) => StaffEarningEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = response.data['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedResult(
      items: items,
      page: meta['page'] as int? ?? page,
      limit: meta['limit'] as int? ?? limit,
      total: meta['total'] as int? ?? items.length,
      totalPages: meta['totalPages'] as int? ?? 1,
    );
  }

  Future<StaffAccountSummary> getAccount({String? staffId}) async {
    final response = await _client.dio.get('/staff-earnings/account', queryParameters: {
      if (staffId != null) 'staffId': staffId,
    });
    return StaffAccountSummary.fromJson(response.data['data']['account'] as Map<String, dynamic>);
  }

  Future<StaffEarningEntry> approveEarning(String id) async {
    final response = await _client.dio.patch('/staff-earnings/$id/approve');
    return StaffEarningEntry.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<StaffEarningEntry> addBonus({
    required String staffId,
    required int amount,
    required String reason,
  }) async {
    final response = await _client.dio.post('/staff-earnings/$staffId/bonus', data: {
      'amount': amount,
      'reason': reason,
    });
    return StaffEarningEntry.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PaginatedResult<StaffPayoutEntry>> getPayouts({
    String? staffId,
    String? status,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final response = await _client.dio.get('/staff-payouts', queryParameters: {
      if (staffId != null) 'staffId': staffId,
      if (status != null) 'status': status,
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['payouts'] as List<dynamic>? ?? [])
        .map((e) => StaffPayoutEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = response.data['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedResult(
      items: items,
      page: meta['page'] as int? ?? page,
      limit: meta['limit'] as int? ?? limit,
      total: meta['total'] as int? ?? items.length,
      totalPages: meta['totalPages'] as int? ?? 1,
    );
  }

  Future<StaffPayoutPreview> previewPayout({
    required String staffId,
    required List<String> earningIds,
  }) async {
    final response = await _client.dio.get('/staff-payouts/preview', queryParameters: {
      'staffId': staffId,
      'earningIds': earningIds.join(','),
    });
    return StaffPayoutPreview.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<StaffPayoutEntry> createPayout({
    required String staffId,
    required List<String> earningIds,
    required String method,
    String? notes,
  }) async {
    final response = await _client.dio.post('/staff-payouts', data: {
      'staffId': staffId,
      'earningIds': earningIds,
      'method': method,
      if (notes != null) 'notes': notes,
    });
    return StaffPayoutEntry.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<StaffPayoutEntry> completePayout(String id) async {
    final response = await _client.dio.patch('/staff-payouts/$id/complete');
    return StaffPayoutEntry.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<StaffPayoutEntry> cancelPayout(String id, String reason) async {
    final response = await _client.dio.patch('/staff-payouts/$id/cancel', data: {'reason': reason});
    return StaffPayoutEntry.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
