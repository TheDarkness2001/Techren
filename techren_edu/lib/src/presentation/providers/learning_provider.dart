import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/learning_api.dart';
import '../../domain/entities/learning_subject.dart';
import '../../domain/entities/paginated_result.dart';
import 'auth_provider.dart';

final learningApiProvider = Provider<LearningApi>((ref) {
  return LearningApi(ref.watch(dioClientProvider));
});

typedef LearningSubjectsQuery = ({int page, String search});

final learningSubjectsProvider =
    FutureProvider.autoDispose.family<PaginatedResult<LearningSubjectCard>, LearningSubjectsQuery>((ref, query) async {
  return ref.watch(learningApiProvider).getSubjects(page: query.page, search: query.search);
});

final learningSubjectDashboardProvider =
    FutureProvider.autoDispose.family<LearningSubjectDashboard, String>((ref, subjectId) async {
  return ref.watch(learningApiProvider).getSubject(subjectId);
});
