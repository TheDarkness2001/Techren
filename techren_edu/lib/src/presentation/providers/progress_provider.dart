import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/progress_api.dart';
import '../../domain/entities/paginated_result.dart';
import '../../domain/entities/student_progress.dart';
import 'auth_provider.dart';

final progressApiProvider = Provider<ProgressApi>((ref) {
  return ProgressApi(ref.watch(dioClientProvider));
});

final studentProgressOverviewProvider = FutureProvider.autoDispose<ProgressOverview>((ref) async {
  return ref.watch(progressApiProvider).getOverview();
});

typedef AdminStudentsProgressQuery = ({String search, int page});

final adminStudentsProgressProvider =
    FutureProvider.autoDispose.family<PaginatedResult<StudentProgressSummary>, AdminStudentsProgressQuery>((ref, query) async {
  return ref.watch(progressApiProvider).listStudents(
        page: query.page,
        search: query.search.isEmpty ? null : query.search,
      );
});

final groupProgressProvider = FutureProvider.autoDispose.family<GroupProgressReport, String>((ref, groupId) async {
  return ref.watch(progressApiProvider).getGroupProgress(groupId);
});

final staffStudentProgressProvider = FutureProvider.autoDispose.family<ProgressOverview, String>((ref, studentId) async {
  return ref.watch(progressApiProvider).getOverview(studentId: studentId);
});

final studentVocabLessonsProvider = FutureProvider.autoDispose.family<StudentVocabLessonsReport, String>((ref, studentId) async {
  return ref.watch(progressApiProvider).getStudentVocabLessons(studentId);
});
