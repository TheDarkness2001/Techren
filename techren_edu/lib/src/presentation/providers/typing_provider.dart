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
    .family<
        TypingLeaderboardPage,
        ({String subjectId, String period, int durationSec, double minAccuracy})>((ref, args) async {
  return ref.watch(typingApiProvider).getLeaderboard(
        subjectId: args.subjectId,
        period: args.period,
        durationSec: args.durationSec,
        minAccuracy: args.minAccuracy,
      );
});
