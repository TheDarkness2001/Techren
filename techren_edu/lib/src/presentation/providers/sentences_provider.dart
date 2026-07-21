import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/sentences_api.dart';
import '../../domain/entities/sentences.dart';
import 'auth_provider.dart';

final sentencesApiProvider = Provider<SentencesApi>((ref) {
  return SentencesApi(ref.watch(dioClientProvider));
});

final studentSentencesTreeProvider = FutureProvider.autoDispose<List<SentenceLevel>>((ref) async {
  return ref.watch(sentencesApiProvider).getStudentLessons();
});

final sentencesLeaderboardProvider = FutureProvider.autoDispose<SentencesLeaderboard>((ref) async {
  return ref.watch(sentencesApiProvider).getLeaderboard();
});
