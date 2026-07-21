import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/adaptive_scaffold.dart';

/// Parent home — child picker (no child selected yet).
const parentHomeNavItems = [
  NavItem(label: 'My Children', icon: Icons.family_restroom_outlined, route: '/parent/home'),
];

List<NavItem> parentChildNavItems(String studentId) => [
      NavItem(
        label: 'Overview',
        icon: Icons.dashboard_outlined,
        route: '/parent/child/$studentId/overview',
      ),
      NavItem(
        label: 'Feedback',
        icon: Icons.rate_review_outlined,
        route: '/parent/child/$studentId/feedback',
      ),
      NavItem(
        label: 'Attendance',
        icon: Icons.fact_check_outlined,
        route: '/parent/child/$studentId/attendance',
      ),
      NavItem(
        label: 'Exams',
        icon: Icons.quiz_outlined,
        route: '/parent/child/$studentId/exams',
      ),
    ];

int parentChildNavIndex(String route, String studentId) {
  final items = parentChildNavItems(studentId);
  final index = items.indexWhere((item) => route.startsWith(item.route));
  return index < 0 ? 0 : index;
}

void onParentChildNavSelected(BuildContext context, String studentId, int index) {
  final items = parentChildNavItems(studentId);
  if (index < 0 || index >= items.length) return;
  context.go(items[index].route);
}

String parentChildOverviewRoute(String studentId) => '/parent/child/$studentId/overview';
