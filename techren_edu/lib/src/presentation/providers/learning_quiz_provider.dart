import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/learning_quiz_api.dart';
import '../../domain/entities/learning_quiz.dart';
import 'auth_provider.dart';

final learningQuizApiProvider = Provider<LearningQuizApi>((ref) {
  return LearningQuizApi(ref.watch(dioClientProvider));
});

final learningQuizzesProvider =
    FutureProvider.autoDispose.family<List<LearningQuiz>, String>((ref, subjectId) async {
  return ref.watch(learningQuizApiProvider).listQuizzes(subjectId: subjectId);
});

final learningQuizHistoryProvider =
    FutureProvider.autoDispose.family<List<LearningQuizAttempt>, String>((ref, subjectId) async {
  return ref.watch(learningQuizApiProvider).history(subjectId: subjectId);
});
