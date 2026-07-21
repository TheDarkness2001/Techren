import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_durations.dart';
import '../theme/app_radius.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// Wraps a [TabBar] in the premium hub chrome (border, shadow, padding).
class HubTabBarShell extends StatelessWidget {
  const HubTabBarShell({super.key, required this.tabBar});

  final TabBar tabBar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: semantic.border),
          boxShadow: AppShadows.card,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: tabBar,
      ),
    );
  }
}

/// Section title for hub screens — consistent level/group headers (Phase F.1).
class HubSectionHeader extends StatelessWidget {
  const HubSectionHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    return Semantics(
      header: true,
      label: subtitle != null ? '$title. $subtitle' : title,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.micro),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Premium hub row card — lessons, exercises, achievements, leaderboard rows.
/// Replaces Card+ListTile pattern across student learning hubs (Phase F.1).
class AppHubCard extends StatefulWidget {
  const AppHubCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.icon,
    this.leadingLabel,
    this.locked = false,
    this.emphasized = false,
    this.progressPercent,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData? icon;
  final String? leadingLabel;
  final bool locked;
  final bool emphasized;
  final int? progressPercent;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  State<AppHubCard> createState() => _AppHubCardState();
}

class _AppHubCardState extends State<AppHubCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    final enabled = !widget.locked && widget.onTap != null;
    final accent = widget.locked ? muted : widget.accentColor;
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;

    final card = AnimatedContainer(
      duration: AppDurations.fast,
      curve: AppCurves.standard,
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: _hovered && enabled ? accent.withValues(alpha: 0.35) : semantic.border,
        ),
        boxShadow: _hovered && enabled
            ? [BoxShadow(color: accent.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 3))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? widget.onTap : null,
          borderRadius: AppRadius.card,
          child: Opacity(
            opacity: widget.locked ? 0.72 : 1,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _LeadingBadge(
                    accentColor: accent,
                    icon: widget.icon,
                    label: widget.leadingLabel,
                    progressPercent: widget.progressPercent,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.micro),
                        Text(widget.subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted)),
                        if (widget.progressPercent != null && widget.icon == null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: LinearProgressIndicator(
                              value: (widget.progressPercent!.clamp(0, 100)) / 100,
                              minHeight: 4,
                              backgroundColor: semantic.surfaceContainer,
                              color: accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  widget.trailing ??
                      Icon(
                        widget.locked ? Icons.lock_outline : Icons.arrow_forward_rounded,
                        color: muted,
                        size: 20,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      label: widget.locked
          ? '${widget.title}, locked'
          : widget.emphasized
              ? '${widget.title}, unread. ${widget.subtitle}'
              : '${widget.title}. ${widget.subtitle}',
      button: enabled,
      enabled: enabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: card,
      ),
    );
  }
}

class _LeadingBadge extends StatelessWidget {
  const _LeadingBadge({
    required this.accentColor,
    this.icon,
    this.label,
    this.progressPercent,
  });

  final Color accentColor;
  final IconData? icon;
  final String? label;
  final int? progressPercent;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      final progress = progressPercent;
      if (progress != null) {
        return SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress.clamp(0, 100) / 100,
                strokeWidth: 3,
                backgroundColor: accentColor.withValues(alpha: 0.12),
                color: accentColor,
              ),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
        );
      }
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor.withValues(alpha: 0.18), accentColor.withValues(alpha: 0.08)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: accentColor, size: 22),
      );
    }

    return CircleAvatar(
      radius: 22,
      backgroundColor: accentColor.withValues(alpha: 0.15),
      child: Text(
        label ?? '',
        style: TextStyle(color: accentColor, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

/// Media hub card — video lessons with thumbnail + watch progress (Phase F.1).
class AppHubMediaCard extends StatefulWidget {
  const AppHubMediaCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.imageUrl,
    this.progressPercent = 0,
    this.completed = false,
    this.accentColor = AppColors.primary,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? imageUrl;
  final int progressPercent;
  final bool completed;
  final Color accentColor;

  @override
  State<AppHubMediaCard> createState() => _AppHubMediaCardState();
}

class _AppHubMediaCardState extends State<AppHubMediaCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    final progressColor = widget.completed ? context.semantic.success : widget.accentColor;

    return Semantics(
      label: '${widget.title}. ${widget.completed ? 'Completed' : '${widget.progressPercent}% watched'}',
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.card,
            border: Border.all(
              color: _hovered ? widget.accentColor.withValues(alpha: 0.35) : context.semantic.border,
            ),
            boxShadow: _hovered ? [BoxShadow(color: widget.accentColor.withValues(alpha: 0.1), blurRadius: 14)] : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(widget.imageUrl!, fit: BoxFit.cover),
                          Container(color: Colors.black26),
                          const Center(
                            child: Icon(Icons.play_circle_fill, size: 52, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.micro),
                        Text(widget.subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted)),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: (widget.progressPercent.clamp(0, 100)) / 100,
                            minHeight: 5,
                            backgroundColor: context.semantic.surfaceContainer,
                            color: progressColor,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          widget.completed ? 'Completed' : '${widget.progressPercent}% watched',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Leaderboard row — rank badge, name, subtitle, score (Phase G.1).
class LeaderboardHubCard extends StatelessWidget {
  const LeaderboardHubCard({
    super.key,
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.highlighted = false,
    this.accentColor = AppColors.primary,
  });

  final int rank;
  final String title;
  final String subtitle;
  final String trailing;
  final bool highlighted;
  final Color accentColor;

  Color _accent(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (highlighted) return scheme.primary;
    if (rank == 1) return const Color(0xFFD97706);
    if (rank == 2) return scheme.onSurfaceVariant;
    if (rank == 3) return const Color(0xFFB45309);
    return accentColor;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    return AppHubCard(
      title: title,
      subtitle: subtitle,
      accentColor: accent,
      leadingLabel: '#$rank',
      trailing: Text(
        trailing,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: accent,
            ),
      ),
    );
  }
}

/// Staff/admin list row — notifications, wallet, penalties (Phase G.3).
class AppAdminRowCard extends StatelessWidget {
  const AppAdminRowCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.accentColor = AppColors.primary,
    this.onTap,
    this.trailing,
    this.menuItems,
    this.onMenuSelected,
    this.highlighted = false,
    this.locked = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final List<PopupMenuEntry<String>>? menuItems;
  final void Function(String)? onMenuSelected;
  final bool highlighted;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final trailingWidget = menuItems != null && menuItems!.isNotEmpty
        ? PopupMenuButton<String>(
            tooltip: 'Actions',
            onSelected: onMenuSelected,
            itemBuilder: (_) => menuItems!,
          )
        : trailing;

    return AppHubCard(
      title: title,
      subtitle: subtitle,
      accentColor: highlighted ? AppColors.primary : accentColor,
      icon: icon,
      emphasized: highlighted,
      locked: locked,
      onTap: onTap,
      trailing: trailingWidget,
    );
  }
}
