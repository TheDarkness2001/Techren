import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/widgets/staff_navigation.dart';
import '../../core/widgets/staff_permissions.dart';
import '../../domain/entities/app_user.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';

final staffRolePermissionsProvider = Provider<Map<String, bool>>((ref) {
  final user = ref.watch(authProvider).user;
  final settings = ref.watch(platformSettingsProvider).valueOrNull;
  if (user?.role == null) return {};
  return settings?.rolePermissions[user!.role!.name] ?? {};
});

/// Desktop sidebar collapse — icon rail (72px) vs expanded (260px).
final staffSidebarCollapsedProvider = StateProvider<bool>((ref) => false);

List<StaffNavItem> staffNavigationForUser({
  required String prefix,
  required bool isFounder,
  required AppUser? user,
  required Map<String, bool> rolePerms,
  required bool walletEnabled,
  required AppLocalizations l10n,
}) {
  return filterStaffNavigation(
    staffNavigationFor(prefix, isFounder: isFounder, l10n: l10n),
    user: user,
    rolePerms: rolePerms,
    walletEnabled: walletEnabled,
  );
}
