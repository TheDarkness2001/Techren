import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/homework_api.dart';
import '../../domain/entities/words.dart';
import 'auth_provider.dart';

final homeworkApiProvider = Provider<HomeworkApi>((ref) {
  return HomeworkApi(ref.watch(dioClientProvider));
});

final wordsLanguagesProvider = FutureProvider.autoDispose<List<LearningLanguage>>((ref) async {
  return ref.watch(homeworkApiProvider).getLanguages();
});

final studentWordsTreeProvider = FutureProvider.autoDispose<List<LearningLevel>>((ref) async {
  return ref.watch(homeworkApiProvider).getStudentLessons();
});

final wordsLeaderboardProvider = FutureProvider.autoDispose<WordsLeaderboard>((ref) async {
  return ref.watch(homeworkApiProvider).getLeaderboard();
});
