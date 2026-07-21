import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/gamification_api.dart';
import '../../domain/entities/gamification.dart';
import 'auth_provider.dart';

final gamificationApiProvider = Provider<GamificationApi>((ref) {
  return GamificationApi(ref.watch(dioClientProvider));
});

final gamificationProfileProvider = FutureProvider.autoDispose<GamificationProfile>((ref) async {
  return ref.watch(gamificationApiProvider).getProfile();
});

final achievementsProvider = FutureProvider.autoDispose<List<AchievementEntry>>((ref) async {
  return ref.watch(gamificationApiProvider).getAchievements();
});

final xpLeaderboardProvider = FutureProvider.autoDispose<List<XpLeaderboardEntry>>((ref) async {
  return ref.watch(gamificationApiProvider).getLeaderboard();
});

final practiceRecommendationProvider = FutureProvider.autoDispose<PracticeRecommendation>((ref) async {
  return ref.watch(gamificationApiProvider).getRecommendations();
});
