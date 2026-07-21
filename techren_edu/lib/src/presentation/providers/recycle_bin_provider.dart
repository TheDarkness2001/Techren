import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/recycle_bin_api.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/recycle_bin.dart';
import 'auth_provider.dart';

typedef RecycleBinQuery = ({String? moduleType, int page, String search});

final recycleBinApiProvider = Provider<RecycleBinApi>((ref) {
  return RecycleBinApi(ref.watch(dioClientProvider));
});

final recycleBinItemsProvider =
    FutureProvider.autoDispose.family<PaginatedResult<RecycleBinEntry>, RecycleBinQuery>((ref, query) async {
  return ref.watch(recycleBinApiProvider).listItems(
        moduleType: query.moduleType,
        page: query.page,
        search: query.search.isEmpty ? null : query.search,
      );
});

final recycleBinSnapshotsProvider = FutureProvider.autoDispose.family<RecycleBinSnapshotDetail, String>((ref, id) async {
  return ref.watch(recycleBinApiProvider).getSnapshots(id);
});
