import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../../../core/widgets/staff_permissions.dart';

import '../../../../domain/entities/app_user.dart';

import '../../../providers/auth_provider.dart';

import '../../../providers/staff_navigation_provider.dart';

import 'dashboard_header.dart';

import 'dashboard_widgets.dart';



typedef DashboardShortcut = ({String label, IconData icon, String route});



bool showRoleDashboardShortcuts(String role) {

  return role == 'founder' ||

      role == 'admin' ||

      role == 'sales' ||

      role == 'receptionist' ||

      role == 'manager' ||

      role == 'teacher';

}



List<DashboardShortcut> dashboardShortcutsFor({

  required AppUser? user,

  required String role,

  required Map<String, bool> rolePerms,

}) {

  if (role == 'founder') {

    return const [

      (label: 'Manage Students', icon: Icons.school_outlined, route: '/founder/people'),

      (label: 'Manage Teachers', icon: Icons.groups_outlined, route: '/founder/people'),

      (label: 'View Payments', icon: Icons.payments_outlined, route: '/founder/more'),

      (label: 'Student Attendance', icon: Icons.fact_check_outlined, route: '/founder/attendance/students'),

      (label: 'Subject Groups', icon: Icons.grid_view_outlined, route: '/founder/schedule/groups'),

      (label: 'Exam Management', icon: Icons.quiz_outlined, route: '/founder/exams'),

      (label: 'Student Feedback', icon: Icons.rate_review_outlined, route: '/founder/feedback'),

    ];

  }



  if (role == 'admin') {

    return [

      if (canAccessStaffRoute(user, '/admin/people', rolePerms))

        (label: 'Manage Students', icon: Icons.school_outlined, route: '/admin/people'),

      if (canAccessStaffRoute(user, '/admin/people', rolePerms))

        (label: 'Manage Teachers', icon: Icons.groups_outlined, route: '/admin/people'),

      if (canAccessStaffRoute(user, '/admin/more', rolePerms))

        (label: 'View Payments', icon: Icons.payments_outlined, route: '/admin/more'),

      if (canAccessStaffRoute(user, '/admin/attendance', rolePerms))

        (label: 'Student Attendance', icon: Icons.fact_check_outlined, route: '/admin/attendance/students'),

      if (canAccessStaffRoute(user, '/admin/schedule', rolePerms))

        (label: 'Subject Groups', icon: Icons.grid_view_outlined, route: '/admin/schedule/groups'),

      if (canAccessStaffRoute(user, '/admin/exams', rolePerms))

        (label: 'Exam Management', icon: Icons.quiz_outlined, route: '/admin/exams'),

      if (canAccessStaffRoute(user, '/admin/feedback', rolePerms))

        (label: 'Student Feedback', icon: Icons.rate_review_outlined, route: '/admin/feedback'),

    ];

  }



  if (role == 'teacher') {

    return const [

      (label: 'My Classes', icon: Icons.class_outlined, route: '/teacher/classes'),

      (label: 'Attendance', icon: Icons.fact_check_outlined, route: '/teacher/attendance'),

      (label: 'Learning CMS', icon: Icons.menu_book_outlined, route: '/teacher/learning-cms'),

      (label: 'Profile', icon: Icons.person_outline, route: '/teacher/profile'),

    ];

  }



  const prefix = '/admin';

  return [

    if (canAccessStaffRoute(user, '$prefix/people', rolePerms))

      (label: 'Manage Students', icon: Icons.school_outlined, route: '$prefix/people'),

    if (canAccessStaffRoute(user, '$prefix/more', rolePerms))

      (label: 'View Payments', icon: Icons.payments_outlined, route: '$prefix/more'),

    if (canAccessStaffRoute(user, '$prefix/attendance', rolePerms))

      (label: 'Student Attendance', icon: Icons.fact_check_outlined, route: '$prefix/attendance'),

    if (canAccessStaffRoute(user, '$prefix/schedule', rolePerms))

      (label: 'Subject Groups', icon: Icons.grid_view_outlined, route: '$prefix/schedule/groups'),

    if (canAccessStaffRoute(user, '$prefix/exams', rolePerms))

      (label: 'Exam Management', icon: Icons.quiz_outlined, route: '$prefix/exams'),

    if (canAccessStaffRoute(user, '$prefix/feedback', rolePerms))

      (label: 'Student Feedback', icon: Icons.rate_review_outlined, route: '$prefix/feedback'),

  ];

}



class RoleDashboardShortcuts extends ConsumerWidget {

  const RoleDashboardShortcuts({super.key, required this.role, this.compact = true});



  final String role;

  final bool compact;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final user = ref.watch(authProvider).user;

    final rolePerms = ref.watch(staffRolePermissionsProvider);

    final shortcuts = dashboardShortcutsFor(user: user, role: role, rolePerms: rolePerms);

    if (shortcuts.isEmpty) return const SizedBox.shrink();



    return DashboardSection(

      title: 'Quick Actions',

      child: QuickActionGrid(

        compact: compact,

        actions: [

          for (final shortcut in shortcuts)

            QuickAction(label: shortcut.label, icon: shortcut.icon, route: shortcut.route),

        ],

      ),

    );

  }

}



String dashboardRoleLabel(String role) {

  return switch (role) {

    'founder' => 'Founder',

    'admin' => 'Admin',

    'manager' => 'Manager',

    'sales' => 'Sales',

    'receptionist' => 'Receptionist',

    'teacher' => 'Teacher',

    'student' => 'Student',

    _ => role,

  };

}



String dashboardPrefixForRole(String role) {

  if (role == 'founder') return '/founder';

  return '/admin';

}


