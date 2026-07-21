import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/app_user.dart';
import '../../core/widgets/adaptive_scaffold.dart';
import '../../core/widgets/staff_permissions.dart';
import '../features/branches/screens/branches_screen.dart';
import '../features/dashboard/widgets/role_dashboard_body.dart';
import '../features/people/screens/people_screen.dart';
import '../features/scheduling/screens/schedule_hub_screen.dart';
import '../features/finance/screens/finance_hub_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/identity_provider.dart';
import '../providers/staff_navigation_provider.dart';

const founderNavItems = [
  NavItem(label: 'Home', icon: Icons.home_outlined, route: '/founder/dashboard'),
  NavItem(label: 'Branches', icon: Icons.account_tree_outlined, route: '/founder/branches'),
  NavItem(label: 'People', icon: Icons.people_outline, route: '/founder/people'),
  NavItem(label: 'More', icon: Icons.more_horiz, route: '/founder/more'),
];

class FounderDashboardScreen extends ConsumerWidget {
  const FounderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    return AdaptiveScaffold(
      title: 'Dashboard',
      selectedIndex: 0,
      selectedRoute: '/founder/dashboard',
      items: founderNavItems,
      onDestinationSelected: (i) => context.go(founderNavItems[i].route),
      actions: [
        FilledButton(
          onPressed: () => context.go('/founder/people'),
          child: const Text('View Students'),
        ),
      ],
      body: RoleDashboardBody(dashboardAsync: dashboard),
    );
  }
}

class FounderBranchesScreen extends StatelessWidget {
  const FounderBranchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BranchesScreen(navItems: founderNavItems, selectedRoute: '/founder/branches');
  }
}

class FounderPeopleScreen extends StatelessWidget {
  const FounderPeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PeopleScreen(navItems: founderNavItems, selectedRoute: '/founder/people');
  }
}

class FounderScheduleScreen extends StatelessWidget {
  const FounderScheduleScreen({super.key, this.selectedRoute = '/founder/schedule/timetable'});

  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    return ScheduleHubScreen(navItems: founderNavItems, selectedRoute: selectedRoute);
  }
}

class FounderMoreScreen extends StatelessWidget {
  const FounderMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FinanceHubScreen(navItems: founderNavItems, selectedRoute: '/founder/more');
  }
}

const adminNavItems = [
  NavItem(label: 'Home', icon: Icons.home_outlined, route: '/admin/dashboard'),
  NavItem(label: 'People', icon: Icons.people_outline, route: '/admin/people'),
  NavItem(label: 'Schedule', icon: Icons.calendar_month_outlined, route: '/admin/schedule'),
  NavItem(label: 'More', icon: Icons.more_horiz, route: '/admin/more'),
];

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final rolePerms = ref.watch(staffRolePermissionsProvider);
    final dashboard = ref.watch(dashboardProvider);

    return AdaptiveScaffold(
      title: 'Dashboard',
      selectedIndex: 0,
      selectedRoute: '/admin/dashboard',
      items: adminNavItems,
      onDestinationSelected: (i) => context.go(adminNavItems[i].route),
      actions: [
        if (user != null && canAccessStaffRoute(user, '/admin/people', rolePerms))
          FilledButton(
            onPressed: () => context.go('/admin/people'),
            child: const Text('View Students'),
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (user != null && !user.hasFullStaffAccess)
            _StaffQuickActions(prefix: '/admin', user: user, rolePerms: rolePerms),
          Expanded(child: RoleDashboardBody(dashboardAsync: dashboard)),
        ],
      ),
    );
  }
}

class _StaffQuickActions extends StatelessWidget {
  const _StaffQuickActions({
    required this.prefix,
    required this.user,
    required this.rolePerms,
  });

  final String prefix;
  final AppUser user;
  final Map<String, bool> rolePerms;

  @override
  Widget build(BuildContext context) {
    final actions = <({String label, IconData icon, String route})>[
      if (canAccessStaffRoute(user, '$prefix/people', rolePerms))
        (label: 'People', icon: Icons.people_outline, route: '$prefix/people'),
      if (canAccessStaffRoute(user, '$prefix/schedule', rolePerms))
        (label: 'Schedule', icon: Icons.calendar_month_outlined, route: '$prefix/schedule'),
      if (canAccessStaffRoute(user, '$prefix/attendance', rolePerms))
        (label: 'Attendance', icon: Icons.fact_check_outlined, route: '$prefix/attendance'),
      if (canAccessStaffRoute(user, '$prefix/feedback', rolePerms))
        (label: 'Feedback', icon: Icons.rate_review_outlined, route: '$prefix/feedback'),
      if (canAccessStaffRoute(user, '$prefix/exams', rolePerms))
        (label: 'Exams', icon: Icons.quiz_outlined, route: '$prefix/exams'),
      if (canAccessStaffRoute(user, '$prefix/revenue-reports', rolePerms))
        (label: 'Revenue', icon: Icons.bar_chart_outlined, route: '$prefix/revenue-reports'),
      if (canAccessStaffRoute(user, '$prefix/more', rolePerms))
        (label: 'Payments', icon: Icons.payments_outlined, route: '$prefix/more'),
    ];

    if (actions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final action in actions)
            ActionChip(
              avatar: Icon(action.icon, size: 18),
              label: Text(action.label),
              onPressed: () => context.go(action.route),
            ),
        ],
      ),
    );
  }
}

class AdminPeopleScreen extends StatelessWidget {
  const AdminPeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PeopleScreen(navItems: adminNavItems, selectedRoute: '/admin/people');
  }
}

class AdminScheduleScreen extends StatelessWidget {
  const AdminScheduleScreen({super.key, this.selectedRoute = '/admin/schedule/timetable'});

  final String selectedRoute;

  @override
  Widget build(BuildContext context) {
    return ScheduleHubScreen(navItems: adminNavItems, selectedRoute: selectedRoute);
  }
}

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FinanceHubScreen(navItems: adminNavItems, selectedRoute: '/admin/more');
  }
}
