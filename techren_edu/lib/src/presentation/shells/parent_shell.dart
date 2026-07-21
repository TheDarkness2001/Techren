import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';



import '../../core/routing/parent_navigation.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';

import '../../core/widgets/adaptive_scaffold.dart';

import '../../core/widgets/app_hub_card.dart';

import '../../core/widgets/common_widgets.dart';

import '../../domain/entities/parent_portal.dart';

import '../features/parent/screens/parent_portal_screen.dart';

import '../providers/auth_provider.dart';

import '../providers/parent_provider.dart';

import '../providers/settings_provider.dart';



List<Widget> _parentShellActions(BuildContext context, WidgetRef ref) => [

      IconButton(

        icon: const Icon(Icons.logout),

        tooltip: 'Sign out',

        onPressed: () => ref.read(authProvider.notifier).logout(),

      ),

    ];



class ParentHomeScreen extends ConsumerWidget {

  const ParentHomeScreen({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final portalEnabled = ref.watch(platformSettingsProvider).valueOrNull?.featureFlags.parentPortalEnabled ?? false;

    final childrenAsync = ref.watch(parentChildrenProvider);

    final title = portalEnabled ? 'My Children' : 'Parent Portal';



    return AdaptiveScaffold(

      title: title,

      selectedIndex: 0,

      selectedRoute: '/parent/home',

      items: parentHomeNavItems,

      onDestinationSelected: (_) {},

      actions: _parentShellActions(context, ref),

      body: !portalEnabled

          ? const EmptyState(

              title: 'Parent portal disabled',

              message: 'Ask your branch administrator to enable the parent portal in platform settings.',

              icon: Icons.family_restroom_outlined,

            )

          : childrenAsync.when(

              loading: () => const LoadingState(kind: LoadingSkeletonKind.list),

              error: (e, _) => Center(child: Text(e.toString())),

              data: (children) {

                if (children.isEmpty) {

                  return const EmptyState(

                    title: 'No linked children',

                    message: 'No students are linked to this parent account yet. Contact your branch administrator.',

                    icon: Icons.person_off_outlined,

                  );

                }

                if (children.length == 1) {

                  WidgetsBinding.instance.addPostFrameCallback((_) {

                    ref.read(selectedParentChildIdProvider.notifier).state = children.first.id;

                    context.go(parentChildOverviewRoute(children.first.id));

                  });

                  return const LoadingState(message: 'Opening child profile...');

                }

                return RefreshIndicator(

                  onRefresh: () async => ref.invalidate(parentChildrenProvider),

                  child: ListView(

                    padding: const EdgeInsets.all(AppSpacing.md),

                    children: [

                      const HubSectionHeader(

                        title: 'Select a child',

                        subtitle: 'View overview, feedback, attendance, and exams',

                      ),

                      for (final child in children) _ChildSelectorCard(child: child),

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

    final inactive = child.status == 'inactive';

    return AppHubCard(

      title: child.name,

      subtitle: child.studentCode ?? child.email ?? 'Student',

      accentColor: inactive ? context.semantic.textMuted : AppColors.primary,

      icon: Icons.person_outline,

      trailing: inactive

          ? Chip(

              label: const Text('Inactive'),

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

    return ParentChildScaffold(

      studentId: studentId,

      selectedRoute: '/parent/child/$studentId/overview',

      selectedIndex: 0,

      body: ParentOverviewTab(

        studentId: studentId,

        onRefresh: () {

          ref.invalidate(parentChildOverviewProvider(studentId));

          ref.invalidate(parentChildFeedbackProvider);

          ref.invalidate(parentChildAttendanceProvider);

          ref.invalidate(parentChildExamsProvider);

        },

      ),

    );

  }

}



class ParentChildFeedbackScreen extends ConsumerWidget {

  const ParentChildFeedbackScreen({super.key, required this.studentId});



  final String studentId;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    return ParentChildScaffold(

      studentId: studentId,

      selectedRoute: '/parent/child/$studentId/feedback',

      selectedIndex: 1,

      body: ParentFeedbackTab(studentId: studentId),

    );

  }

}



class ParentChildAttendanceScreen extends ConsumerWidget {

  const ParentChildAttendanceScreen({super.key, required this.studentId});



  final String studentId;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    return ParentChildScaffold(

      studentId: studentId,

      selectedRoute: '/parent/child/$studentId/attendance',

      selectedIndex: 2,

      body: ParentAttendanceTab(studentId: studentId),

    );

  }

}



class ParentChildExamsScreen extends ConsumerWidget {

  const ParentChildExamsScreen({super.key, required this.studentId});



  final String studentId;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    return ParentChildScaffold(

      studentId: studentId,

      selectedRoute: '/parent/child/$studentId/exams',

      selectedIndex: 3,

      body: ParentExamsTab(studentId: studentId),

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

    final childrenAsync = ref.watch(parentChildrenProvider);

    final overviewAsync = ref.watch(parentChildOverviewProvider(studentId));

    final navItems = parentChildNavItems(studentId);



    return childrenAsync.when(

      loading: () => AdaptiveScaffold(

        title: 'Loading...',

        selectedIndex: selectedIndex,

        selectedRoute: selectedRoute,

        items: navItems,

        onDestinationSelected: (i) => onParentChildNavSelected(context, studentId, i),

        actions: _parentShellActions(context, ref),

        body: const LoadingState(kind: LoadingSkeletonKind.dashboard),

      ),

      error: (e, _) => AdaptiveScaffold(

        title: 'Error',

        selectedIndex: selectedIndex,

        selectedRoute: selectedRoute,

        items: navItems,

        onDestinationSelected: (i) => onParentChildNavSelected(context, studentId, i),

        actions: _parentShellActions(context, ref),

        body: Center(child: Text(e.toString())),

      ),

      data: (children) {

        if (!children.any((child) => child.id == studentId)) {

          WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/parent/home'));

          return AdaptiveScaffold(

            title: 'Redirecting...',

            selectedIndex: 0,

            selectedRoute: '/parent/home',

            items: parentHomeNavItems,

            onDestinationSelected: (_) {},

            actions: _parentShellActions(context, ref),

            body: const LoadingState(message: 'Redirecting...'),

          );

        }



        final childName = overviewAsync.maybeWhen(data: (o) => o.child.name, orElse: () => 'Child');

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

                tooltip: 'Switch child',

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

            IconButton(

              icon: const Icon(Icons.home_outlined),

              tooltip: 'All children',

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

