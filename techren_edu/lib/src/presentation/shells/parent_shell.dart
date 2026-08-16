import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/error_l10n.dart';
import '../../core/routing/parent_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/adaptive_scaffold.dart';
import '../../core/widgets/app_hub_card.dart';
import '../../core/widgets/appearance_controls.dart';
import '../../core/widgets/common_widgets.dart';
import '../../domain/entities/parent_portal.dart';
import '../features/communications/screens/communications_hub_screen.dart';
import '../features/parent/screens/parent_portal_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/parent_provider.dart';
import '../providers/settings_provider.dart';

List<Widget> _parentShellActions(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  return [
    IconButton(
      icon: const Icon(Icons.logout),
      tooltip: l10n.signOut,
      onPressed: () => ref.read(authProvider.notifier).logout(),
    ),
  ];
}

class ParentHomeScreen extends ConsumerWidget {
  const ParentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final portalEnabled =
        ref.watch(platformSettingsProvider).valueOrNull?.featureFlags.parentPortalEnabled ?? false;
    final childrenAsync = ref.watch(parentChildrenProvider);
    final title = portalEnabled ? l10n.navMyChildren : l10n.parentPortal;

    return AdaptiveScaffold(
      title: title,
      selectedIndex: 0,
      selectedRoute: '/parent/home',
      items: parentHomeNavItems,
      onDestinationSelected: (_) {},
      actions: _parentShellActions(context, ref),
      body: !portalEnabled
          ? Column(
              children: [
                Expanded(
                  child: EmptyState(
                    title: l10n.parentPortalDisabled,
                    message: l10n.parentPortalDisabledMessage,
                    icon: Icons.family_restroom_outlined,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: AppearanceControls(),
                ),
              ],
            )
          : childrenAsync.when(
              loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
              error: (e, _) => Center(child: Text(localizedError(e, l10n))),
              data: (children) {
                if (children.isEmpty) {
                  return Column(
                    children: [
                      Expanded(
                        child: EmptyState(
                          title: l10n.noLinkedChildren,
                          message: l10n.noLinkedChildrenMessage,
                          icon: Icons.person_off_outlined,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: AppearanceControls(),
                      ),
                    ],
                  );
                }

                if (children.length == 1) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ref.read(selectedParentChildIdProvider.notifier).state = children.first.id;
                    context.go(parentChildOverviewRoute(children.first.id));
                  });
                  return LoadingState(message: l10n.openingChildProfile);
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(parentChildrenProvider),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      HubSectionHeader(
                        title: l10n.selectAChild,
                        subtitle: l10n.selectAChildSubtitle,
                      ),
                      for (final child in children) _ChildSelectorCard(child: child),
                      const SizedBox(height: AppSpacing.lg),
                      const AppearanceControls(),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ChildSelectorCard extends ConsumerWidget {
  const _ChildSelectorCard({required this.child});

  final ParentChild child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final inactive = child.status == 'inactive';

    return AppHubCard(
      title: child.name,
      subtitle: child.studentCode ?? child.email ?? l10n.roleStudent,
      accentColor: inactive ? context.semantic.textMuted : AppColors.primary,
      icon: Icons.person_outline,
      trailing: inactive
          ? Chip(
              label: Text(l10n.statusInactive),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : null,
      onTap: () {
        ref.read(selectedParentChildIdProvider.notifier).state = child.id;
        context.go(parentChildOverviewRoute(child.id));
      },
    );
  }
}

class ParentChildOverviewScreen extends ConsumerWidget {
  const ParentChildOverviewScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = '/parent/child/$studentId/overview';
    return ParentChildScaffold(
      studentId: studentId,
      selectedRoute: route,
      selectedIndex: parentChildNavIndex(route, studentId),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: AppearanceControls(),
          ),
          Expanded(
            child: ParentOverviewTab(
              studentId: studentId,
              onRefresh: () {
                ref.invalidate(parentChildOverviewProvider(studentId));
                ref.invalidate(parentChildPaymentsProvider(studentId));
                ref.invalidate(parentChildFeedbackProvider);
                ref.invalidate(parentChildAttendanceProvider);
                ref.invalidate(parentChildExamsProvider);
                ref.invalidate(parentChildHomeworkProvider(studentId));
                ref.invalidate(parentChildScheduleProvider(studentId));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ParentChildPaymentsScreen extends ConsumerWidget {
  const ParentChildPaymentsScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = '/parent/child/$studentId/payments';
    return ParentChildScaffold(
      studentId: studentId,
      selectedRoute: route,
      selectedIndex: parentChildNavIndex(route, studentId),
      body: ParentPaymentsTab(studentId: studentId),
    );
  }
}

class ParentChildFeedbackScreen extends ConsumerWidget {
  const ParentChildFeedbackScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = '/parent/child/$studentId/feedback';
    return ParentChildScaffold(
      studentId: studentId,
      selectedRoute: route,
      selectedIndex: parentChildNavIndex(route, studentId),
      body: ParentFeedbackTab(studentId: studentId),
    );
  }
}

class ParentChildAttendanceScreen extends ConsumerWidget {
  const ParentChildAttendanceScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = '/parent/child/$studentId/attendance';
    return ParentChildScaffold(
      studentId: studentId,
      selectedRoute: route,
      selectedIndex: parentChildNavIndex(route, studentId),
      body: ParentAttendanceTab(studentId: studentId),
    );
  }
}

class ParentChildExamsScreen extends ConsumerWidget {
  const ParentChildExamsScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = '/parent/child/$studentId/exams';
    return ParentChildScaffold(
      studentId: studentId,
      selectedRoute: route,
      selectedIndex: parentChildNavIndex(route, studentId),
      body: ParentExamsTab(studentId: studentId),
    );
  }
}

class ParentChildScheduleScreen extends ConsumerWidget {
  const ParentChildScheduleScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = '/parent/child/$studentId/schedule';
    return ParentChildScaffold(
      studentId: studentId,
      selectedRoute: route,
      selectedIndex: parentChildNavIndex(route, studentId),
      body: ParentScheduleTab(studentId: studentId),
    );
  }
}

class ParentChildHomeworkScreen extends ConsumerWidget {
  const ParentChildHomeworkScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = '/parent/child/$studentId/homework';
    return ParentChildScaffold(
      studentId: studentId,
      selectedRoute: route,
      selectedIndex: parentChildNavIndex(route, studentId),
      body: ParentHomeworkTab(studentId: studentId),
    );
  }
}

class ParentMessagesScreen extends StatelessWidget {
  const ParentMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommunicationsHubScreen(
      routePrefix: '/parent',
      isParent: true,
      homeRoute: '/parent/home',
      selectedRoute: '/parent/messages',
    );
  }
}

class ParentChildScaffold extends ConsumerWidget {
  const ParentChildScaffold({
    super.key,
    required this.studentId,
    required this.selectedRoute,
    required this.selectedIndex,
    required this.body,
  });

  final String studentId;
  final String selectedRoute;
  final int selectedIndex;
  final Widget body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final childrenAsync = ref.watch(parentChildrenProvider);
    final overviewAsync = ref.watch(parentChildOverviewProvider(studentId));
    final navItems = parentChildNavItems(studentId);

    return childrenAsync.when(
      loading: () => AdaptiveScaffold(
        title: l10n.loadingLabel,
        selectedIndex: selectedIndex,
        selectedRoute: selectedRoute,
        items: navItems,
        onDestinationSelected: (i) => onParentChildNavSelected(context, studentId, i),
        actions: _parentShellActions(context, ref),
        body: const LoadingState(kind: LoadingSkeletonKind.dashboard),
      ),
      error: (e, _) => AdaptiveScaffold(
        title: l10n.errorLabel,
        selectedIndex: selectedIndex,
        selectedRoute: selectedRoute,
        items: navItems,
        onDestinationSelected: (i) => onParentChildNavSelected(context, studentId, i),
        actions: _parentShellActions(context, ref),
        body: Center(child: Text(localizedError(e, l10n))),
      ),
      data: (children) {
        if (!children.any((child) => child.id == studentId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/parent/home'));
          return AdaptiveScaffold(
            title: l10n.redirecting,
            selectedIndex: 0,
            selectedRoute: '/parent/home',
            items: parentHomeNavItems,
            onDestinationSelected: (_) {},
            actions: _parentShellActions(context, ref),
            body: LoadingState(message: l10n.redirecting),
          );
        }

        final childName = overviewAsync.maybeWhen(data: (o) => o.child.name, orElse: () => l10n.childLabel);
        final showSwitcher = children.length > 1;

        return AdaptiveScaffold(
          title: childName,
          selectedIndex: selectedIndex,
          selectedRoute: selectedRoute,
          items: navItems,
          onDestinationSelected: (i) => onParentChildNavSelected(context, studentId, i),
          actions: [
            if (showSwitcher)
              PopupMenuButton<String>(
                tooltip: l10n.switchChild,
                icon: const Icon(Icons.family_restroom_outlined),
                onSelected: (id) {
                  ref.read(selectedParentChildIdProvider.notifier).state = id;
                  final route = selectedRoute.replaceFirst(studentId, id);
                  context.go(route);
                },
                itemBuilder: (context) => [
                  for (final child in children)
                    PopupMenuItem(
                      value: child.id,
                      child: Text(child.name),
                    ),
                ],
              ),
            PopupMenuButton<String>(
              tooltip: l10n.navMore,
              icon: const Icon(Icons.more_horiz),
              onSelected: (route) => context.go(route),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: '/parent/messages',
                  child: Text(l10n.navMessages),
                ),
                PopupMenuItem(
                  value: '/parent/child/$studentId/schedule',
                  child: Text(l10n.childSchedule),
                ),
                PopupMenuItem(
                  value: '/parent/child/$studentId/homework',
                  child: Text(l10n.navHomework),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: l10n.allChildren,
              onPressed: () => context.go('/parent/home'),
            ),
            ..._parentShellActions(context, ref),
          ],
          body: body,
        );
      },
    );
  }
}
