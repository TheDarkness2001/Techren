import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/typing_api.dart';
import '../../domain/entities/typing.dart';
import 'auth_provider.dart';

final typingApiProvider = Provider<TypingApi>((ref) {
  return TypingApi(ref.watch(dioClientProvider));
});

final typingDashboardProvider =
    FutureProvider.autoDispose.family<TypingDashboard, String>((ref, subjectId) async {
  return ref.watch(typingApiProvider).getDashboard(subjectId);
});

final typingLeaderboardProvider = FutureProvider.autoDispose
    .family<List<TypingLeaderboardEntry>, ({String subjectId, String period})>((ref, args) async {
  return ref.watch(typingApiProvider).getLeaderboard(subjectId: args.subjectId, period: args.period);
});
