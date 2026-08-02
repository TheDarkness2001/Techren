import 'package:flutter/foundation.dart';
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

/// Opens the staff command palette (same as Ctrl+K / clickable top-bar hint).
Future<void> openStaffCommandPalette(
  BuildContext context,
  WidgetRef ref, {
  required String prefix,
  required bool isFounder,
}) async {
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
  if (!context.mounted) return;
  try {
    await showAppCommandPalette(context, items: flat);
  } catch (e, st) {
    debugPrint('Command palette failed: $e\n$st');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open command palette: $e')),
    );
  }
}

/// Staff shell keyboard shortcuts — command palette, sidebar toggle, Alt+1-4 nav.
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
    final bindings = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
        openStaffCommandPalette(context, ref, prefix: prefix, isFounder: isFounder);
      },
      const SingleActivator(LogicalKeyboardKey.keyK, control: true, shift: true): () {
        openStaffCommandPalette(context, ref, prefix: prefix, isFounder: isFounder);
      },
      const SingleActivator(LogicalKeyboardKey.keyB, control: true): () {
        final collapsed = ref.read(staffSidebarCollapsedProvider);
        ref.read(staffSidebarCollapsedProvider.notifier).state = !collapsed;
      },
      const SingleActivator(LogicalKeyboardKey.digit1, alt: true): () {
        if (compactBottomRoutes.isNotEmpty) context.go(compactBottomRoutes[0]);
      },
      const SingleActivator(LogicalKeyboardKey.digit2, alt: true): () {
        if (compactBottomRoutes.length > 1) context.go(compactBottomRoutes[1]);
      },
      const SingleActivator(LogicalKeyboardKey.digit3, alt: true): () {
        if (compactBottomRoutes.length > 2) context.go(compactBottomRoutes[2]);
      },
      const SingleActivator(LogicalKeyboardKey.digit4, alt: true): () {
        if (compactBottomRoutes.length > 3) context.go(compactBottomRoutes[3]);
      },
    };
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      bindings[const SingleActivator(LogicalKeyboardKey.keyK, meta: true)] = () {
        openStaffCommandPalette(context, ref, prefix: prefix, isFounder: isFounder);
      };
    }

    return CallbackShortcuts(
      bindings: bindings,
      child: Focus(
        autofocus: true,
        canRequestFocus: true,
        skipTraversal: true,
        child: child,
      ),
    );
  }
}

/// Clickable hint in the staff top bar — opens the command palette.
class KeyboardShortcutHint extends ConsumerWidget {
  const KeyboardShortcutHint({
    super.key,
    required this.prefix,
    required this.isFounder,
  });

  final String prefix;
  final bool isFounder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'Jump to a page (Ctrl+K)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openStaffCommandPalette(context, ref, prefix: prefix, isFounder: isFounder),
          borderRadius: BorderRadius.circular(6),
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
        ),
      ),
    );
  }
}
