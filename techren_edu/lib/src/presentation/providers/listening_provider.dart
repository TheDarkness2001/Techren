import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/listening_api.dart';
import '../../domain/entities/listening.dart';
import 'auth_provider.dart';

final listeningApiProvider = Provider<ListeningApi>((ref) {
  return ListeningApi(ref.watch(dioClientProvider));
});

final studentListeningLevelsProvider = FutureProvider.autoDispose<List<ListeningLevel>>((ref) async {
  return ref.watch(listeningApiProvider).getStudentLevels();
});

final listeningLeaderboardProvider = FutureProvider.autoDispose<ListeningLeaderboard>((ref) async {
  return ref.watch(listeningApiProvider).getLeaderboard();
});
