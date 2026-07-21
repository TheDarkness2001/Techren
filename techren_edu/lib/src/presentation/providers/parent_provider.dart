import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/parent_api.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/parent_portal.dart';
import 'auth_provider.dart';

typedef ParentFeedbackQuery = ({String studentId, int page, String search});
typedef ParentAttendanceQuery = ({String studentId, int page});
typedef ParentExamsQuery = ({String studentId, int page});

final parentApiProvider = Provider<ParentApi>((ref) {
  return ParentApi(ref.watch(dioClientProvider));
});

final parentChildrenProvider = FutureProvider.autoDispose<List<ParentChild>>((ref) async {
  return ref.watch(parentApiProvider).getChildren();
});

final parentChildOverviewProvider = FutureProvider.autoDispose.family<ParentChildOverview, String>((ref, studentId) async {
  return ref.watch(parentApiProvider).getOverview(studentId);
});

final parentChildFeedbackProvider =
    FutureProvider.autoDispose.family<PaginatedResult<ParentFeedbackEntry>, ParentFeedbackQuery>((ref, query) async {
  return ref.watch(parentApiProvider).getFeedback(
        query.studentId,
        page: query.page,
        search: query.search.isEmpty ? null : query.search,
      );
});

final parentChildAttendanceProvider =
    FutureProvider.autoDispose.family<PaginatedResult<ParentAttendanceEntry>, ParentAttendanceQuery>((ref, query) async {
  return ref.watch(parentApiProvider).getAttendance(query.studentId, page: query.page);
});

final parentChildExamsProvider =
    FutureProvider.autoDispose.family<PaginatedResult<ParentExamEntry>, ParentExamsQuery>((ref, query) async {
  return ref.watch(parentApiProvider).getExams(query.studentId, page: query.page);
});

final selectedParentChildIdProvider = StateProvider<String?>((ref) => null);
