import '../../../core/network/dio_client.dart';
import '../../../domain/entities/paginated_result.dart';
import '../../../domain/entities/wallet.dart';

class WalletApi {
  WalletApi(this._client);

  final DioClient _client;

  Future<WalletBalance> getBalance({String? studentId}) async {
    final response = await _client.dio.get(
      '/wallet/balance',
      queryParameters: studentId != null ? {'studentId': studentId} : null,
    );
    return WalletBalance.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PaginatedResult<WalletTransaction>> getTransactions({
    String? studentId,
    int page = 1,
    String? search,
  }) async {
    final response = await _client.dio.get(
      '/wallet/transactions',
      queryParameters: {
        if (studentId != null) 'studentId': studentId,
        'page': page,
        'limit': 20,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
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

  Future<WalletTopupResult> topup({
    required String studentId,
    required double amountSom,
    String? description,
  }) async {
    final response = await _client.dio.post('/wallet/topup', data: {
      'studentId': studentId,
      'amountSom': amountSom,
      if (description != null) 'description': description,
    });
    return WalletTopupResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<WalletTopupResult> deduct({
    required String studentId,
    required double amountSom,
    String type = 'deduction',
    String? description,
  }) async {
    final response = await _client.dio.post('/wallet/deduct', data: {
      'studentId': studentId,
      'amountSom': amountSom,
      'type': type,
      if (description != null) 'description': description,
    });
    return WalletTopupResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
