import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/adaptive_scaffold.dart';
import '../features/attendance/screens/teacher_attendance_screen.dart';
import '../features/dashboard/widgets/role_dashboard_body.dart';
import '../features/people/widgets/profile_photo_picker.dart';
import '../features/scheduling/screens/schedule_hub_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/identity_provider.dart';
import '../providers/staff_navigation_provider.dart';
const teacherNavItems = [
  NavItem(label: 'Home', icon: Icons.home_outlined, route: '/teacher/dashboard'),
  NavItem(label: 'Classes', icon: Icons.class_outlined, route: '/teacher/classes'),
  NavItem(label: 'Attendance', icon: Icons.fact_check_outlined, route: '/teacher/attendance'),
  NavItem(label: 'Profile', icon: Icons.person_outline, route: '/teacher/profile'),
];

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    return AdaptiveScaffold(
      title: 'Teacher',
      selectedIndex: 0,
      selectedRoute: '/teacher/dashboard',
      items: teacherNavItems,
      onDestinationSelected: (i) => context.go(teacherNavItems[i].route),
      body: RoleDashboardBody(dashboardAsync: dashboard),
    );
  }
}

class TeacherClassesScreen extends StatelessWidget {
  const TeacherClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TimetableScreen(
      type: 'teacher',
      title: 'My Classes',
      navItems: teacherNavItems,
      selectedRoute: '/teacher/classes',
      selectedIndex: 1,
    );
  }
}

class TeacherAttendanceScreen extends StatelessWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TeacherAttendancePage(
      navItems: teacherNavItems,
      selectedRoute: '/teacher/attendance',
    );
  }
}

class TeacherProfileScreen extends ConsumerWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final rolePerms = ref.watch(staffRolePermissionsProvider);
    return AdaptiveScaffold(
      title: 'Profile',
      selectedIndex: 3,
      selectedRoute: '/teacher/profile',
      items: teacherNavItems,
      onDestinationSelected: (i) => context.go(teacherNavItems[i].route),
      body: ListView(
        padding: AppSpacing.pagePaddingWide,
        children: [
          if (user != null)
            Center(
              child: ProfilePhotoPicker(
                personId: user.id,
                name: user.name,
                profileImage: user.profileImage,
                isStudent: false,
                radius: 48,
                canEdit: true,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(user?.name ?? '', style: Theme.of(context).textTheme.headlineSmall),
          Text(user?.email ?? '', style: TextStyle(color: Colors.grey.shade600)),
          Text('Role: ${user?.role?.name ?? ''}'),
          const SizedBox(height: AppSpacing.lg),
          if (user != null && user.canManageHomeworkFor(rolePerms)) ...[
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Learning CMS'),
              subtitle: const Text('Manage words, sentences & listening'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/teacher/learning-cms'),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Content Import'),
              subtitle: const Text('DOCX, OCR & bulk import'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/teacher/content-import'),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Competition'),
            subtitle: const Text('Record penalties & presentations'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/teacher/competition'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('My Earnings'),
            subtitle: const Text('View earnings and payouts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/teacher/staff-finance'),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonalIcon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}
