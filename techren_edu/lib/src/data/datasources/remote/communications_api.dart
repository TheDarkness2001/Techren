import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../domain/entities/communication.dart';

class CommunicationsApi {
  CommunicationsApi(this._client);

  final DioClient _client;

  Future<List<Conversation>> listConversations({String? type, bool? archived}) async {
    final response = await _client.dio.get('/communications/conversations', queryParameters: {
      if (type != null && type.isNotEmpty) 'type': type,
      if (archived == true) 'archived': 'true',
    });
    return (response.data['data'] as List<dynamic>? ?? [])
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Conversation> getConversation(String id) async {
    final response = await _client.dio.get('/communications/conversations/$id');
    return Conversation.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> listMessages(
    String conversationId, {
    String? before,
    String? q,
    bool filesOnly = false,
  }) async {
    final response = await _client.dio.get(
      '/communications/conversations/$conversationId/messages',
      queryParameters: {
        if (before != null) 'before': before,
        if (q != null && q.isNotEmpty) 'q': q,
        if (filesOnly) 'files': '1',
      },
    );
    return (response.data['data'] as List<dynamic>? ?? [])
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> sendMessage(
    String conversationId, {
    String body = '',
    String? clientId,
    String? replyToId,
    String? filePath,
    String? fileName,
    DateTime? scheduledAt,
    int? durationSec,
  }) async {
    if (filePath != null) {
      final form = FormData.fromMap({
        if (body.isNotEmpty) 'body': body,
        if (clientId != null) 'clientId': clientId,
        if (replyToId != null) 'replyToId': replyToId,
        if (scheduledAt != null) 'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        if (durationSec != null) 'durationSec': durationSec.toString(),
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _client.dio.post(
        '/communications/conversations/$conversationId/messages',
        data: form,
      );
      return ChatMessage.fromJson(response.data['data'] as Map<String, dynamic>);
    }
    final response = await _client.dio.post(
      '/communications/conversations/$conversationId/messages',
      data: {
        'body': body,
        if (clientId != null) 'clientId': clientId,
        if (replyToId != null) 'replyToId': replyToId,
        if (scheduledAt != null) 'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      },
    );
    return ChatMessage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ChatMessage> updateMessage(String messageId, {String? body, bool deleted = false}) async {
    final response = await _client.dio.patch('/communications/messages/$messageId', data: {
      if (body != null) 'body': body,
      if (deleted) 'deleted': true,
    });
    return ChatMessage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ChatMessage> react(String messageId, String emoji) async {
    final response = await _client.dio.post('/communications/messages/$messageId/react', data: {
      'emoji': emoji,
    });
    return ChatMessage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ChatMessage> star(String messageId, {bool starred = true}) async {
    final response = await _client.dio.post('/communications/messages/$messageId/star', data: {
      'starred': starred,
    });
    return ChatMessage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ChatMessage> forward(String messageId, String conversationId) async {
    final response = await _client.dio.post('/communications/messages/$messageId/forward', data: {
      'conversationId': conversationId,
    });
    return ChatMessage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> search({required String q, bool filesOnly = false}) async {
    final response = await _client.dio.get('/communications/search', queryParameters: {
      'q': q,
      if (filesOnly) 'files': '1',
    });
    return (response.data['data'] as List<dynamic>? ?? [])
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String conversationId) async {
    await _client.dio.patch('/communications/conversations/$conversationId/read');
  }

  Future<Conversation> createPrivate({
    required String targetUserId,
    required String targetUserType,
  }) async {
    final response = await _client.dio.post('/communications/conversations/private', data: {
      'targetUserId': targetUserId,
      'targetUserType': targetUserType,
    });
    return Conversation.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Conversation> createSupport({String? body}) async {
    final response = await _client.dio.post('/communications/conversations/support', data: {
      if (body != null) 'body': body,
    });
    return Conversation.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Conversation> createBroadcast({
    required String title,
    required String body,
    bool allowReplies = false,
  }) async {
    final response = await _client.dio.post('/communications/broadcasts', data: {
      'title': title,
      'body': body,
      'allowReplies': allowReplies,
    });
    return Conversation.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Conversation> createSubjectRoom({required String subjectId, String? title}) async {
    final response = await _client.dio.post('/communications/conversations/subject', data: {
      'subjectId': subjectId,
      if (title != null) 'title': title,
    });
    return Conversation.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<({String id, String name})>> listSubjectOptions() async {
    final response = await _client.dio.get('/communications/subjects');
    return (response.data['data'] as List<dynamic>? ?? [])
        .map((e) {
          final m = e as Map<String, dynamic>;
          return (id: m['id']?.toString() ?? '', name: m['name']?.toString() ?? 'Subject');
        })
        .where((e) => e.id.isNotEmpty)
        .toList();
  }

  Future<List<DirectoryUser>> directory({String? search, String? role}) async {
    final response = await _client.dio.get('/communications/directory', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (role != null && role.isNotEmpty) 'role': role,
    });
    return (response.data['data'] as List<dynamic>? ?? [])
        .map((e) => DirectoryUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadTotal() async {
    final response = await _client.dio.get('/communications/unread');
    return (response.data['data']?['unread'] as num?)?.toInt() ?? 0;
  }

  Future<Conversation> togglePinMute(
    String id, {
    bool? pinned,
    bool? muted,
    bool? archived,
  }) async {
    final response = await _client.dio.patch('/communications/conversations/$id', data: {
      if (pinned != null) 'pinned': pinned,
      if (muted != null) 'muted': muted,
      if (archived != null) 'archived': archived,
    });
    return Conversation.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<Conversation> pinMessage(String conversationId, String? messageId) async {
    final response = await _client.dio.post(
      '/communications/conversations/$conversationId/pin-message',
      data: {'messageId': messageId},
    );
    return Conversation.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> moderationInbox({String? q}) async {
    final response = await _client.dio.get('/communications/moderation', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
    });
    return (response.data['data'] as List<dynamic>? ?? [])
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> moderateMessage(String messageId, {bool deleted = false, String? note}) async {
    final response = await _client.dio.post('/communications/messages/$messageId/moderate', data: {
      'deleted': deleted,
      if (note != null) 'note': note,
    });
    return ChatMessage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ChatMessage> createChatPoll(
    String conversationId, {
    required String question,
    String pollType = 'single',
    List<Map<String, String>>? options,
  }) async {
    final response = await _client.dio.post('/communications/conversations/$conversationId/poll', data: {
      'question': question,
      'pollType': pollType,
      if (options != null) 'options': options,
    });
    return ChatMessage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<ChatMessage> signalCall(String conversationId, {String action = 'invite', String media = 'audio'}) async {
    final response = await _client.dio.post('/communications/conversations/$conversationId/call', data: {
      'action': action,
      'media': media,
    });
    return ChatMessage.fromJson(response.data['data'] as Map<String, dynamic>);
  }

}
