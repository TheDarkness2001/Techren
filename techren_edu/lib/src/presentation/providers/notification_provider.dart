import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/notification_api.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/paginated_result.dart';
import 'auth_provider.dart';

final notificationApiProvider = Provider<NotificationApi>((ref) {
  return NotificationApi(ref.watch(dioClientProvider));
});

typedef NotificationsQuery = ({int page, String search});

final notificationInboxProvider =
    FutureProvider.autoDispose.family<NotificationInbox, NotificationsQuery>((ref, query) async {
  return ref.watch(notificationApiProvider).getNotifications(
        page: query.page,
        search: query.search.isEmpty ? null : query.search,
      );
});

final notificationPageProvider =
    FutureProvider.autoDispose.family<PaginatedResult<AppNotification>, NotificationsQuery>((ref, query) async {
  final inbox = await ref.watch(notificationInboxProvider(query).future);
  return inbox.paginated;
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) async {
  ref.watch(authProvider);
  final inbox = await ref.watch(notificationApiProvider).getNotifications(page: 1);
  return inbox.unreadCount;
});

void invalidateNotificationState(WidgetRef ref) {
  ref.invalidate(notificationInboxProvider);
  ref.invalidate(unreadNotificationCountProvider);
}

final parentNotificationSettingsProvider = FutureProvider.autoDispose.family<ParentNotificationSettings, String>((ref, studentId) async {
  return ref.watch(notificationApiProvider).getParentSettings(studentId);
});
