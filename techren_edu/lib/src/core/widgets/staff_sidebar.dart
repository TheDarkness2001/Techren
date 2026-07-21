import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_durations.dart';
import '../theme/app_spacing.dart';
import '../theme/staff_shell_colors.dart';
import '../l10n/app_localizations.dart';
import '../../presentation/providers/app_preferences_provider.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/settings_provider.dart';
import '../../presentation/providers/staff_navigation_provider.dart';
import 'staff_navigation.dart';

/// Dark staff sidebar — flat nav list, blue active accent bar, expandable groups.
class StaffSidebar extends ConsumerStatefulWidget {
  const StaffSidebar({
    super.key,
    required this.prefix,
    required this.isFounder,
    required this.currentRoute,
    this.embedded = false,
  });

  final String prefix;
  final bool isFounder;
  final String currentRoute;
  final bool embedded;

  static const expandedWidth = 248.0;
  static const collapsedWidth = 72.0;

  @override
  ConsumerState<StaffSidebar> createState() => _StaffSidebarState();
}

class _StaffSidebarState extends ConsumerState<StaffSidebar> {
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _syncExpanded();
  }

  @override
  void didUpdateWidget(covariant StaffSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      _syncExpanded();
    }
  }

  void _syncExpanded() {
    final user = ref.read(authProvider).user;
    final rolePerms = ref.read(staffRolePermissionsProvider);
    final walletEnabled = ref.read(walletEnabledProvider);
    final l10n = AppLocalizations(ref.read(localeProvider));
    final items = staffNavigationForUser(
      prefix: widget.prefix,
      isFounder: widget.isFounder,
      user: user,
      rolePerms: rolePerms,
      walletEnabled: walletEnabled,
      l10n: l10n,
    );
    for (final item in items) {
      if (item.hasChildren && staffRouteMatches(widget.currentRoute, item)) {
        _expanded.add(item.label);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final collapsed = !widget.embedded && ref.watch(staffSidebarCollapsedProvider);
    final width = widget.embedded
        ? double.infinity
        : collapsed
            ? StaffSidebar.collapsedWidth
            : StaffSidebar.expandedWidth;

    final user = ref.watch(authProvider).user;
    final rolePerms = ref.watch(staffRolePermissionsProvider);
    final walletEnabled = ref.watch(walletEnabledProvider);
    final l10n = context.l10n;
    final items = staffNavigationForUser(
      prefix: widget.prefix,
      isFounder: widget.isFounder,
      user: user,
      rolePerms: rolePerms,
      walletEnabled: walletEnabled,
      l10n: l10n,
    );

    final mainItems = items.where((i) => !i.pinToBottom).toList();
    final bottomItems = items.where((i) => i.pinToBottom).toList();

    final shell = StaffShellColors.of(context);

    return AnimatedContainer(
      duration: AppDurations.normal,
      curve: AppCurves.standard,
      width: width,
      decoration: BoxDecoration(
        color: shell.sidebarBackground,
        border: Border(right: BorderSide(color: shell.sidebarBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: widget.embedded ? AppSpacing.sm : AppSpacing.md),
          Expanded(
            child: Scrollbar(
              thumbVisibility: !collapsed,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                children: [
                  for (final item in mainItems) _buildItem(item, collapsed),
                ],
              ),
            ),
          ),
          if (bottomItems.isNotEmpty) ...[
            Divider(height: 1, color: shell.sidebarBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, AppSpacing.sm),
              child: Column(
                children: [
                  for (final item in bottomItems) _buildItem(item, collapsed),
                ],
              ),
            ),
          ],
          if (!widget.embedded)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Center(
                child: IconButton(
                  tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                  onPressed: () => ref.read(staffSidebarCollapsedProvider.notifier).state = !collapsed,
                  icon: Icon(
                    collapsed ? Icons.last_page_rounded : Icons.first_page_rounded,
                    color: shell.textMuted,
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildItem(StaffNavItem item, bool collapsed) {
    if (!item.hasChildren) {
      return _SidebarTile(
        label: item.label,
        icon: item.icon,
        selected: item.route != null && staffRouteMatches(widget.currentRoute, item),
        collapsed: collapsed,
        onTap: item.route == null ? null : () => context.go(item.route!),
      );
    }

    final expanded = _expanded.contains(item.label);
    final groupActive = staffRouteMatches(widget.currentRoute, item);

    if (collapsed) {
      return _SidebarTile(
        label: item.label,
        icon: item.icon,
        selected: groupActive,
        collapsed: true,
        onTap: () {
          final firstChild = item.children.firstWhere(
            (c) => c.route != null,
            orElse: () => item.children.first,
          );
          if (firstChild.route != null) context.go(firstChild.route!);
        },
      );
    }

    return Column(
      children: [
        _SidebarTile(
          label: item.label,
          icon: item.icon,
          selected: false,
          collapsed: false,
          showChevron: true,
          chevronExpanded: expanded,
          onTap: () => setState(() {
            if (expanded) {
              _expanded.remove(item.label);
            } else {
              _expanded.add(item.label);
            }
          }),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              for (final child in item.children)
                _SidebarTile(
                  label: child.label,
                  icon: child.icon,
                  selected: child.route != null && staffRouteMatches(widget.currentRoute, child),
                  collapsed: false,
                  nested: true,
                  onTap: child.route == null ? null : () => context.go(child.route!),
                ),
            ],
          ),
          crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: AppDurations.normal,
          sizeCurve: AppCurves.standard,
        ),
      ],
    );
  }
}

class _SidebarTile extends StatefulWidget {
  const _SidebarTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.collapsed,
    this.onTap,
    this.nested = false,
    this.showChevron = false,
    this.chevronExpanded = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool collapsed;
  final VoidCallback? onTap;
  final bool nested;
  final bool showChevron;
  final bool chevronExpanded;

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final shell = StaffShellColors.of(context);
    final active = widget.selected;
    final iconColor = active ? shell.selectedIconColor : shell.iconColor;
    final textColor = active ? shell.textPrimary : shell.textMuted;
    final bgColor = active
        ? shell.navActiveBackground
        : _hovered
            ? shell.navPillHover
            : Colors.transparent;

    final content = AnimatedContainer(
      duration: AppDurations.fast,
      curve: AppCurves.standard,
      margin: EdgeInsets.only(
        left: widget.nested ? AppSpacing.lg : 0,
        top: 2,
        bottom: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.transparent,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (active && !widget.collapsed)
                  Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: shell.navActiveBar,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.collapsed ? AppSpacing.sm : AppSpacing.md,
                      vertical: 11,
                    ),
                    child: widget.collapsed
                        ? Center(child: Icon(widget.icon, size: 22, color: iconColor))
                        : Row(
                            children: [
                              Icon(widget.icon, size: 20, color: iconColor),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  widget.label,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.showChevron)
                                AnimatedRotation(
                                  turns: widget.chevronExpanded ? 0.25 : 0,
                                  duration: AppDurations.fast,
                                  curve: AppCurves.standard,
                                  child: Icon(Icons.chevron_right, color: shell.textMuted, size: 18),
                                ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: widget.collapsed
            ? Tooltip(message: widget.label, waitDuration: const Duration(milliseconds: 400), child: content)
            : content,
      ),
    );
  }
}
