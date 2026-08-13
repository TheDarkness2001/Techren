import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

/// Notification action ids (must match initialize() registration).
const kChatReplyActionId = 'chat_reply';
const kChatMarkReadActionId = 'chat_mark_read';
const kChatNotificationCategory = 'CHAT_MESSAGE';
const kChatChannelId = 'techren_chat';
const kDefaultChannelId = 'techren_notifications';

final FlutterLocalNotificationsPlugin localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

bool _pluginReady = false;

/// Plain notification tap (no Reply / Mark as read) — set by [PushNotificationService].
void Function(Map<String, String> data)? onChatNotificationTap;

Future<void> ensureChatNotificationsReady() async {
  if (_pluginReady || kIsWeb) return;

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  final iosInit = DarwinInitializationSettings(
    notificationCategories: [
      DarwinNotificationCategory(
        kChatNotificationCategory,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.text(
            kChatReplyActionId,
            'Reply',
            buttonTitle: 'Send',
            placeholder: 'Message',
          ),
          DarwinNotificationAction.plain(
            kChatMarkReadActionId,
            'Mark as Read',
            options: <DarwinNotificationActionOption>{
              DarwinNotificationActionOption.destructive,
            },
          ),
        ],
      ),
    ],
  );

  await localNotificationsPlugin.initialize(
    InitializationSettings(android: androidInit, iOS: iosInit),
    onDidReceiveNotificationResponse: (response) {
      handleChatNotificationResponse(response);
    },
    onDidReceiveBackgroundNotificationResponse: chatNotificationBackgroundHandler,
  );

  final android = localNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      kChatChannelId,
      'Messages',
      description: 'Chat messages with Reply and Mark as read',
      importance: Importance.high,
    ),
  );
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      kDefaultChannelId,
      'TechRen Notifications',
      description: 'Payments, messages, feedback, attendance, and news',
      importance: Importance.high,
    ),
  );

  _pluginReady = true;
}

bool isChatPushData(Map<String, String> data) {
  final eventType = (data['eventType'] ?? '').toLowerCase();
  final screen = (data['screen'] ?? '').toLowerCase();
  final actions = (data['actions'] ?? '').toLowerCase();
  return actions == 'chat' ||
      eventType.contains('chat') ||
      eventType.contains('message') ||
      screen == 'messages' ||
      screen == 'chat';
}

Future<void> showChatPushNotification({
  required String title,
  required String body,
  required Map<String, String> data,
}) async {
  if (kIsWeb) return;
  await ensureChatNotificationsReady();

  final safeTitle = title.trim().isEmpty ? 'TechRen' : title.trim();
  final safeBody = body.trim().isEmpty ? 'New message' : body.trim();
  final dedup = data['messageId']?.isNotEmpty == true
      ? data['messageId']!
      : (data['notificationId']?.isNotEmpty == true
          ? data['notificationId']!
          : '${data['conversationId']}_$safeBody');

  final details = NotificationDetails(
    android: AndroidNotificationDetails(
      kChatChannelId,
      'Messages',
      channelDescription: 'Chat messages with Reply and Mark as read',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      icon: '@mipmap/ic_launcher',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          kChatReplyActionId,
          'Reply',
          inputs: <AndroidNotificationActionInput>[
            const AndroidNotificationActionInput(label: 'Reply'),
          ],
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          kChatMarkReadActionId,
          'Mark as read',
          cancelNotification: true,
        ),
      ],
    ),
    iOS: DarwinNotificationDetails(
      categoryIdentifier: kChatNotificationCategory,
      threadIdentifier: data['conversationId'] ?? 'chat',
    ),
  );

  await localNotificationsPlugin.show(
    dedup.hashCode,
    safeTitle,
    safeBody,
    details,
    payload: jsonEncode(data),
  );
}

@pragma('vm:entry-point')
void chatNotificationBackgroundHandler(NotificationResponse response) {
  // Background isolate: binding needed for secure storage / plugins.
  WidgetsFlutterBinding.ensureInitialized();
  handleChatNotificationResponse(response);
}

Future<void> handleChatNotificationResponse(NotificationResponse response) async {
  Map<String, String> data = {};
  final payload = response.payload;
  if (payload != null && payload.isNotEmpty) {
    try {
      final raw = jsonDecode(payload);
      if (raw is Map) {
        data = raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
    } catch (_) {}
  }

  final conversationId = data['conversationId'] ?? '';
  final actionId = response.actionId ?? '';

  if (actionId == kChatMarkReadActionId && conversationId.isNotEmpty) {
    await _apiMarkRead(conversationId);
    return;
  }

  if (actionId == kChatReplyActionId && conversationId.isNotEmpty) {
    final text = (response.input ?? '').trim();
    if (text.isNotEmpty) {
      await _apiSendReply(conversationId, text);
    }
    return;
  }

  // Plain tap — open conversation when the UI layer registered a handler.
  if (data.isNotEmpty) {
    onChatNotificationTap?.call(data);
  }
}

Future<Dio?> _authedDio() async {
  try {
    final token = await SecureStorageService().getAccessToken();
    if (token == null || token.isEmpty) return null;
    return Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ),
    );
  } catch (e) {
    if (kDebugMode) debugPrint('Push action auth failed: $e');
    return null;
  }
}

Future<void> _apiMarkRead(String conversationId) async {
  final dio = await _authedDio();
  if (dio == null) return;
  try {
    await dio.patch('/communications/conversations/$conversationId/read');
  } catch (e) {
    if (kDebugMode) debugPrint('Mark as read from notification failed: $e');
  }
}

Future<void> _apiSendReply(String conversationId, String body) async {
  final dio = await _authedDio();
  if (dio == null) return;
  try {
    await dio.post(
      '/communications/conversations/$conversationId/messages',
      data: {
        'body': body,
        'clientId': 'push_${DateTime.now().millisecondsSinceEpoch}',
      },
    );
    await dio.patch('/communications/conversations/$conversationId/read');
  } catch (e) {
    if (kDebugMode) debugPrint('Reply from notification failed: $e');
  }
}

Future<void> cancelChatNotification(int id) async {
  if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
  try {
    await localNotificationsPlugin.cancel(id);
  } catch (_) {}
}
