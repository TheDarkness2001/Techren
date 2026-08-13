import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/communications_socket.dart';
import '../../core/push/push_providers.dart';
import '../../data/datasources/remote/communications_api.dart';
import '../../domain/entities/communication.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';

final communicationsApiProvider = Provider<CommunicationsApi>((ref) {
  return CommunicationsApi(ref.watch(dioClientProvider));
});

final communicationsSocketProvider = Provider<CommunicationsSocket>((ref) {
  final socket = CommunicationsSocket(ref.watch(secureStorageProvider));
  ref.onDispose(socket.disconnect);
  return socket;
});

/// Conversation currently open in the messages hub (null if not viewing a chat).
final activeChatConversationIdProvider = StateProvider<String?>((ref) => null);

/// Pending conversation to open after navigating from a toast tap.
final pendingOpenConversationIdProvider = StateProvider<String?>((ref) => null);

/// Bumped on socket `notification` so unread badges refresh.
final communicationsUnreadTickProvider = StateProvider<int>((ref) => 0);

/// Latest chat toast payload for Telegram-style popup (when not in that chat).
final chatToastEventProvider = StateProvider<ChatToastEvent?>((ref) => null);

class ChatToastEvent {
  const ChatToastEvent({
    required this.id,
    required this.conversationId,
    required this.title,
    required this.body,
    this.avatarUrl,
  });

  final String id;
  final String conversationId;
  final String title;
  final String body;
  final String? avatarUrl;
}

/// Bumped when the app resumes so the realtime socket rebinds handlers after disconnect.
final communicationsSocketEpochProvider = StateProvider<int>((ref) => 0);

/// Keep socket connected while authenticated so unread badges + chat toasts stay live.
final communicationsRealtimeProvider = Provider<void>((ref) {
  ref.watch(communicationsSocketEpochProvider);
  final auth = ref.watch(authProvider);
  final socket = ref.watch(communicationsSocketProvider);
  if (auth.user == null) {
    socket.disconnect();
    return;
  }
  final me = auth.user!;
  Future.microtask(() async {
    await socket.connect();
    socket.off('notification');
    socket.on('notification', (data) {
      if (data is! Map) return;
      final map = Map<String, dynamic>.from(data);
      if (map['type']?.toString() != 'chat_message') return;

      final conversationId = map['conversationId']?.toString() ?? '';
      if (conversationId.isEmpty) return;

      final activeId = ref.read(activeChatConversationIdProvider);
      // Already viewing this thread — do not bump the global unread badge.
      if (activeId != null && activeId == conversationId) return;

      // Refresh chat unread badge from the server.
      ref.read(communicationsUnreadTickProvider.notifier).state++;

      final rawMessage = map['message'];
      if (rawMessage is! Map) return;
      final message = ChatMessage.fromJson(Map<String, dynamic>.from(rawMessage));
      if (message.senderId == me.id) return;

      // Share dedup key with FCM so socket + push don't double-toast.
      if (!claimPushDedupId(ref, message.id)) return;

      final preview = message.body.trim().isNotEmpty
          ? message.body.trim()
          : (message.attachments.isNotEmpty ? 'Attachment' : 'New message');
      ref.read(chatToastEventProvider.notifier).state = ChatToastEvent(
        id: message.id,
        conversationId: conversationId,
        title: message.displayFirstName,
        body: preview,
        avatarUrl: message.senderProfileImage,
      );
      // Bell badge: in-app notification is created server-side for chat_message.
      ref.invalidate(unreadNotificationCountProvider);
    });
  });
});

final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) async {
  ref.watch(communicationsUnreadTickProvider);
  return ref.watch(communicationsApiProvider).listConversations();
});

final conversationMessagesProvider =
    FutureProvider.autoDispose.family<List<ChatMessage>, String>((ref, conversationId) async {
  return ref.watch(communicationsApiProvider).listMessages(conversationId);
});

final communicationsUnreadProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.watch(communicationsRealtimeProvider);
  ref.watch(communicationsUnreadTickProvider);
  return ref.watch(communicationsApiProvider).unreadTotal();
});

final directorySearchProvider =
    FutureProvider.autoDispose.family<List<DirectoryUser>, String>((ref, query) async {
  if (query.trim().isEmpty) {
    return ref.watch(communicationsApiProvider).directory();
  }
  return ref.watch(communicationsApiProvider).directory(search: query.trim());
});

final userPresenceProvider = FutureProvider.autoDispose
    .family<UserPresenceInfo, ({String userId, String userType})>((ref, args) async {
  return ref.watch(communicationsApiProvider).getPresence(
        userId: args.userId,
        userType: args.userType,
      );
});
