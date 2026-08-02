import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../domain/entities/news.dart';

class NewsApi {
  NewsApi(this._client);

  final DioClient _client;

  Future<NewsFeedPage> getFeed({String? cursor, String? category, String? type, String? q}) async {
    final response = await _client.dio.get('/news/feed', queryParameters: {
      if (cursor != null) 'cursor': cursor,
      if (category != null && category.isNotEmpty) 'category': category,
      if (type != null && type.isNotEmpty) 'type': type,
      if (q != null && q.isNotEmpty) 'q': q,
    });
    return NewsFeedPage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<NewsPost>> listAdmin({String? status}) async {
    final response = await _client.dio.get('/news/admin', queryParameters: {
      if (status != null && status.isNotEmpty) 'status': status,
    });
    return (response.data['data'] as List<dynamic>? ?? [])
        .map((e) => NewsPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<NewsCategory>> categories() async {
    final response = await _client.dio.get('/news/categories');
    return (response.data['data'] as List<dynamic>? ?? [])
        .map((e) => NewsCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NewsPost> getPost(String id) async {
    final response = await _client.dio.get('/news/$id');
    return NewsPost.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<NewsPost> createPost(Map<String, dynamic> body) async {
    final response = await _client.dio.post('/news', data: body);
    return NewsPost.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<NewsPost> updatePost(String id, Map<String, dynamic> body) async {
    final response = await _client.dio.put('/news/$id', data: body);
    return NewsPost.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deletePost(String id) async {
    await _client.dio.delete('/news/$id');
  }

  Future<NewsPost> publish(String id) async {
    final response = await _client.dio.post('/news/$id/publish');
    return NewsPost.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<NewsPost> unpublish(String id) async {
    final response = await _client.dio.post('/news/$id/unpublish');
    return NewsPost.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<NewsPost> pin(String id, {bool pinned = true}) async {
    final response = await _client.dio.post('/news/$id/pin', data: {'pinned': pinned});
    return NewsPost.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<NewsPost> archive(String id) async {
    final response = await _client.dio.post('/news/$id/archive');
    return NewsPost.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<NewsPost> duplicate(String id) async {
    final response = await _client.dio.post('/news/$id/duplicate');
    return NewsPost.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<NewsPost> react(String id, String emoji) async {
    final response = await _client.dio.post('/news/$id/react', data: {'emoji': emoji});
    return NewsPost.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<NewsPost> unreact(String id) async {
    final response = await _client.dio.delete('/news/$id/react');
    return NewsPost.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<NewsComment>> comments(String id) async {
    final response = await _client.dio.get('/news/$id/comments');
    return (response.data['data'] as List<dynamic>? ?? [])
        .map((e) => NewsComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<NewsComment> addComment(String id, String body, {String? parentId}) async {
    final response = await _client.dio.post('/news/$id/comments', data: {
      'body': body,
      if (parentId != null) 'parentId': parentId,
    });
    return NewsComment.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> recordView(String id) async {
    await _client.dio.post('/news/$id/view');
  }

  Future<void> recordClick(String id) async {
    await _client.dio.post('/news/$id/click');
  }

  Future<NewsLink> fetchLinkPreview(String url) async {
    final response = await _client.dio.post('/news/link-preview', data: {'url': url});
    return NewsLink.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<NewsPost> registerForEvent(String id) async {
    final response = await _client.dio.post('/news/$id/register');
    return NewsPost.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<NewsMedia> upload(String filePath, {String? fileName}) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final response = await _client.dio.post('/news/upload', data: form);
    return NewsMedia.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<NewsPoll> vote(String pollId, List<String> optionIds) async {
    final response = await _client.dio.post('/polls/$pollId/vote', data: {
      'optionIds': optionIds,
    });
    return NewsPoll.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<NewsPoll> pollResults(String pollId) async {
    final response = await _client.dio.get('/polls/$pollId/results');
    return NewsPoll.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<String> exportPollCsv(String pollId) async {
    final response = await _client.dio.get(
      '/polls/$pollId/export.csv',
      options: Options(responseType: ResponseType.plain),
    );
    return response.data?.toString() ?? '';
  }
}
