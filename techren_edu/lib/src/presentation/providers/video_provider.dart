import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/video_api.dart';
import '../../domain/entities/video.dart';
import 'auth_provider.dart';

final videoApiProvider = Provider<VideoApi>((ref) => VideoApi(ref.watch(dioClientProvider)));

final studentVideosProvider = FutureProvider.autoDispose<List<VideoLessonSummary>>((ref) async {
  return ref.watch(videoApiProvider).listVideos();
});

final videoDetailProvider = FutureProvider.autoDispose.family<VideoLessonDetail, String>((ref, id) async {
  return ref.watch(videoApiProvider).getVideo(id);
});

final videoTestLeaderboardProvider = FutureProvider.autoDispose.family<List<VideoTestLeaderboardEntry>, String>((ref, videoId) async {
  return ref.watch(videoApiProvider).getLeaderboard(videoId);
});
