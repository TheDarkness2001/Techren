import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../widgets/adaptive_scaffold.dart';
import 'inactive_student_guard.dart';
import '../../domain/entities/app_user.dart';
import '../../presentation/providers/auth_provider.dart';

void navigateStudentRoute(BuildContext context, String route) {
  final user = ProviderScope.containerOf(context).read(authProvider).user;
  if (_shouldBlock(user, route)) {
    context.go(inactiveStudentDashboardRoute);
    return;
  }
  context.go(route);
}

void onStudentNavSelected(BuildContext context, List<NavItem> items, int index) {
  navigateStudentRoute(context, items[index].route);
}

bool _shouldBlock(AppUser? user, String route) {
  return user?.isInactiveStudent == true && isRouteBlockedForInactiveStudent(route);
}

/// Localized bottom/rail navigation for student shells.
List<NavItem> studentNavItemsFor(AppLocalizations l10n) => [
      NavItem(label: l10n.navHome, icon: Icons.home_outlined, route: '/student/dashboard'),
      NavItem(label: l10n.navLearn, icon: Icons.menu_book_outlined, route: '/student/learn'),
      NavItem(label: l10n.navSchedule, icon: Icons.calendar_today_outlined, route: '/student/schedule'),
      NavItem(label: l10n.navProgress, icon: Icons.insights_outlined, route: '/student/progress'),
      NavItem(label: l10n.navProfile, icon: Icons.person_outline, route: '/student/profile'),
    ];

List<NavItem> studentNavItemsOf(BuildContext context) => studentNavItemsFor(context.l10n);
