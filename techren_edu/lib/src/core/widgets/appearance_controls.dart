import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../presentation/providers/app_preferences_provider.dart';

/// Language (EN / RU / UZ) and theme (light / dark / system) chips for profile menus.
class AppearanceControls extends ConsumerWidget {
  const AppearanceControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _OptionChip(
              label: 'EN',
              selected: locale.languageCode == 'en',
              onTap: () => ref.read(localeProvider.notifier).setLanguageCode('en'),
              isDark: isDark,
            ),
            const SizedBox(width: AppSpacing.xs),
            _OptionChip(
              label: 'РУ',
              selected: locale.languageCode == 'ru',
              onTap: () => ref.read(localeProvider.notifier).setLanguageCode('ru'),
              isDark: isDark,
            ),
            const SizedBox(width: AppSpacing.xs),
            _OptionChip(
              label: 'UZ',
              selected: locale.languageCode == 'uz',
              onTap: () => ref.read(localeProvider.notifier).setLanguageCode('uz'),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ThemeChip(
              icon: Icons.light_mode_outlined,
              tooltip: l10n.themeLight,
              selected: themeMode == ThemeMode.light,
              onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
              isDark: isDark,
            ),
            const SizedBox(width: AppSpacing.xs),
            _ThemeChip(
              icon: Icons.dark_mode_outlined,
              tooltip: l10n.themeDark,
              selected: themeMode == ThemeMode.dark,
              onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
              isDark: isDark,
            ),
            const SizedBox(width: AppSpacing.xs),
            _ThemeChip(
              icon: Icons.brightness_auto_outlined,
              tooltip: l10n.themeSystem,
              selected: themeMode == ThemeMode.system,
              onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.primary : (isDark ? scheme.surfaceContainerHigh : Colors.white);
    final fg = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    final border = selected ? scheme.primary : (isDark ? scheme.outline : AppColors.border);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 44,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border),
          ),
          child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.primary : (isDark ? scheme.surfaceContainerHigh : Colors.white);
    final fg = selected ? scheme.onPrimary : scheme.onSurfaceVariant;
    final border = selected ? scheme.primary : (isDark ? scheme.outline : AppColors.border);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 44,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border),
            ),
            child: Icon(icon, size: 18, color: fg),
          ),
        ),
      ),
    );
  }
}
