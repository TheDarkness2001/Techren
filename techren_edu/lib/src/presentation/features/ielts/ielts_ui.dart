import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Shared dialog / form / list spacing for IELTS staff CMS screens
/// (Manage, Sources, Bank, Analytics, Access, Editor dialogs).
abstract final class IeltsUi {
  static const EdgeInsets dialogInset = AppSpacing.dialogInset;

  static const EdgeInsets titlePadding = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.lg,
    AppSpacing.lg,
    AppSpacing.sm,
  );

  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.xs,
    AppSpacing.lg,
    AppSpacing.xs,
  );

  static const EdgeInsets actionsPadding = EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.sm,
    AppSpacing.lg,
    AppSpacing.lg,
  );

  static const SizedBox fieldGap = SizedBox(height: AppSpacing.fieldGap);

  /// Gap between list cards.
  static const double listGap = AppSpacing.sm;

  static const double dialogWidth = 520;
  static const double dialogWidthNarrow = 420;

  static InputDecoration field(
    String label, {
    String? hint,
    bool dense = true,
    bool outline = true,
    bool alignHint = false,
  }) {
    // Always float labels with high-contrast colors — auto-float + dark dialogs
    // made Number/Type/Word limit labels nearly invisible on the border.
    const labelColor = Color(0xFFE2E8F0); // slate-200
    const floatingColor = Color(0xFFA5B4FC); // indigo-300
    const hintColor = Color(0xFF94A3B8); // slate-400

    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        color: labelColor,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      floatingLabelStyle: const TextStyle(
        color: floatingColor,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      hintStyle: const TextStyle(color: hintColor, fontSize: 13),
      border: outline ? const OutlineInputBorder() : null,
      enabledBorder: outline
          ? const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF475569)))
          : null,
      focusedBorder: outline
          ? const OutlineInputBorder(borderSide: BorderSide(color: floatingColor, width: 1.5))
          : null,
      isDense: dense,
      alignLabelWithHint: alignHint,
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
    );
  }

  static BoxConstraints dialogConstraints(BuildContext context, {double maxWidth = dialogWidth}) {
    return BoxConstraints(
      maxWidth: maxWidth,
      maxHeight: MediaQuery.sizeOf(context).height * 0.72,
    );
  }
}
