import '../../domain/entities/app_user.dart';
import 'staff_navigation.dart';
String? permissionKeyForStaffRoute(String route) {
  if (route.endsWith('/dashboard') || route.endsWith('/branches')) return null;

  if (route.endsWith('/people')) return 'canViewStudents';
  if (route.contains('/schedule')) return 'canViewScheduler';
  if (route.contains('/attendance')) return 'canViewAttendance';
  if (route.endsWith('/feedback')) return 'canViewFeedback';
  if (route.endsWith('/exams')) return 'canViewExams';
  if (route.endsWith('/learning') ||
      route.contains('/learning/') ||
      route.endsWith('/words') ||
      route.endsWith('/sentences') ||
      route.endsWith('/learning-cms') ||
      route.endsWith('/content-import') ||
      route.contains('/progress')) {
    return 'canManageHomework';
  }
  if (route.endsWith('/competition')) return 'canViewStudents';
  if (route.endsWith('/more')) return 'canViewPayments';
  if (route.endsWith('/revenue-reports')) return 'canViewRevenue';
  if (route.endsWith('/wallet')) return 'canViewWallet';
  if (route.endsWith('/staff-finance')) return 'canViewRevenue';
  if (route.endsWith('/settings') || route.endsWith('/parent-notification-settings')) {
    return 'canManageSettings';
  }
  if (route.endsWith('/recycle-bin')) return '__admin_only__';
  if (route.endsWith('/notifications')) return null;
  return null;
}

bool canAccessStaffRoute(AppUser? user, String route, Map<String, bool> rolePerms) {
  if (user == null) return false;
  if (user.hasFullStaffAccess) return true;

  final key = permissionKeyForStaffRoute(route);
  if (key == '__admin_only__') return false;
  if (key == null) return true;
  return user.hasPermission(key, rolePerms);
}

List<StaffNavItem> filterStaffNavigation(
  List<StaffNavItem> items, {
  required AppUser? user,
  required Map<String, bool> rolePerms,
  bool walletEnabled = false,
}) {
  if (user == null) return items;
  if (user.hasFullStaffAccess && walletEnabled) return items;
  if (user.hasFullStaffAccess && !walletEnabled) {
    return _filterWalletNavItems(items);
  }

  StaffNavItem? filterItem(StaffNavItem item) {
    if (item.hasChildren) {
      final children = item.children.map(filterItem).whereType<StaffNavItem>().toList();
      if (children.isEmpty) return null;
      return StaffNavItem(
        label: item.label,
        icon: item.icon,
        children: children,
        founderOnly: item.founderOnly,
        adminOnly: item.adminOnly,
        section: item.section,
        pinToBottom: item.pinToBottom,
      );
    }
    final route = item.route;
    if (route == null) return null;
    if (!walletEnabled && route.endsWith('/wallet')) return null;
    if (!canAccessStaffRoute(user, route, rolePerms)) return null;
    return item;
  }

  return items.map(filterItem).whereType<StaffNavItem>().toList();
}

List<StaffNavItem> _filterWalletNavItems(List<StaffNavItem> items) {
  StaffNavItem? filterItem(StaffNavItem item) {
    if (item.hasChildren) {
      final children = item.children.map(filterItem).whereType<StaffNavItem>().toList();
      if (children.isEmpty) return null;
      return StaffNavItem(
        label: item.label,
        icon: item.icon,
        children: children,
        founderOnly: item.founderOnly,
        adminOnly: item.adminOnly,
        section: item.section,
        pinToBottom: item.pinToBottom,
      );
    }
    final route = item.route;
    if (route != null && route.endsWith('/wallet')) return null;
    return item;
  }

  return items.map(filterItem).whereType<StaffNavItem>().toList();
}
