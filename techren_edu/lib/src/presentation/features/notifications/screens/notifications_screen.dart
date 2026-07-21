import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/paginated_scroll_body.dart';
import '../../../../domain/entities/notification.dart';

import '../../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({
    super.key,
    this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem>? navItems;
  final String selectedRoute;

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _search = '';
  final _searchController = TextEditingController();

  NotificationsQuery get _baseQuery => (page: 1, search: _search);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navItems = widget.navItems ?? studentNavItemsOf(context);
    final selectedIndex = navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));
    final baseQuery = _baseQuery;

    return AdaptiveScaffold(
      title: 'Notifications',
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: navItems,
      onDestinationSelected: (i) {
        if (widget.selectedRoute.startsWith('/student')) {
          onStudentNavSelected(context, navItems, i);
        } else {
          context.go(navItems[i].route);
        }
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.done_all),
          tooltip: 'Mark all read',
          onPressed: () async {
            await ref.read(notificationApiProvider).markAllRead();
            invalidateNotificationState(ref);
            ref.invalidate(notificationPageProvider(_baseQuery));
          },
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.searchBarPadding,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notifications by title or type',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (value) => setState(() => _search = value.trim()),
            ),
          ),
          Expanded(
            child: PaginatedScrollBody<AppNotification, NotificationsQuery>(
              provider: notificationPageProvider,
              query: baseQuery,
              withPage: (q, page) => (page: page, search: q.search),
              queryCacheKey: _search,
              onInvalidate: (ref, q) {
                invalidateNotificationState(ref);
                ref.invalidate(notificationPageProvider(q));
              },
              itemLabel: 'notifications',
              initialLoadingKind: LoadingSkeletonKind.list,
              empty: ListView(
                children: const [
                  SizedBox(height: AppSpacing.emptyStateTop),
                  EmptyState(
                    title: 'No notifications yet',
                    message: 'Alerts about attendance, feedback, and payments appear here.',
                    icon: Icons.notifications_none_outlined,
                  ),
                ],
              ),
              builder: (context, controller, items, state) => ListView.builder(
                controller: controller,
                padding: AppSpacing.listGutter,
                itemCount: items.length,
                itemBuilder: (_, i) => _NotificationTile(notification: items[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotification notification;

  IconData _iconForEvent(String eventType) {
    if (eventType.contains('feedback')) return Icons.rate_review_outlined;
    if (eventType.contains('attendance')) return Icons.fact_check_outlined;
    if (eventType.contains('payment')) return Icons.payments_outlined;
    if (eventType.contains('exam')) return Icons.quiz_outlined;
    return Icons.notifications_outlined;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppAdminRowCard(
      title: notification.title,
      subtitle: notification.body,
      icon: _iconForEvent(notification.eventType),
      highlighted: !notification.isRead,
      onTap: () async {
        if (!notification.isRead) {
          await ref.read(notificationApiProvider).markRead(notification.id);
          invalidateNotificationState(ref);
          ref.invalidate(notificationPageProvider((page: 1, search: '')));
        }
      },
      trailing: notification.isRead
          ? null
          : Icon(Icons.circle, size: 10, color: AppColors.primary),
    );
  }
}
