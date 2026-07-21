import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_hub_card.dart';

/// Compact selectable row for CMS tree navigation (levels, lessons).
class CmsTreeItem extends StatefulWidget {
  const CmsTreeItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool dense;

  @override
  State<CmsTreeItem> createState() => _CmsTreeItemState();
}

class _CmsTreeItemState extends State<CmsTreeItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    final accent = widget.selected ? AppColors.primary : AppColors.secondary;

    return Semantics(
      label: widget.subtitle == null ? widget.title : '${widget.title}. ${widget.subtitle}',
      button: true,
      selected: widget.selected,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          margin: EdgeInsets.only(bottom: widget.dense ? AppSpacing.micro : AppSpacing.xs),
          decoration: BoxDecoration(
            color: widget.selected ? AppColors.primaryContainer.withValues(alpha: 0.35) : Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.chip,
            border: Border.all(
              color: widget.selected
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : _hovered
                      ? AppColors.border
                      : Colors.transparent,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: AppRadius.chip,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: widget.dense ? AppSpacing.xs : AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.selected ? Icons.folder_open_outlined : Icons.folder_outlined,
                      size: 18,
                      color: accent,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                                ),
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: AppSpacing.micro),
                            Text(
                              widget.subtitle!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.trailing != null) widget.trailing!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Content row card for words, sentences, and listening exercises.
class CmsContentCard extends StatelessWidget {
  const CmsContentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
    this.leadingIcon,
    this.leadingColor,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final IconData? leadingIcon;
  final Color? leadingColor;

  @override
  Widget build(BuildContext context) {
    return AppHubCard(
      title: title,
      subtitle: subtitle,
      accentColor: leadingColor ?? AppColors.primary,
      icon: leadingIcon ?? Icons.article_outlined,
      trailing: PopupMenuButton<String>(
        tooltip: 'Content actions',
        onSelected: (action) {
          if (action == 'edit') onEdit();
          if (action == 'delete') onDelete();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
      onTap: onEdit,
    );
  }
}

/// Section header for CMS tree panels.
class CmsTreeSectionHeader extends StatelessWidget {
  const CmsTreeSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return HubSectionHeader(title: title);
  }
}
