import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/adaptive_scaffold.dart';
import '../../core/widgets/appearance_controls.dart';
import '../../core/widgets/messages_icon_button.dart';
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
  NavItem(label: 'Learning', icon: Icons.menu_book_outlined, route: '/teacher/learning'),
  NavItem(label: 'Messages', icon: Icons.chat_bubble_outline, route: '/teacher/messages'),
  NavItem(label: 'Profile', icon: Icons.person_outline, route: '/teacher/profile'),
];

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    return AdaptiveScaffold(
      title: context.l10n.roleTeacher,
      selectedIndex: 0,
      selectedRoute: '/teacher/dashboard',
      items: teacherNavItems,
      onDestinationSelected: (i) => context.go(teacherNavItems[i].route),
      actions: const [
        MessagesIconButton(route: '/teacher/messages'),
      ],
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
      title: context.l10n.navMyClasses,
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
    final l10n = context.l10n;
    final user = ref.watch(authProvider).user;
    final rolePerms = ref.watch(staffRolePermissionsProvider);
    return AdaptiveScaffold(
      title: l10n.navProfile,
      selectedIndex: 5,
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
          Text(
            l10n.roleNamed(
              l10n.roleLabelFor(
                isFounder: user?.isFounder ?? false,
                isAdmin: user?.isAdmin ?? false,
                isManager: user?.isManager ?? false,
                isTeacher: user?.isTeacher ?? false,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppearanceControls(),
          const SizedBox(height: AppSpacing.lg),
          if (user != null && user.canEditHomeworkFor(rolePerms)) ...[
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(l10n.navLearning),
              subtitle: Text(l10n.learningYourSubjects),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/teacher/learning'),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(l10n.navContentImport),
              subtitle: Text(l10n.contentImportSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/teacher/content-import'),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.insights_outlined),
            title: Text(l10n.navStudentProgress),
            subtitle: Text(l10n.studentProgressSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/teacher/progress'),
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: Text(l10n.navCompetition),
            subtitle: Text(l10n.competitionRecordSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/teacher/competition'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: Text(l10n.myEarnings),
            subtitle: Text(l10n.myEarningsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/teacher/staff-finance'),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonalIcon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}
