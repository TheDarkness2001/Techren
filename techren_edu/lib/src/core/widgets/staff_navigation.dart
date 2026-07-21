import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class StaffNavItem {
  const StaffNavItem({
    required this.label,
    required this.icon,
    this.route,
    this.children = const [],
    this.founderOnly = false,
    this.adminOnly = false,
    this.section,
    this.pinToBottom = false,
  });

  final String label;
  final IconData icon;
  final String? route;
  final List<StaffNavItem> children;
  final bool founderOnly;
  final bool adminOnly;

  /// @deprecated Section headers removed — flat nav list matches reference UI.
  final String? section;

  /// Pinned to the bottom of the sidebar (e.g. Settings).
  final bool pinToBottom;

  bool get hasChildren => children.isNotEmpty;
}

List<StaffNavItem> staffNavigationFor(
  String prefix, {
  required bool isFounder,
  required AppLocalizations l10n,
}) {
  final items = <StaffNavItem>[
    StaffNavItem(
      label: l10n.navDashboard,
      icon: Icons.home_outlined,
      route: '$prefix/dashboard',
    ),
    StaffNavItem(
      label: l10n.navBranches,
      icon: Icons.apartment_outlined,
      route: '$prefix/branches',
      founderOnly: true,
    ),
    StaffNavItem(
      label: l10n.navTimetable,
      icon: Icons.calendar_today_outlined,
      route: '$prefix/schedule/timetable',
    ),
    StaffNavItem(
      label: l10n.navAttendance,
      icon: Icons.fact_check_outlined,
      children: [
        StaffNavItem(
          label: l10n.navStudentAttendance,
          icon: Icons.school_outlined,
          route: '$prefix/attendance/students',
        ),
        StaffNavItem(
          label: l10n.navTeacherAttendance,
          icon: Icons.badge_outlined,
          route: '$prefix/attendance/teachers',
        ),
      ],
    ),
    StaffNavItem(
      label: l10n.navExams,
      icon: Icons.quiz_outlined,
      route: '$prefix/exams',
    ),
    StaffNavItem(
      label: l10n.navFeedback,
      icon: Icons.rate_review_outlined,
      route: '$prefix/feedback',
    ),
    StaffNavItem(
      label: l10n.navLearning,
      icon: Icons.menu_book_outlined,
      route: '$prefix/learning',
    ),
    StaffNavItem(
      label: l10n.navCompetition,
      icon: Icons.emoji_events_outlined,
      children: [
        StaffNavItem(label: l10n.navCompetitionHub, icon: Icons.emoji_events_outlined, route: '$prefix/competition'),
      ],
    ),
    StaffNavItem(
      label: l10n.navPeople,
      icon: Icons.people_outline,
      children: [
        StaffNavItem(label: l10n.navStudentsTeachers, icon: Icons.groups_outlined, route: '$prefix/people'),
      ],
    ),
    StaffNavItem(
      label: l10n.navFinance,
      icon: Icons.payments_outlined,
      children: [
        StaffNavItem(label: l10n.navPaymentsExams, icon: Icons.account_balance_wallet_outlined, route: '$prefix/more'),
        StaffNavItem(label: l10n.navRevenueReports, icon: Icons.bar_chart_outlined, route: '$prefix/revenue-reports'),
        StaffNavItem(label: l10n.navStudentWallets, icon: Icons.wallet_outlined, route: '$prefix/wallet'),
        StaffNavItem(label: l10n.navStaffFinance, icon: Icons.account_balance_wallet_outlined, route: '$prefix/staff-finance'),
      ],
    ),
    StaffNavItem(
      label: l10n.navGroups,
      icon: Icons.grid_view_outlined,
      route: '$prefix/schedule/groups',
    ),
    StaffNavItem(
      label: l10n.navRecycleBin,
      icon: Icons.delete_outline,
      route: '$prefix/recycle-bin',
    ),
    StaffNavItem(
      label: l10n.navSettings,
      icon: Icons.settings_outlined,
      pinToBottom: true,
      children: [
        StaffNavItem(label: l10n.navPlatformSettings, icon: Icons.tune_outlined, route: '$prefix/settings'),
        StaffNavItem(label: l10n.navParentAlerts, icon: Icons.family_restroom_outlined, route: '$prefix/parent-notification-settings'),
        StaffNavItem(label: l10n.navNotifications, icon: Icons.notifications_outlined, route: '$prefix/notifications'),
      ],
    ),
  ];

  return items.where((item) {
    if (item.founderOnly && !isFounder) return false;
    if (item.adminOnly && isFounder) return false;
    return true;
  }).toList();
}

bool staffRouteMatches(String currentRoute, StaffNavItem item) {
  if (item.route != null && _routeActive(currentRoute, item.route!)) return true;
  return item.children.any((child) => staffRouteMatches(currentRoute, child));
}

bool _routeActive(String current, String target) {
  if (current == target) return true;
  if (target.endsWith('/more') && current.startsWith(target)) return true;
  return current.startsWith('$target/');
}

String? staffPrefixFromRoute(String? route) {
  if (route == null) return null;
  if (route.startsWith('/founder')) return '/founder';
  if (route.startsWith('/admin')) return '/admin';
  return null;
}
