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
