import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/scheduling_api.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/scheduling.dart';
import 'auth_provider.dart';

final schedulingApiProvider = Provider<SchedulingApi>((ref) {
  return SchedulingApi(ref.watch(dioClientProvider));
});

final examGroupsProvider = FutureProvider.autoDispose<List<ExamGroup>>((ref) async {
  return ref.watch(schedulingApiProvider).getExamGroups();
});

typedef GroupsQuery = ({int page, String search});

final unifiedGroupsProvider =
    FutureProvider.autoDispose.family<PaginatedResult<UnifiedGroupView>, GroupsQuery>((ref, query) async {
  return ref.watch(schedulingApiProvider).getUnifiedView(
        page: query.page,
        search: query.search.isEmpty ? null : query.search,
      );
});

typedef SchedulesQuery = ({int page, String search});

final schedulesProvider =
    FutureProvider.autoDispose.family<PaginatedResult<ClassSchedule>, SchedulesQuery>((ref, query) async {
  return ref.watch(schedulingApiProvider).getSchedules(
        page: query.page,
        search: query.search.isEmpty ? null : query.search,
      );
});

final timetableProvider = FutureProvider.autoDispose.family<TimetableData, String>((ref, type) async {
  return ref.watch(schedulingApiProvider).getTimetable(type);
});
