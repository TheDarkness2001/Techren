import '../../domain/entities/app_user.dart';
import '../widgets/staff_permissions.dart';

const staffDashboardRoute = '/admin/dashboard';

String? staffRouteGuard(AppUser user, String path, Map<String, bool> rolePerms) {
  if (user.hasFullStaffAccess) return null;
  if (!path.startsWith('/admin') && !path.startsWith('/founder')) return null;
  if (canAccessStaffRoute(user, path, rolePerms)) return null;
  return path.startsWith('/founder') ? '/founder/dashboard' : staffDashboardRoute;
}
