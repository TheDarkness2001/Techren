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
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: outline ? const OutlineInputBorder() : null,
      isDense: dense,
      alignLabelWithHint: alignHint,
    );
  }

  static BoxConstraints dialogConstraints(BuildContext context, {double maxWidth = dialogWidth}) {
    return BoxConstraints(
      maxWidth: maxWidth,
      maxHeight: MediaQuery.sizeOf(context).height * 0.72,
    );
  }
}
