import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../domain/entities/learning_subject.dart';
import '../../../domain/entities/paginated_result.dart';

class LearningApi {
  LearningApi(this._client);

  final DioClient _client;

  Future<PaginatedResult<LearningSubjectCard>> getSubjects({
    int page = 1,
    String search = '',
  }) async {
    final response = await _client.dio.get('/learning/subjects', queryParameters: {
      'page': page,
      'limit': 100,
      if (search.isNotEmpty) 'search': search,
    });
    return _parse(response, LearningSubjectCard.fromJson);
  }

  Future<LearningSubjectDashboard> getSubject(String id) async {
    final response = await _client.dio.get('/learning/subjects/$id');
    return LearningSubjectDashboard.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<LearningSubjectCard> createSubject({
    required String name,
    String? code,
    String? description,
    String? icon,
    String? color,
    String? branchId,
    String? profile,
    List<Map<String, dynamic>>? modules,
  }) async {
    final response = await _client.dio.post('/learning/subjects', data: {
      'name': name,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (branchId != null) 'branchId': branchId,
      if (modules != null) 'modules': modules,
      if (profile != null && modules == null) 'modules': _modulesForProfile(profile),
    });
    return LearningSubjectCard.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<LearningSubjectCard> updateSubject({
    required String id,
    String? name,
    String? code,
    String? description,
    String? icon,
    String? color,
    List<Map<String, dynamic>>? modules,
  }) async {
    final response = await _client.dio.put('/learning/subjects/$id', data: {
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (modules != null) 'modules': modules,
    });
    return LearningSubjectCard.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteSubject(String id) async {
    await _client.dio.delete('/learning/subjects/$id');
  }

  List<Map<String, dynamic>> _modulesForProfile(String profile) {
    final list = switch (profile) {
      'programming' => const [
          ('lessons', 'Lessons', 'learning', 'school'),
          ('projects', 'Projects', 'learning', 'folder_special'),
          ('exercises', 'Exercises', 'learning', 'code'),
          ('challenges', 'Challenges', 'learning', 'bolt'),
          ('video', 'Videos', 'learning', 'play_circle'),
          ('quiz', 'Quiz', 'assessment', 'quiz'),
          ('exam', 'Exam', 'assessment', 'emoji_events'),
          ('cms', 'Learning CMS', 'management', 'edit_note'),
          ('progress', 'Student Progress', 'statistics', 'insights'),
        ],
      'stem' => const [
          ('lessons', 'Lessons', 'learning', 'school'),
          ('practice', 'Practice', 'learning', 'calculate'),
          ('examples', 'Worked Examples', 'learning', 'lightbulb'),
          ('video', 'Videos', 'learning', 'play_circle'),
          ('quiz', 'Quiz', 'assessment', 'quiz'),
          ('exam', 'Exam', 'assessment', 'emoji_events'),
          ('cms', 'Learning CMS', 'management', 'edit_note'),
          ('progress', 'Student Progress', 'statistics', 'insights'),
        ],
      _ => const [
          ('words', 'Words', 'learning', 'spellcheck'),
          ('sentences', 'Sentences', 'learning', 'format_quote'),
          ('listening', 'Listening', 'learning', 'headphones'),
          ('video', 'Video Lessons', 'learning', 'play_circle'),
          ('grammar', 'Grammar', 'learning', 'menu_book'),
          ('flashcards', 'Flashcards', 'learning', 'style'),
          ('quiz', 'Quiz', 'assessment', 'quiz'),
          ('exam', 'Exam', 'assessment', 'emoji_events'),
          ('cms', 'Learning CMS', 'management', 'edit_note'),
          ('import', 'Content Import', 'management', 'upload_file'),
          ('progress', 'Student Progress', 'statistics', 'insights'),
        ],
    };
    return list
        .map(
          (m) => {
            'key': m.$1,
            'label': m.$2,
            'category': m.$3,
            'icon': m.$4,
            'audience': (m.$1 == 'cms' || m.$1 == 'import' || m.$1 == 'progress') ? 'staff' : 'all',
            'enabled': true,
          },
        )
        .toList();
  }

  PaginatedResult<T> _parse<T>(
    Response<dynamic> response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final data = response.data as Map<String, dynamic>;
    final items = (data['data'] as List<dynamic>? ?? [])
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = data['meta'] as Map<String, dynamic>? ?? {};
    return PaginatedResult(
      items: items,
      page: meta['page'] as int? ?? 1,
      limit: meta['limit'] as int? ?? 20,
      total: meta['total'] as int? ?? items.length,
      totalPages: meta['totalPages'] as int? ?? 1,
    );
  }
}
