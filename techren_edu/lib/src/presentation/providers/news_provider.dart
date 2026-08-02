import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/news_api.dart';
import '../../domain/entities/news.dart';
import 'auth_provider.dart';

final newsApiProvider = Provider<NewsApi>((ref) {
  return NewsApi(ref.watch(dioClientProvider));
});

final newsFeedProvider = FutureProvider.autoDispose<NewsFeedPage>((ref) async {
  return ref.watch(newsApiProvider).getFeed();
});

final newsAdminProvider =
    FutureProvider.autoDispose.family<List<NewsPost>, String>((ref, status) async {
  return ref.watch(newsApiProvider).listAdmin(status: status.isEmpty ? null : status);
});

final newsCategoriesProvider = FutureProvider.autoDispose<List<NewsCategory>>((ref) async {
  return ref.watch(newsApiProvider).categories();
});

final newsCommentsProvider =
    FutureProvider.autoDispose.family<List<NewsComment>, String>((ref, postId) async {
  return ref.watch(newsApiProvider).comments(postId);
});
