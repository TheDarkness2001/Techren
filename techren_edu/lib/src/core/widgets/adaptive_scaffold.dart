import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_durations.dart';
import '../theme/app_spacing.dart';
import '../theme/staff_shell_colors.dart';
import '../utils/responsive.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/staff_navigation_provider.dart';
import 'staff_navigation.dart';
import 'staff_permissions.dart';
import 'staff_shell_shortcuts.dart';
import 'staff_sidebar.dart';
import 'staff_top_bar.dart';
import 'page_content_container.dart';
class NavItem {
  const NavItem({required this.label, required this.icon, required this.route});

  final String label;
  final IconData icon;
  final String route;
}

/// Responsive app shell — staff dark sidebar, student/teacher [NavigationRail],
/// and bottom nav on compact breakpoints (Phase B polish).
class AdaptiveScaffold extends ConsumerWidget {
  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.selectedIndex,
    required this.items,
    required this.onDestinationSelected,
    required this.body,
    this.actions,
    this.selectedRoute,
  });

  final String title;
  final int selectedIndex;
  final List<NavItem> items;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final List<Widget>? actions;
  final String? selectedRoute;

  String? get _staffPrefix => staffPrefixFromRoute(selectedRoute ?? _routeFromItems());

  String? _routeFromItems() {
    if (selectedIndex >= 0 && selectedIndex < items.length) {
      return items[selectedIndex].route;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = Responsive.of(context);
    final staffPrefix = _staffPrefix;
    final user = ref.watch(authProvider).user;
    final rolePerms = ref.watch(staffRolePermissionsProvider);
    final mobileItems = staffPrefix != null && user != null && !user.hasFullStaffAccess
        ? items.where((item) => canAccessStaffRoute(user, item.route, rolePerms)).toList()
        : items;
    final navItems = mobileItems.isEmpty ? items : mobileItems;
    var navSelectedIndex = selectedIndex;
    if (navSelectedIndex >= navItems.length) {
      navSelectedIndex = 0;
    }

    void handleNavSelected(int index) {
      if (index < 0 || index >= navItems.length) return;
      final targetRoute = navItems[index].route;
      final originalIndex = items.indexWhere((item) => item.route == targetRoute);
      onDestinationSelected(originalIndex >= 0 ? originalIndex : index);
    }

    final contentBackground = StaffShellColors.contentBackgroundFor(Theme.of(context).brightness);
    final l10n = context.l10n;
    final contentKey = ValueKey<String>(selectedRoute ?? title);
    final animatedBody = _AnimatedBody(contentKey: contentKey, child: body);

    // —— Staff desktop / tablet: dark sidebar + top bar ——
    if (staffPrefix != null && size != ScreenSize.compact) {
      final isFounder = staffPrefix == '/founder';
      final route = selectedRoute ?? _routeFromItems() ?? '$staffPrefix/dashboard';

      return StaffShellShortcuts(
        prefix: staffPrefix,
        isFounder: isFounder,
        child: Scaffold(
          backgroundColor: contentBackground,
          body: Semantics(
            label: l10n.staffWorkspace,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StaffSidebar(prefix: staffPrefix, isFounder: isFounder, currentRoute: route),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const StaffTopBar(),
                      if (title.isNotEmpty) _PageHeader(title: title, actions: actions),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: animatedBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // —— Staff mobile: single top bar + drawer (no duplicate AppBar) ——
    if (staffPrefix != null && size == ScreenSize.compact) {
      final isFounder = staffPrefix == '/founder';
      final route = selectedRoute ?? _routeFromItems() ?? '$staffPrefix/dashboard';
      return StaffShellShortcuts(
        prefix: staffPrefix,
        isFounder: isFounder,
        compactBottomRoutes: [for (final item in navItems) item.route],
        child: Builder(
          builder: (scaffoldContext) => Scaffold(
            backgroundColor: contentBackground,
            drawer: Drawer(
              child: StaffSidebar(
                prefix: staffPrefix,
                isFounder: isFounder,
                currentRoute: route,
                embedded: true,
              ),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StaffTopBar(
                  compact: true,
                  title: title.isEmpty ? l10n.academyName : title,
                  actions: actions,
                  onMenuPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: animatedBody,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Semantics(
              label: l10n.primaryNavigation,
              child: NavigationBar(
                selectedIndex: navSelectedIndex,
                onDestinationSelected: handleNavSelected,
                destinations: [
                  for (final item in navItems)
                    NavigationDestination(icon: Icon(item.icon), label: item.label),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // —— Student / teacher / parent compact ——
    if (size == ScreenSize.compact) {
      return Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        body: animatedBody,
        bottomNavigationBar: Semantics(
          label: l10n.primaryNavigation,
          child: NavigationBar(
            selectedIndex: navSelectedIndex,
            onDestinationSelected: handleNavSelected,
            destinations: [
              for (final item in navItems)
                NavigationDestination(icon: Icon(item.icon), label: item.label),
            ],
          ),
        ),
      );
    }

    // —— Student / teacher medium+ : themed navigation rail ——
    return Scaffold(
      body: Row(
        children: [
          Semantics(
            label: l10n.mainNavigation,
            child: NavigationRail(
              selectedIndex: navSelectedIndex,
              onDestinationSelected: handleNavSelected,
              extended: size == ScreenSize.expanded,
              minExtendedWidth: 200,
              labelType: size == ScreenSize.expanded
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.selected,
              leading: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset('assets/branding/logo.png', fit: BoxFit.contain),
                  ),
                ),
              ),
              destinations: [
                for (final item in navItems)
                  NavigationRailDestination(
                    icon: Icon(item.icon),
                    label: Text(item.label),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Column(
              children: [
                AppBar(
                  title: Text(title),
                  actions: actions,
                  scrolledUnderElevation: 0,
                ),
                Expanded(child: animatedBody),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle content cross-fade when navigating between pages in the same shell.
class _AnimatedBody extends StatelessWidget {
  const _AnimatedBody({required this.contentKey, required this.child});

  final Key contentKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.normal,
      switchInCurve: AppCurves.enter,
      switchOutCurve: AppCurves.exit,
      layoutBuilder: (currentChild, previousChildren) => currentChild ?? const SizedBox.shrink(),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: KeyedSubtree(
        key: contentKey,
        child: PageContentContainer(child: child),
      ),
    );
  }
}
class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
      ),
    );
  }
}
