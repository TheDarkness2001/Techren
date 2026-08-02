import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/communications_socket.dart';
import '../../data/datasources/remote/communications_api.dart';
import '../../domain/entities/communication.dart';
import 'auth_provider.dart';

final communicationsApiProvider = Provider<CommunicationsApi>((ref) {
  return CommunicationsApi(ref.watch(dioClientProvider));
});

final communicationsSocketProvider = Provider<CommunicationsSocket>((ref) {
  final socket = CommunicationsSocket(ref.watch(secureStorageProvider));
  ref.onDispose(socket.disconnect);
  return socket;
});

/// Bumped on socket `notification` so unread badges refresh.
final communicationsUnreadTickProvider = StateProvider<int>((ref) => 0);

/// Keep socket connected while authenticated so unread badges stay live.
final communicationsRealtimeProvider = Provider<void>((ref) {
  final auth = ref.watch(authProvider);
  final socket = ref.watch(communicationsSocketProvider);
  if (auth.user == null) {
    socket.disconnect();
    return;
  }
  Future.microtask(() async {
    await socket.connect();
    socket.off('notification');
    socket.on('notification', (_) {
      ref.read(communicationsUnreadTickProvider.notifier).state++;
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
