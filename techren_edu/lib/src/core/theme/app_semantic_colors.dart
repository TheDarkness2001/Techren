import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_colors_dark.dart';

/// Semantic + shell tokens via ThemeExtension.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.textMuted,
    required this.textSecondary,
    required this.textDisabled,
    required this.border,
    required this.divider,
    required this.surfaceContainer,
    required this.card,
    required this.primaryHover,
    required this.inputFill,
    required this.sidebarBackground,
    required this.sidebarSelected,
    required this.sidebarHover,
    required this.sidebarIcon,
    required this.sidebarIconSelected,
    required this.sidebarText,
    required this.sidebarBorder,
    required this.navbarBackground,
    required this.chartPalette,
  });

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color onDangerContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color textMuted;
  final Color textSecondary;
  final Color textDisabled;
  final Color border;
  final Color divider;
  final Color surfaceContainer;
  final Color card;
  final Color primaryHover;
  final Color inputFill;
  final Color sidebarBackground;
  final Color sidebarSelected;
  final Color sidebarHover;
  final Color sidebarIcon;
  final Color sidebarIconSelected;
  final Color sidebarText;
  final Color sidebarBorder;
  final Color navbarBackground;
  final List<Color> chartPalette;

  static const light = AppSemanticColors(
    success: AppColors.success,
    successContainer: AppColors.successContainer,
    onSuccessContainer: AppColors.onSuccessContainer,
    warning: AppColors.warning,
    warningContainer: AppColors.warningContainer,
    onWarningContainer: AppColors.onWarningContainer,
    danger: AppColors.danger,
    dangerContainer: AppColors.dangerContainer,
    onDangerContainer: AppColors.onDangerContainer,
    info: AppColors.info,
    infoContainer: AppColors.infoContainer,
    onInfoContainer: AppColors.onInfoContainer,
    textMuted: AppColors.textMuted,
    textSecondary: AppColors.textSecondary,
    textDisabled: AppColors.textDisabled,
    border: AppColors.border,
    divider: AppColors.divider,
    surfaceContainer: AppColors.surfaceContainer,
    card: AppColors.card,
    primaryHover: AppColors.primaryHover,
    inputFill: AppColors.inputFill,
    sidebarBackground: AppColors.sidebarBackground,
    sidebarSelected: AppColors.sidebarSelected,
    sidebarHover: AppColors.sidebarHover,
    sidebarIcon: AppColors.sidebarIcon,
    sidebarIconSelected: AppColors.sidebarIconSelected,
    sidebarText: AppColors.sidebarText,
    sidebarBorder: AppColors.sidebarBorder,
    navbarBackground: Color(0xF2FFFFFF),
    chartPalette: AppColors.chartPalette,
  );

  static const dark = AppSemanticColors(
    success: AppColorsDark.success,
    successContainer: AppColorsDark.successContainer,
    onSuccessContainer: AppColorsDark.onSuccessContainer,
    warning: AppColorsDark.warning,
    warningContainer: AppColorsDark.warningContainer,
    onWarningContainer: AppColorsDark.onWarningContainer,
    danger: AppColorsDark.danger,
    dangerContainer: AppColorsDark.dangerContainer,
    onDangerContainer: AppColorsDark.onDangerContainer,
    info: AppColorsDark.info,
    infoContainer: AppColorsDark.infoContainer,
    onInfoContainer: AppColorsDark.onInfoContainer,
    textMuted: AppColorsDark.textMuted,
    textSecondary: AppColorsDark.textSecondary,
    textDisabled: AppColorsDark.textDisabled,
    border: AppColorsDark.border,
    divider: AppColorsDark.divider,
    surfaceContainer: AppColorsDark.surfaceContainer,
    card: AppColorsDark.card,
    primaryHover: AppColorsDark.primaryHover,
    inputFill: AppColorsDark.inputFill,
    sidebarBackground: AppColorsDark.sidebarBackground,
    sidebarSelected: AppColorsDark.sidebarSelected,
    sidebarHover: AppColorsDark.sidebarHover,
    sidebarIcon: AppColorsDark.sidebarIcon,
    sidebarIconSelected: AppColorsDark.sidebarIconSelected,
    sidebarText: AppColorsDark.sidebarText,
    sidebarBorder: AppColorsDark.sidebarBorder,
    navbarBackground: Color(0xE6111827),
    chartPalette: AppColors.chartPalette,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? danger,
    Color? dangerContainer,
    Color? onDangerContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
    Color? textMuted,
    Color? textSecondary,
    Color? textDisabled,
    Color? border,
    Color? divider,
    Color? surfaceContainer,
    Color? card,
    Color? primaryHover,
    Color? inputFill,
    Color? sidebarBackground,
    Color? sidebarSelected,
    Color? sidebarHover,
    Color? sidebarIcon,
    Color? sidebarIconSelected,
    Color? sidebarText,
    Color? sidebarBorder,
    Color? navbarBackground,
    List<Color>? chartPalette,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
      textMuted: textMuted ?? this.textMuted,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      card: card ?? this.card,
      primaryHover: primaryHover ?? this.primaryHover,
      inputFill: inputFill ?? this.inputFill,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      sidebarSelected: sidebarSelected ?? this.sidebarSelected,
      sidebarHover: sidebarHover ?? this.sidebarHover,
      sidebarIcon: sidebarIcon ?? this.sidebarIcon,
      sidebarIconSelected: sidebarIconSelected ?? this.sidebarIconSelected,
      sidebarText: sidebarText ?? this.sidebarText,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      navbarBackground: navbarBackground ?? this.navbarBackground,
      chartPalette: chartPalette ?? this.chartPalette,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDangerContainer: Color.lerp(onDangerContainer, other.onDangerContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      card: Color.lerp(card, other.card, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      sidebarBackground: Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      sidebarSelected: Color.lerp(sidebarSelected, other.sidebarSelected, t)!,
      sidebarHover: Color.lerp(sidebarHover, other.sidebarHover, t)!,
      sidebarIcon: Color.lerp(sidebarIcon, other.sidebarIcon, t)!,
      sidebarIconSelected: Color.lerp(sidebarIconSelected, other.sidebarIconSelected, t)!,
      sidebarText: Color.lerp(sidebarText, other.sidebarText, t)!,
      sidebarBorder: Color.lerp(sidebarBorder, other.sidebarBorder, t)!,
      navbarBackground: Color.lerp(navbarBackground, other.navbarBackground, t)!,
      chartPalette: t < 0.5 ? chartPalette : other.chartPalette,
    );
  }
}

extension AppSemanticColorsContext on BuildContext {
  AppSemanticColors get semantic {
    final extension = Theme.of(this).extension<AppSemanticColors>();
    if (extension != null) return extension;
    return Theme.of(this).brightness == Brightness.dark ? AppSemanticColors.dark : AppSemanticColors.light;
  }
}
