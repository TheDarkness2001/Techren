import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_radius.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

class EntityMeta {
  const EntityMeta({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;
}

/// Groups-style list row: icon, title, meta columns, trailing actions.
class EntityListCard extends StatefulWidget {
  const EntityListCard({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.iconColor = AppColors.primary,
    this.footer,
    this.metas = const [],
    this.primaryAction,
    this.menu,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? footer;
  final List<EntityMeta> metas;
  final Widget? primaryAction;
  final Widget? menu;
  final VoidCallback? onTap;

  @override
  State<EntityListCard> createState() => _EntityListCardState();
}

class _EntityListCardState extends State<EntityListCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 860;

    final identity = Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: widget.iconColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(widget.icon, color: widget.iconColor, size: 22),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: semantic.textMuted),
                ),
              ],
              if (widget.footer != null) ...[
                const SizedBox(height: AppSpacing.xs),
                widget.footer!,
              ],
            ],
          ),
        ),
      ],
    );

    final metaRow = Row(
      children: [
        for (var i = 0; i < widget.metas.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.lg),
          Expanded(child: _MetaBlock(meta: widget.metas[i])),
        ],
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.primaryAction != null) widget.primaryAction!,
        if (widget.menu != null) widget.menu!,
      ],
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.card,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: AppRadius.card,
              border: Border.all(
                color: _hovered ? AppColors.primary.withValues(alpha: 0.4) : semantic.border,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: wide
                ? Row(
                    children: [
                      Expanded(flex: 3, child: identity),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(flex: 5, child: metaRow),
                      const SizedBox(width: AppSpacing.md),
                      actions,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      identity,
                      if (widget.metas.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        metaRow,
                      ],
                      if (widget.primaryAction != null || widget.menu != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Align(alignment: Alignment.centerRight, child: actions),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _MetaBlock extends StatelessWidget {
  const _MetaBlock({required this.meta});

  final EntityMeta meta;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    return Row(
      children: [
        Icon(meta.icon, size: 16, color: AppColors.primaryLight),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meta.label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted)),
              Text(
                meta.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
