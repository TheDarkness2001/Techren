import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/branch.dart';
import '../../domain/entities/paginated_result.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/identity_provider.dart';
import '../../presentation/providers/staff_branch_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/staff_shell_colors.dart';
import '../utils/media_url.dart';
import 'appearance_controls.dart';
import 'notification_icon_button.dart';
import 'staff_shell_shortcuts.dart';

/// Staff top navbar — hairline border, branch combobox, and [MenuAnchor] profile
/// (replaces the old manual dialog positioning from Phase A audit).
class StaffTopBar extends ConsumerStatefulWidget {
  const StaffTopBar({
    super.key,
    this.compact = false,
    this.title,
    this.actions,
    this.onMenuPressed,
  });

  final bool compact;

  /// Page title shown on mobile (replaces duplicate [AppBar]).
  final String? title;

  /// Screen-specific actions (search, add, etc.).
  final List<Widget>? actions;

  /// Opens the navigation drawer on mobile staff layout.
  final VoidCallback? onMenuPressed;

  @override
  ConsumerState<StaffTopBar> createState() => _StaffTopBarState();
}

class _StaffTopBarState extends ConsumerState<StaffTopBar> {
  String _roleLabel(AppUser user, AppLocalizations l10n) {
    return l10n.roleLabelFor(
      isFounder: user.isFounder,
      isAdmin: user.isAdmin,
      isManager: user.isManager,
      isTeacher: user.isTeacher,
    );
  }

  String _displayId(AppUser user) {
    final prefix = user.isFounder
        ? 'F'
        : user.isAdmin
            ? 'A'
            : user.isManager
                ? 'M'
                : 'T';
    final tail = user.id.length > 4 ? user.id.substring(user.id.length - 4) : user.id;
    return '$prefix$tail'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = ref.watch(authProvider).user;
    final branchesAsync = ref.watch(branchesProvider(const PageMeta(page: 1)));
    final selectedBranchId = ref.watch(staffBranchFilterProvider);
    final isFounder = user?.isFounder ?? false;
    final shell = StaffShellColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: shell.navbarBackground,
        border: Border(bottom: BorderSide(color: shell.sidebarBorder.withValues(alpha: 0.7))),
        boxShadow: AppShadows.navbar,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: widget.compact ? 52 : 64,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? AppSpacing.sm : AppSpacing.lg),
            child: Row(
              children: [
                if (widget.compact && widget.onMenuPressed != null)
                  IconButton(
                    tooltip: l10n.openNavigation,
                    onPressed: widget.onMenuPressed,
                    icon: Icon(Icons.menu_rounded, color: shell.textPrimary),
                  ),
                if (widget.compact && widget.title != null)
                  Expanded(
                    child: Text(
                      widget.title!,
                      style: TextStyle(
                        color: shell.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else if (!widget.compact)
                  Text(
                    l10n.academyName,
                    style: TextStyle(
                      color: shell.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
                  ),
                const Spacer(),
                if (!widget.compact) const KeyboardShortcutHint(),
                if (isFounder) _BranchSelector(branchesAsync: branchesAsync, selectedBranchId: selectedBranchId),
                if (!isFounder && user?.branchId != null)
                  _BranchLabel(branchesAsync: branchesAsync, branchId: user!.branchId!),
                if (widget.actions != null) ...widget.actions!,
                if (user != null) ...[
                  NotificationIconButton(
                    route: user.isFounder ? '/founder/notifications' : '/admin/notifications',
                    iconColor: shell.textPrimary,
                  ),
                  _ProfileMenuAnchor(
                    user: user,
                    roleLabel: _roleLabel(user, l10n),
                    displayId: _displayId(user),
                    compact: widget.compact,
                    onLogout: () => ref.read(authProvider.notifier).logout(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BranchSelector extends ConsumerWidget {
  const _BranchSelector({required this.branchesAsync, required this.selectedBranchId});

  final AsyncValue<PaginatedResult<Branch>> branchesAsync;
  final String selectedBranchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = StaffShellColors.of(context);
    return branchesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        final branches = result.items;
        if (branches.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            height: 38,
            decoration: BoxDecoration(
              color: shell.dropdownBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: shell.sidebarBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedBranchId,
                dropdownColor: shell.dropdownBackground,
                icon: Icon(Icons.expand_more, color: shell.textMuted, size: 18),
                style: TextStyle(color: shell.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                items: [
                  DropdownMenuItem(
                    value: 'all',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apartment_outlined, size: 16, color: shell.textMuted),
                        const SizedBox(width: AppSpacing.sm),
                        const Text('All Branches'),
                      ],
                    ),
                  ),
                  ...branches.map(
                    (b) => DropdownMenuItem(
                      value: b.id,
                      child: Text(b.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) {
                  ref.read(staffBranchFilterProvider.notifier).select(v ?? 'all');
                  ref.invalidate(studentsProvider);
                  ref.invalidate(teachersProvider);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BranchLabel extends StatelessWidget {
  const _BranchLabel({required this.branchesAsync, required this.branchId});

  final AsyncValue<PaginatedResult<Branch>> branchesAsync;
  final String branchId;

  @override
  Widget build(BuildContext context) {
    final shell = StaffShellColors.of(context);
    return branchesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        final branch = result.items.where((b) => b.id == branchId).firstOrNull;
        if (branch == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.apartment_outlined, size: 16, color: shell.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Text(
                branch.name,
                style: TextStyle(color: shell.textPrimary, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileMenuAnchor extends StatelessWidget {
  const _ProfileMenuAnchor({
    required this.user,
    required this.roleLabel,
    required this.displayId,
    required this.compact,
    required this.onLogout,
  });

  final AppUser user;
  final String roleLabel;
  final String displayId;
  final bool compact;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final shell = StaffShellColors.of(context);
    final menuBg = shell.dropdownBackground;
    final menuBorder = shell.sidebarBorder;

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(menuBg),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: menuBorder),
          ),
        ),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
      ),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: compact ? 16 : 17,
                  backgroundColor: shell.brandAccent.withValues(alpha: 0.15),
                  backgroundImage: _avatarImage(user.profileImage),
                  child: user.profileImage == null
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: shell.brandAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        )
                      : null,
                ),
                if (!compact) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    user.name,
                    style: TextStyle(color: shell.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Icon(Icons.expand_more, color: shell.textMuted, size: 18),
                ],
              ],
            ),
          ),
        );
      },
      menuChildren: [
        _ProfileCard(
          user: user,
          roleLabel: roleLabel,
          displayId: displayId,
          onLogout: onLogout,
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.roleLabel,
    required this.displayId,
    required this.onLogout,
  });

  final AppUser user;
  final String roleLabel;
  final String displayId;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final shell = StaffShellColors.of(context);
    final headerTint = shell.profileCardTint;

    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: headerTint,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: shell.brandAccent.withValues(alpha: 0.15),
                  backgroundImage: _avatarImage(user.profileImage),
                  child: user.profileImage == null
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 24, color: shell.brandAccent),
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: AppSpacing.micro),
                Text('ID: $displayId', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.infoContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                const AppearanceControls(),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(onPressed: onLogout, child: Text(l10n.signOut)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

ImageProvider? _avatarImage(String? profileImage) {
  final url = resolveMediaUrl(profileImage);
  return url.isNotEmpty ? NetworkImage(url) : null;
}
