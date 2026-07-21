import '../../../core/network/dio_client.dart';
import '../../../domain/entities/notification.dart';

class NotificationApi {
  NotificationApi(this._client);

  final DioClient _client;

  Future<NotificationInbox> getNotifications({int page = 1, bool unreadOnly = false, String? search}) async {
    final response = await _client.dio.get('/notifications', queryParameters: {
      'page': page,
      'limit': 20,
      if (unreadOnly) 'unreadOnly': 'true',
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return NotificationInbox.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AppNotification> markRead(String id) async {
    final response = await _client.dio.patch('/notifications/$id/read');
    return AppNotification.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<int> markAllRead() async {
    final response = await _client.dio.patch('/notifications/read-all');
    return response.data['data']['updated'] as int? ?? 0;
  }

  Future<void> registerFcmToken(String studentId, String token) async {
    await _client.dio.post('/students/$studentId/fcm-token', data: {'token': token});
  }

  Future<ParentNotificationSettings> getParentSettings(String studentId) async {
    final response = await _client.dio.get('/students/$studentId/notification-settings');
    return ParentNotificationSettings.fromJson(response.data['data']['settings'] as Map<String, dynamic>);
  }

  Future<ParentNotificationSettings> updateParentSettings(
    String studentId,
    ParentNotificationSettings settings,
  ) async {
    final response = await _client.dio.put('/students/$studentId/notification-settings', data: settings.toJson());
    return ParentNotificationSettings.fromJson(response.data['data']['settings'] as Map<String, dynamic>);
  }
}
