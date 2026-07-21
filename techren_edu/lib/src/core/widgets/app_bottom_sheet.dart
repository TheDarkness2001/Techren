import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

/// Draggable bottom sheet with snap points — Phase F.4 design system.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  double initialChildSize = 0.55,
  double minChildSize = 0.35,
  double maxChildSize = 0.92,
  bool useDraggableSheet = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: true,
    useSafeArea: true,
    builder: (sheetContext) {
      if (!useDraggableSheet) {
        return builder(sheetContext);
      }
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        builder: (context, scrollController) => _AppBottomSheetScrollScope(
          scrollController: scrollController,
          child: builder(sheetContext),
        ),
      );
    },
  );
}

class _AppBottomSheetScrollScope extends InheritedWidget {
  const _AppBottomSheetScrollScope({
    required this.scrollController,
    required super.child,
  });

  final ScrollController scrollController;

  static ScrollController? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_AppBottomSheetScrollScope>()?.scrollController;
  }

  @override
  bool updateShouldNotify(_AppBottomSheetScrollScope oldWidget) {
    return scrollController != oldWidget.scrollController;
  }
}

/// Standard bottom sheet layout — title, optional subtitle, body, footer actions.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.children = const [],
    this.footer,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scrollController = _AppBottomSheetScrollScope.of(context);
    final muted = context.semantic.textMuted;
    final bodyPadding = padding ?? const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted)),
        ],
        const SizedBox(height: AppSpacing.md),
        ...children,
        if (footer != null) ...[
          const SizedBox(height: AppSpacing.lg),
          footer!,
        ],
        SizedBox(height: MediaQuery.paddingOf(context).bottom),
      ],
    );

    if (scrollController != null) {
      return ListView(
        controller: scrollController,
        padding: bodyPadding,
        children: [content],
      );
    }

    return Padding(padding: bodyPadding, child: content);
  }
}

/// Compact action row for sheet footers.
class AppBottomSheetActions extends StatelessWidget {
  const AppBottomSheetActions({
    super.key,
    this.primary,
    this.secondary,
    this.destructive,
  });

  final Widget? primary;
  final Widget? secondary;
  final Widget? destructive;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (primary != null) primary!,
        if (secondary != null) ...[
          const SizedBox(height: AppSpacing.sm),
          secondary!,
        ],
        if (destructive != null) ...[
          const SizedBox(height: AppSpacing.sm),
          destructive!,
        ],
      ],
    );
  }
}

/// Status chip used in detail sheets.
class AppSheetStatusChip extends StatelessWidget {
  const AppSheetStatusChip({super.key, required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: active ? AppColors.successContainer : AppColors.dangerContainer,
        borderRadius: AppRadius.chip,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: active ? AppColors.success : AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
