import '../../../core/network/dio_client.dart';
import '../../../domain/entities/competition.dart';
import '../../../domain/entities/paginated_result.dart';

class CompetitionApi {
  CompetitionApi(this._client);

  final DioClient _client;

  Future<List<PenaltyRecord>> getStudentPenalties(String studentId, {int? year, int? month}) async {
    final response = await _client.dio.get('/penalties/student/$studentId', queryParameters: {
      if (year != null) 'year': year,
      if (month != null) 'month': month,
    });
    return (response.data['data']['penalties'] as List<dynamic>? ?? [])
        .map((e) => PenaltyRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getStudentPenaltyTotal(String studentId, {int? year, int? month}) async {
    final response = await _client.dio.get('/penalties/student/$studentId', queryParameters: {
      if (year != null) 'year': year,
      if (month != null) 'month': month,
    });
    return response.data['data']['total'] as int? ?? 0;
  }

  Future<List<PresentationRecord>> getStudentPresentations(String studentId, {int? year, int? month}) async {
    final response = await _client.dio.get('/presentations/student/$studentId', queryParameters: {
      if (year != null) 'year': year,
      if (month != null) 'month': month,
    });
    return (response.data['data']['presentations'] as List<dynamic>? ?? [])
        .map((e) => PresentationRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaginatedResult<PenaltyRecord>> getMonthlyPenalties({
    required int year,
    required int month,
    String? branchId,
    int page = 1,
  }) async {
    final response = await _client.dio.get('/penalties/monthly', queryParameters: {
      'year': year,
      'month': month,
      'page': page,
      'limit': 20,
      if (branchId != null) 'branchId': branchId,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    final items = (data['penalties'] as List<dynamic>? ?? [])
        .map((e) => PenaltyRecord.fromJson(e as Map<String, dynamic>))
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

  Future<List<TopPresenter>> getTopPresenters({required int year, required int month, String? branchId}) async {
    final response = await _client.dio.get('/presentations/top', queryParameters: {
      'year': year,
      'month': month,
      if (branchId != null) 'branchId': branchId,
    });
    return (response.data['data']['leaderboard'] as List<dynamic>? ?? [])
        .map((e) => TopPresenter.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BonusPreview> calculateBonuses({required int year, required int month, String? branchId}) async {
    final response = await _client.dio.get('/bonuses/calculate', queryParameters: {
      'year': year,
      'month': month,
      if (branchId != null) 'branchId': branchId,
    });
    return BonusPreview.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<BonusPeriod>> getBonusHistory({String? branchId}) async {
    final response = await _client.dio.get('/bonuses/history', queryParameters: {
      if (branchId != null) 'branchId': branchId,
    });
    return (response.data['data']['periods'] as List<dynamic>? ?? [])
        .map((e) => BonusPeriod.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createPenalty({
    required String studentId,
    required String type,
    required int points,
    String? notes,
  }) async {
    await _client.dio.post('/penalties', data: {
      'studentId': studentId,
      'type': type,
      'points': points,
      if (notes != null) 'notes': notes,
    });
  }

  Future<void> recordPresentation({
    required String studentId,
    required int score,
    String? notes,
  }) async {
    await _client.dio.post('/presentations', data: {
      'studentId': studentId,
      'score': score,
      if (notes != null) 'notes': notes,
    });
  }

  Future<void> distributeBonuses({
    required int year,
    required int month,
    required String firstPlaceStudentId,
    required String secondPlaceStudentId,
  }) async {
    await _client.dio.post('/bonuses/distribute', data: {
      'year': year,
      'month': month,
      'firstPlaceStudentId': firstPlaceStudentId,
      'secondPlaceStudentId': secondPlaceStudentId,
    });
  }

  Future<void> revertPenalty(String id) async {
    await _client.dio.post('/penalties/$id/revert');
  }
}
