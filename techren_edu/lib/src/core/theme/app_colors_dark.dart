import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Dark-mode palette — slate depths, indigo primary family, soft semantics.
abstract final class AppColorsDark {
  static const primary = AppColors.primaryLight;
  static const primaryHover = AppColors.primary;
  static const primaryContainer = Color(0xFF1E3A8A);
  static const onPrimaryContainer = Color(0xFFEEF2FF);
  static const onPrimary = Color(0xFF0F172A);

  static const secondary = AppColors.secondary;
  static const secondaryContainer = Color(0xFF164E63);
  static const onSecondaryContainer = Color(0xFFCFFAFE);
  static const onSecondary = Color(0xFF083344);

  static const tertiary = AppColors.warning;
  static const tertiaryContainer = Color(0xFF78350F);
  static const onTertiaryContainer = Color(0xFFFEF3C7);

  static const background = Color(0xFF0F172A);
  static const surface = Color(0xFF111827);
  static const surfaceVariant = Color(0xFF1E293B);
  static const surfaceContainer = surfaceVariant;
  static const surfaceContainerHigh = Color(0xFF1F2937);
  static const surfaceContainerHighest = Color(0xFF334155);
  static const card = Color(0xFF1F2937);
  static const inputFill = Color(0xFF1E293B);

  static const divider = Color(0xFF334155);
  static const border = Color(0xFF334155);
  static const borderStrong = Color(0xFF475569);
  static const outline = Color(0xFF64748B);
  static const outlineVariant = divider;

  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFFCBD5E1);
  static const textMuted = Color(0xFF94A3B8);
  static const textDisabled = Color(0xFF64748B);
  static const textHint = Color(0xFF94A3B8);

  static const success = Color(0xFF4ADE80);
  static const successContainer = Color(0xFF14532D);
  static const onSuccessContainer = Color(0xFFDCFCE7);

  static const warning = Color(0xFFFBBF24);
  static const warningContainer = Color(0xFF78350F);
  static const onWarningContainer = Color(0xFFFEF3C7);

  static const danger = Color(0xFFF87171);
  static const dangerContainer = Color(0xFF7F1D1D);
  static const onDangerContainer = Color(0xFFFEE2E2);

  static const info = Color(0xFF60A5FA);
  static const infoContainer = Color(0xFF1E3A8A);
  static const onInfoContainer = Color(0xFFDBEAFE);

  static const error = danger;

  // Sidebar (dark)
  static const sidebarBackground = Color(0xFF111827);
  static const sidebarSelected = Color(0xFF1E3A8A);
  static const sidebarHover = Color(0xFF1F2937);
  static const sidebarIcon = Color(0xFF94A3B8);
  static const sidebarIconSelected = AppColors.primaryLight;
  static const sidebarText = Color(0xFFE2E8F0);
  static const sidebarBorder = border;

  /// Content pane behind staff chrome.
  static const staffContentBackground = background;
}
