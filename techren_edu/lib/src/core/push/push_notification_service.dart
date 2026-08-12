import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/notification_api.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/communications_provider.dart';
import '../../presentation/providers/notification_provider.dart';
import '../routing/app_router.dart';
import 'push_providers.dart';

export 'push_providers.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    /* config missing */
  }
}

class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;
  final _local = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _firebaseReady = false;
  String? _currentToken;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _fgSub;
  StreamSubscription<RemoteMessage>? _openSub;

  String? get currentToken => _currentToken;

  NotificationApi get _api => _ref.read(notificationApiProvider);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) return;

    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'Firebase not configured yet (add google-services.json / GoogleService-Info.plist): $e',
        );
      }
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final map = jsonDecode(payload) as Map<String, dynamic>;
          _handleDataNavigation(map.map((k, v) => MapEntry(k, v?.toString() ?? '')));
        } catch (_) {}
      },
    );

    const channel = AndroidNotificationChannel(
      'techren_notifications',
      'TechRen Notifications',
      description: 'Payments, messages, feedback, attendance, and news',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    if (!kIsWeb && Platform.isIOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: false,
      );
    }

    _fgSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    _openSub = FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _handleDataNavigation(_stringData(msg.data));
    });

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleDataNavigation(_stringData(initial.data));
    }

    _tokenSub = messaging.onTokenRefresh.listen((token) async {
      await _registerToken(token, previous: _currentToken);
    });

    if (_ref.read(authProvider).user != null) {
      await syncTokenWithBackend();
    }
  }

  Future<void> onAuthenticated() async {
    if (!_firebaseReady) return;
    await syncTokenWithBackend();
    consumePendingNavigation();
  }

  /// Call while JWT is still valid (before auth logout clears tokens).
  Future<void> onBeforeLogout() async {
    if (!_firebaseReady || _currentToken == null) return;
    try {
      await _api.removeDeviceToken(_currentToken!);
    } catch (_) {}
  }

  Future<void> syncTokenWithBackend() async {
    if (!_firebaseReady) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _registerToken(token, previous: _currentToken);
    } catch (e) {
      if (kDebugMode) debugPrint('FCM getToken failed: $e');
    }
  }

  Future<void> _registerToken(String token, {String? previous}) async {
    _currentToken = token;
    final platform = kIsWeb
        ? 'web'
        : Platform.isIOS
            ? 'ios'
            : Platform.isAndroid
                ? 'android'
                : 'unknown';
    String deviceId = '';
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        deviceId = (await info.androidInfo).id;
      } else if (Platform.isIOS) {
        deviceId = (await info.iosInfo).identifierForVendor ?? '';
      }
    } catch (_) {}

    try {
      if (previous != null && previous.isNotEmpty && previous != token) {
        await _api.refreshDeviceToken(
          token: token,
          previousToken: previous,
          platform: platform,
          deviceId: deviceId,
        );
      } else {
        await _api.registerDeviceToken(
          token: token,
          platform: platform,
          deviceId: deviceId,
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Device token register failed: $e');
    }
  }

  bool claimDedupId(String id) => claimPushDedupId(_ref, id);

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final data = _stringData(message.data);
    final dedupId = () {
      final messageId = data['messageId'] ?? '';
      final notificationId = data['notificationId'] ?? '';
      if (messageId.isNotEmpty) return messageId;
      if (notificationId.isNotEmpty) return notificationId;
      return message.messageId ?? '';
    }();

    if (dedupId.isNotEmpty && !claimDedupId(dedupId)) return;

    _ref.invalidate(unreadNotificationCountProvider);

    final eventType = (data['eventType'] ?? '').toLowerCase();
    final screen = (data['screen'] ?? '').toLowerCase();

    // Chat: socket toast handles foreground; skip OS banner.
    if (eventType.contains('chat') ||
        eventType.contains('message') ||
        screen == 'messages' ||
        screen == 'chat') {
      return;
    }

    // Payment / feedback / attendance: in-app toast poller shows one toast.
    if (eventType.contains('payment') ||
        eventType.contains('feedback') ||
        eventType.contains('attendance') ||
        screen == 'payments' ||
        screen == 'feedback' ||
        screen == 'schedule' ||
        screen == 'attendance') {
      return;
    }

    final title = message.notification?.title ?? data['title'] ?? 'TechRen';
    final body = message.notification?.body ?? data['body'] ?? '';
    if (body.isEmpty && message.notification == null) return;

    await _local.show(
      dedupId.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'techren_notifications',
          'TechRen Notifications',
          channelDescription: 'Payments, messages, feedback, attendance, and news',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(data),
    );
  }

  void _handleDataNavigation(Map<String, String> data) {
    final screen = (data['screen'] ?? '').isNotEmpty
        ? data['screen']!
        : _screenFromEvent(data['eventType'] ?? '');
    final conversationId = data['conversationId'];
    _ref.read(pendingNotificationNavProvider.notifier).state = PendingNotificationNav(
      screen: screen,
      conversationId: conversationId?.isEmpty == true ? null : conversationId,
      notificationId: data['notificationId'],
      extra: data,
    );
    consumePendingNavigation();
  }

  void consumePendingNavigation() {
    final pending = _ref.read(pendingNotificationNavProvider);
    if (pending == null) return;
    final user = _ref.read(authProvider).user;
    if (user == null) return;

    _ref.read(pendingNotificationNavProvider.notifier).state = null;
    _navigateNow(pending.screen, pending.conversationId);
  }

  void _navigateNow(String screen, String? conversationId) {
    final user = _ref.read(authProvider).user;
    if (user == null) return;
    final router = _ref.read(routerProvider);
    final prefix = user.isStudent
        ? '/student'
        : user.isFounder
            ? '/founder'
            : user.usesAdminShell
                ? '/admin'
                : user.isTeacher
                    ? '/teacher'
                    : user.isParent
                        ? '/parent'
                        : '/student';

    switch (screen) {
      case 'payments':
        router.go('$prefix/payments');
      case 'feedback':
        router.go('$prefix/feedback');
      case 'schedule':
      case 'attendance':
        router.go(user.isStudent ? '/student/schedule' : '$prefix/attendance');
      case 'messages':
      case 'chat':
        if (conversationId != null && conversationId.isNotEmpty) {
          _ref.read(pendingOpenConversationIdProvider.notifier).state = conversationId;
        }
        router.go('$prefix/messages');
      case 'news':
        // Students have no dedicated news route yet — open inbox.
        router.go(user.isStudent ? '/student/notifications' : '$prefix/news');
      case 'exams':
        router.go(user.isStudent ? '/student/exams' : '$prefix/exams');
      default:
        router.go(user.isStudent ? '/student/notifications' : '$prefix/notifications');
    }
  }

  static String _screenFromEvent(String eventType) {
    final t = eventType.toLowerCase();
    if (t.contains('payment')) return 'payments';
    if (t.contains('feedback')) return 'feedback';
    if (t.contains('attendance')) return 'schedule';
    if (t.contains('chat') || t.contains('message')) return 'messages';
    if (t.contains('news')) return 'news';
    if (t.contains('exam')) return 'exams';
    return 'notifications';
  }

  Map<String, String> _stringData(Map<String, dynamic> data) =>
      data.map((k, v) => MapEntry(k, v?.toString() ?? ''));

  void dispose() {
    _tokenSub?.cancel();
    _fgSub?.cancel();
    _openSub?.cancel();
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// Boots FCM, registers tokens on login, deactivates before logout, consumes deep links.
class PushNotificationBootstrap extends ConsumerStatefulWidget {
  const PushNotificationBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushNotificationBootstrap> createState() => _PushNotificationBootstrapState();
}

class _PushNotificationBootstrapState extends ConsumerState<PushNotificationBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = ref.read(authProvider.notifier);
      final push = ref.read(pushNotificationServiceProvider);
      auth.beforeLogoutHook = push.onBeforeLogout;
      await push.initialize();
      if (ref.read(authProvider).user != null) {
        await push.onAuthenticated();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      final push = ref.read(pushNotificationServiceProvider);
      if (next.user != null && prev?.user == null) {
        unawaited(push.onAuthenticated());
      }
      if (next.user != null && prev?.user != null && next.user!.id != prev!.user!.id) {
        unawaited(push.onAuthenticated());
      }
    });

    return widget.child;
  }
}
