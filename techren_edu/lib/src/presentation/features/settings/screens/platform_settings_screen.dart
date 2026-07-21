import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/platform_settings.dart';
import '../../../providers/settings_provider.dart';

class PlatformSettingsScreen extends ConsumerStatefulWidget {
  const PlatformSettingsScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends ConsumerState<PlatformSettingsScreen> {
  FeatureFlags? _flags;
  Map<String, Map<String, bool>>? _permissions;
  bool _saving = false;
  bool _dirty = false;

  void _initFrom(PlatformSettings settings) {
    if (_dirty) return;
    _flags = settings.featureFlags;
    _permissions = settings.rolePermissions.map(
      (role, perms) => MapEntry(role, Map<String, bool>.from(perms)),
    );
  }

  Future<void> _save() async {
    if (_flags == null || _permissions == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(settingsApiProvider).updateSettings(
            featureFlags: _flags,
            rolePermissions: _permissions,
          );
      ref.invalidate(platformSettingsProvider);
      if (!mounted) return;
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(platformSettingsProvider);
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));

    return AdaptiveScaffold(
      title: 'Settings',
      selectedIndex: selectedIndex < 0 ? 3 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        if (_dirty)
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
      ],
      body: settingsAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (settings) {
          _initFrom(settings);
          final flags = _flags ?? settings.featureFlags;
          final permissions = _permissions ?? settings.rolePermissions;

          return ListView(
            padding: AppSpacing.listGutter,
            children: [
              Text('Feature flags', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Wallet module'),
                      subtitle: const Text('Student wallet, top-up, admin deductions'),
                      value: flags.walletEnabled,
                      onChanged: (v) => setState(() {
                        _flags = flags.copyWith(walletEnabled: v);
                        _dirty = true;
                      }),
                    ),
                    SwitchListTile(
                      title: const Text('Gamification'),
                      subtitle: const Text('XP, streaks, achievements'),
                      value: flags.gamificationEnabled,
                      onChanged: (v) => setState(() {
                        _flags = flags.copyWith(gamificationEnabled: v);
                        _dirty = true;
                      }),
                    ),
                    SwitchListTile(
                      title: const Text('Parent portal'),
                      subtitle: const Text('Parent login and child views'),
                      value: flags.parentPortalEnabled,
                      onChanged: (v) => setState(() {
                        _flags = flags.copyWith(parentPortalEnabled: v);
                        _dirty = true;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Role permissions', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              ...editableRoles.map((role) {
                final rolePerms = permissions[role] ?? {};
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ExpansionTile(
                    title: Text(role[0].toUpperCase() + role.substring(1)),
                    subtitle: Text('${rolePerms.values.where((v) => v).length} permissions enabled'),
                    children: permissionLabels.entries.map((entry) {
                      final enabled = rolePerms[entry.key] ?? false;
                      return SwitchListTile(
                        title: Text(entry.value),
                        value: enabled,
                        onChanged: (v) => setState(() {
                          _permissions ??= permissions.map(
                            (r, p) => MapEntry(r, Map<String, bool>.from(p)),
                          );
                          _permissions![role] = {..._permissions![role]!, entry.key: v};
                          _dirty = true;
                        }),
                      );
                    }).toList(),
                  ),
                );
              }),
              if (settings.updatedAt != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Last updated: ${settings.updatedAt!.toLocal()}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
