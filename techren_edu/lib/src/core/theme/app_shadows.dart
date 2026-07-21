import 'package:flutter/material.dart';

/// Soft elevation — slate-tinted, large blur, low opacity. Never pure black.
abstract final class AppShadows {
  static const Color _slate = Color(0xFF0F172A);
  static const Color _indigo = Color(0xFF4F46E5);

  static List<BoxShadow> get none => const [];

  /// Floating paper card.
  static List<BoxShadow> get card => [
        BoxShadow(
          color: _slate.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: _slate.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardHover => [
        BoxShadow(
          color: _slate.withValues(alpha: 0.08),
          blurRadius: 32,
          offset: const Offset(0, 12),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: _indigo.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get overlay => [
        BoxShadow(
          color: _slate.withValues(alpha: 0.12),
          blurRadius: 40,
          offset: const Offset(0, 16),
          spreadRadius: -8,
        ),
      ];

  /// Glass nav — hairline elevation only.
  static List<BoxShadow> get navbar => [
        BoxShadow(
          color: _slate.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get premium => [
        BoxShadow(
          color: _indigo.withValues(alpha: 0.18),
          blurRadius: 28,
          offset: const Offset(0, 10),
          spreadRadius: -6,
        ),
      ];
}
