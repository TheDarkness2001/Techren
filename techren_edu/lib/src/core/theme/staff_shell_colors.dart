import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_colors_dark.dart';

/// Staff chrome (sidebar + top bar) — light/dark pairs from the design system.
class StaffShellColors {
  const StaffShellColors._({
    required this.shellBackground,
    required this.sidebarBackground,
    required this.navbarBackground,
    required this.sidebarBorder,
    required this.brandAccent,
    required this.brandAccentMuted,
    required this.navActiveBackground,
    required this.navActiveBar,
    required this.navPill,
    required this.navPillHover,
    required this.textMuted,
    required this.textPrimary,
    required this.dropdownBackground,
    required this.profileCardTint,
    required this.contentBackground,
    required this.iconColor,
    required this.selectedIconColor,
  });

  final Color shellBackground;
  final Color sidebarBackground;
  final Color navbarBackground;
  final Color sidebarBorder;
  final Color brandAccent;
  final Color brandAccentMuted;
  final Color navActiveBackground;
  final Color navActiveBar;
  final Color navPill;
  final Color navPillHover;
  final Color textMuted;
  final Color textPrimary;
  final Color dropdownBackground;
  final Color profileCardTint;
  final Color contentBackground;
  final Color iconColor;
  final Color selectedIconColor;

  static StaffShellColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  static const light = StaffShellColors._(
    shellBackground: AppColors.sidebarBackground,
    sidebarBackground: AppColors.sidebarBackground,
    navbarBackground: Color(0xF2FFFFFF),
    sidebarBorder: AppColors.sidebarBorder,
    brandAccent: AppColors.primary,
    brandAccentMuted: AppColors.primary,
    navActiveBackground: AppColors.sidebarSelected,
    navActiveBar: AppColors.primary,
    navPill: AppColors.sidebarSelected,
    navPillHover: AppColors.sidebarHover,
    textMuted: AppColors.sidebarIcon,
    textPrimary: AppColors.sidebarText,
    dropdownBackground: AppColors.surface,
    profileCardTint: AppColors.primaryContainer,
    contentBackground: AppColors.background,
    iconColor: AppColors.sidebarIcon,
    selectedIconColor: AppColors.sidebarIconSelected,
  );

  static const dark = StaffShellColors._(
    shellBackground: AppColorsDark.sidebarBackground,
    sidebarBackground: AppColorsDark.sidebarBackground,
    navbarBackground: Color(0xE6111827),
    sidebarBorder: AppColorsDark.sidebarBorder,
    brandAccent: AppColors.primaryLight,
    brandAccentMuted: AppColors.primaryLight,
    navActiveBackground: AppColorsDark.sidebarSelected,
    navActiveBar: AppColors.primaryLight,
    navPill: AppColorsDark.sidebarSelected,
    navPillHover: AppColorsDark.sidebarHover,
    textMuted: AppColorsDark.sidebarIcon,
    textPrimary: AppColorsDark.sidebarText,
    dropdownBackground: AppColorsDark.card,
    profileCardTint: AppColorsDark.sidebarSelected,
    contentBackground: AppColorsDark.staffContentBackground,
    iconColor: AppColorsDark.sidebarIcon,
    selectedIconColor: AppColorsDark.sidebarIconSelected,
  );

  // Legacy aliases
  static const brandPurple = AppColors.primary;
  static const activeBackground = AppColors.sidebarSelected;
  static const activeAccent = AppColors.primaryLight;

  static Color contentBackgroundFor(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColorsDark.staffContentBackground
        : AppColors.background;
  }
}
