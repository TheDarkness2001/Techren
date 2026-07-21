import 'package:flutter/material.dart';

/// TechRen brand palette — indigo primary, slate neutrals, purposeful semantics.
/// Surfaces follow the design table; avoid pure black and neon accents.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────
  static const primary = Color(0xFF4F46E5);
  static const primaryHover = Color(0xFF4338CA);
  static const primaryLight = Color(0xFF818CF8);
  static const primarySoft = Color(0xFF6366F1);
  static const primaryContainer = Color(0xFFEEF2FF);
  static const onPrimaryContainer = Color(0xFF312E81);
  /// Soft near-white for text on filled primary (not pure #FFFFFF).
  static const onPrimary = Color(0xFFF8FAFC);

  static const secondary = Color(0xFF06B6D4);
  static const secondaryContainer = Color(0xFFCFFAFE);
  static const onSecondaryContainer = Color(0xFF164E63);
  static const onSecondary = Color(0xFFF0FDFA);

  static const accent = primaryLight;
  static const tertiary = warning;
  static const tertiaryContainer = warningContainer;
  static const onTertiaryContainer = onWarningContainer;

  // ── Light surfaces ─────────────────────────────────────────────────────
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F5F9);
  static const surfaceContainer = surfaceVariant;
  static const surfaceContainerHigh = Color(0xFFE2E8F0);
  static const surfaceContainerHighest = Color(0xFFCBD5E1);
  static const card = surface;
  static const inputFill = Color(0xFFF1F5F9);

  // ── Borders ────────────────────────────────────────────────────────────
  static const divider = Color(0xFFE2E8F0);
  static const border = Color(0xFFCBD5E1);
  static const borderStrong = Color(0xFF94A3B8);
  static const outline = Color(0xFF94A3B8);
  static const outlineVariant = divider;

  // ── Text ───────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF64748B);
  static const textDisabled = Color(0xFF94A3B8);
  static const textHint = Color(0xFF64748B);

  // ── Semantic ───────────────────────────────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const successContainer = Color(0xFFDCFCE7);
  static const onSuccessContainer = Color(0xFF14532D);

  static const warning = Color(0xFFF59E0B);
  static const warningContainer = Color(0xFFFEF3C7);
  static const onWarningContainer = Color(0xFF78350F);

  static const danger = Color(0xFFEF4444);
  static const dangerContainer = Color(0xFFFEE2E2);
  static const onDangerContainer = Color(0xFF7F1D1D);
  static const dangerSoft = Color(0xFFFEE2E2);

  static const info = Color(0xFF3B82F6);
  static const infoContainer = Color(0xFFDBEAFE);
  static const onInfoContainer = Color(0xFF1E3A8A);

  /// Legacy alias used across features.
  static const error = danger;

  // ── Charts (fixed palette — never improvise) ───────────────────────────
  static const chartBlue = Color(0xFF3B82F6);
  static const chartIndigo = Color(0xFF4F46E5);
  static const chartEmerald = Color(0xFF22C55E);
  static const chartAmber = Color(0xFFF59E0B);
  static const chartCyan = Color(0xFF06B6D4);
  static const chartPurple = Color(0xFF8B5CF6);

  static const List<Color> chartPalette = [
    chartBlue,
    chartIndigo,
    chartEmerald,
    chartAmber,
    chartCyan,
    chartPurple,
  ];

  // ── Sidebar (light) ────────────────────────────────────────────────────
  static const sidebarBackground = Color(0xFFFFFFFF);
  static const sidebarSelected = Color(0xFFEEF2FF);
  static const sidebarHover = Color(0xFFF8FAFC);
  static const sidebarIcon = Color(0xFF64748B);
  static const sidebarIconSelected = primary;
  static const sidebarText = Color(0xFF334155);
  static const sidebarBorder = divider;

  // ── Gradients ──────────────────────────────────────────────────────────
  static const gradientStart = primary;
  static const gradientMid = primarySoft;
  static const gradientEnd = primaryLight;
}
