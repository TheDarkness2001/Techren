import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/app_preferences_provider.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/settings_provider.dart';
import '../../presentation/providers/staff_navigation_provider.dart';
import '../theme/app_spacing.dart';
import 'app_command_palette.dart';
import 'staff_navigation.dart';

/// Staff shell keyboard shortcuts — Ctrl+K palette, Ctrl+B sidebar, Alt+1-4 nav (Phase E).
class StaffShellShortcuts extends ConsumerWidget {
  const StaffShellShortcuts({
    super.key,
    required this.child,
    required this.prefix,
    required this.isFounder,
    this.compactBottomRoutes = const [],
  });

  final Widget child;
  final String prefix;
  final bool isFounder;
  final List<String> compactBottomRoutes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyK, control: true): _OpenCommandPaletteIntent(),
        SingleActivator(LogicalKeyboardKey.keyB, control: true): _ToggleSidebarIntent(),
        SingleActivator(LogicalKeyboardKey.digit1, alt: true): _QuickNavIntent(0),
        SingleActivator(LogicalKeyboardKey.digit2, alt: true): _QuickNavIntent(1),
        SingleActivator(LogicalKeyboardKey.digit3, alt: true): _QuickNavIntent(2),
        SingleActivator(LogicalKeyboardKey.digit4, alt: true): _QuickNavIntent(3),
      },
      child: Actions(
        actions: {
          _OpenCommandPaletteIntent: CallbackAction<_OpenCommandPaletteIntent>(
            onInvoke: (_) {
              _openPalette(context, ref);
              return null;
            },
          ),
          _ToggleSidebarIntent: CallbackAction<_ToggleSidebarIntent>(
            onInvoke: (_) {
              final collapsed = ref.read(staffSidebarCollapsedProvider);
              ref.read(staffSidebarCollapsedProvider.notifier).state = !collapsed;
              return null;
            },
          ),
          _QuickNavIntent: CallbackAction<_QuickNavIntent>(
            onInvoke: (intent) {
              if (intent.index < compactBottomRoutes.length) {
                context.go(compactBottomRoutes[intent.index]);
              }
              return null;
            },
          ),
        },
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: child,
        ),
      ),
    );
  }

  void _openPalette(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    final rolePerms = ref.read(staffRolePermissionsProvider);
    final walletEnabled = ref.read(walletEnabledProvider);
    final l10n = ref.read(appLocalizationsProvider);
    final items = staffNavigationForUser(
      prefix: prefix,
      isFounder: isFounder,
      user: user,
      rolePerms: rolePerms,
      walletEnabled: walletEnabled,
      l10n: l10n,
    );
    final flat = <CommandPaletteItem>[];

    void walk(List<StaffNavItem> nodes) {
      for (final node in nodes) {
        if (node.route != null) {
          flat.add(CommandPaletteItem(label: node.label, icon: node.icon, route: node.route!));
        }
        if (node.hasChildren) walk(node.children);
      }
    }

    walk(items);
    showAppCommandPalette(context, items: flat);
  }
}

class _OpenCommandPaletteIntent extends Intent {
  const _OpenCommandPaletteIntent();
}

class _ToggleSidebarIntent extends Intent {
  const _ToggleSidebarIntent();
}

class _QuickNavIntent extends Intent {
  const _QuickNavIntent(this.index);
  final int index;
}

/// Hint chip shown in staff top bar on desktop — reminds users of Ctrl+K.
class KeyboardShortcutHint extends StatelessWidget {
  const KeyboardShortcutHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Command palette (Ctrl+K)',
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'Ctrl+K',
          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
