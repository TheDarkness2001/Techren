import '../../../core/network/dio_client.dart';
import '../../../domain/entities/paginated_result.dart';
import '../../../domain/entities/recycle_bin.dart';

class RecycleBinApi {
  RecycleBinApi(this._client);

  final DioClient _client;

  Future<PaginatedResult<RecycleBinEntry>> listItems({
    String? moduleType,
    String? collectionName,
    int page = 1,
    String? search,
  }) async {
    final response = await _client.dio.get('/admin/recycle-bin', queryParameters: {
      'page': page,
      'limit': 20,
      if (moduleType != null) 'moduleType': moduleType,
      if (collectionName != null) 'collectionName': collectionName,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final items = (response.data['data'] as List<dynamic>? ?? [])
        .map((e) => RecycleBinEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = response.data['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedResult(
      items: items,
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 20,
      total: meta['total'] as int? ?? items.length,
      totalPages: meta['totalPages'] as int? ?? 1,
    );
  }

  Future<RecycleBinSnapshotDetail> getSnapshots(String id) async {
    final response = await _client.dio.get('/admin/recycle-bin/$id/snapshots');
    return RecycleBinSnapshotDetail.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<RecycleBinRestoreResult> restore(String id) async {
    final response = await _client.dio.post('/admin/recycle-bin/$id/restore');
    return RecycleBinRestoreResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<RecycleBinEntry> purge(String id) async {
    final response = await _client.dio.post('/admin/recycle-bin/$id/purge');
    return RecycleBinEntry.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<RecycleBinPurgeAllResult> purgeAll({int olderThanDays = 30, String? moduleType}) async {
    final response = await _client.dio.post('/admin/recycle-bin/purge-all', data: {
      'olderThanDays': olderThanDays,
      if (moduleType != null) 'moduleType': moduleType,
    });
    return RecycleBinPurgeAllResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<RecycleBinEntry> toggleImportant(String id) async {
    final response = await _client.dio.patch('/admin/recycle-bin/$id/toggle-important');
    return RecycleBinEntry.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
