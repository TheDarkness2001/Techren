import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Premium dialog shell — rounded surface, consistent padding, action row.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.content,
    this.actions,
    this.maxWidth = 480,
  });

  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Widget? content;
  final List<Widget>? actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final compact = media.size.width < AppConstants.compactBreakpoint;
    final insetH = compact ? 12.0 : 40.0;
    final insetV = compact ? 16.0 : 24.0;
    final maxDialogWidth = maxWidth < media.size.width - insetH * 2
        ? maxWidth
        : media.size.width - insetH * 2;
    final maxDialogHeight = (media.size.height - insetV * 2 - media.viewInsets.bottom) * 0.92;

    return Dialog(
      insetPadding: EdgeInsets.fromLTRB(
        insetH,
        insetV,
        insetH,
        insetV + media.viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          maxHeight: maxDialogHeight.clamp(160.0, media.size.height),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? AppSpacing.md : AppSpacing.lg,
            compact ? AppSpacing.md : AppSpacing.lg,
            compact ? AppSpacing.md : AppSpacing.lg,
            compact ? AppSpacing.sm : AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (iconColor ?? AppColors.primary).withValues(alpha: 0.12),
                        borderRadius: AppRadius.chip,
                      ),
                      child: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (content != null) ...[
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: SingleChildScrollView(
                    child: content!,
                  ),
                ),
              ],
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppDialogActions {
  const AppDialogActions._();

  static Widget cancel(BuildContext context, {VoidCallback? onPressed, String? label}) {
    return TextButton(
      onPressed: onPressed ?? () {
        final navigator = Navigator.maybeOf(context, rootNavigator: true) ?? Navigator.maybeOf(context);
        navigator?.pop();
      },
      child: Text(label ?? context.l10n.cancel),
    );
  }

  static Widget confirm(
    BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
    bool destructive = false,
    bool loading = false,
  }) {
    final style = destructive
        ? FilledButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white)
        : null;

    return FilledButton(
      style: style,
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(label),
    );
  }
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => builder(dialogContext),
  );
}

Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  IconData? icon,
}) async {
  final result = await showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => AppDialog(
      title: title,
      icon: icon ?? (destructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded),
      iconColor: destructive ? AppColors.danger : AppColors.primary,
      content: Text(message, style: Theme.of(dialogContext).textTheme.bodyMedium),
      actions: [
        AppDialogActions.cancel(dialogContext, label: cancelLabel ?? dialogContext.l10n.cancel, onPressed: () => Navigator.pop(dialogContext, false)),
        AppDialogActions.confirm(
          dialogContext,
          label: confirmLabel ?? dialogContext.l10n.confirm,
          destructive: destructive,
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
      ],
    ),
  );
  return result == true;
}

Future<bool?> showAppFormDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  bool loading = false,
  Future<void> Function()? onConfirm,
  IconData? icon,
}) {
  return showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => AppDialog(
      title: title,
      icon: icon ?? Icons.edit_outlined,
      content: content,
      actions: [
        AppDialogActions.cancel(
          dialogContext,
          label: cancelLabel ?? dialogContext.l10n.cancel,
          onPressed: loading ? null : () => Navigator.pop(dialogContext, false),
        ),
        AppDialogActions.confirm(
          dialogContext,
          label: confirmLabel ?? dialogContext.l10n.save,
          destructive: destructive,
          loading: loading,
          onPressed: onConfirm == null
              ? () => Navigator.pop(dialogContext, true)
              : () async {
                  await onConfirm();
                },
        ),
      ],
    ),
  );
}
