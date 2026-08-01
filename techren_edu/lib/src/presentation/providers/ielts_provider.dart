import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/ielts_api.dart';
import '../../domain/entities/ielts.dart';
import '../../domain/entities/paginated_result.dart';
import 'auth_provider.dart';

final ieltsApiProvider = Provider<IeltsApi>((ref) {
  return IeltsApi(ref.watch(dioClientProvider));
});

final ieltsExamsProvider =
    FutureProvider.autoDispose.family<List<IeltsExam>, ({String subjectId, String? mode})>((ref, args) async {
  return ref.watch(ieltsApiProvider).listExams(subjectId: args.subjectId, mode: args.mode);
});

final ieltsHistoryProvider =
    FutureProvider.autoDispose.family<PaginatedResult<IeltsAttempt>, String?>((ref, subjectId) async {
  return ref.watch(ieltsApiProvider).history(subjectId: subjectId);
});

final ieltsWritingQueueProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String?>((ref, subjectId) async {
  return ref.watch(ieltsApiProvider).writingQueue(subjectId: subjectId);
});

final ieltsSourcesProvider =
    FutureProvider.autoDispose.family<List<IeltsSource>, String?>((ref, subjectId) async {
  return ref.watch(ieltsApiProvider).listSources(subjectId: subjectId);
});

final ieltsBankProvider = FutureProvider.autoDispose
    .family<List<IeltsBankItem>, ({String? subjectId, String? skill, String? q})>((ref, args) async {
  return ref.watch(ieltsApiProvider).listBank(subjectId: args.subjectId, skill: args.skill, q: args.q);
});

final ieltsStaffAnalyticsProvider =
    FutureProvider.autoDispose.family<IeltsStaffAnalytics, String?>((ref, subjectId) async {
  return ref.watch(ieltsApiProvider).staffAnalytics(subjectId: subjectId);
});

final ieltsStudentAnalyticsProvider = FutureProvider.autoDispose<IeltsStudentAnalytics>((ref) async {
  return ref.watch(ieltsApiProvider).studentAnalytics();
});

final ieltsExamDifficultyProvider =
    FutureProvider.autoDispose.family<List<IeltsQuestionDifficultyRow>, String>((ref, examId) async {
  return ref.watch(ieltsApiProvider).examDifficultyAnalytics(examId);
});
