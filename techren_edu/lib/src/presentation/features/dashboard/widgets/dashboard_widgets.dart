import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';

/// Compact dashboard stat — icon + value + label (reference UI).
class DashboardStatCard extends StatefulWidget {
  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accentColor,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  State<DashboardStatCard> createState() => _DashboardStatCardState();
}

class _DashboardStatCardState extends State<DashboardStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.accentColor ?? scheme.primary;
    final muted = context.semantic.textMuted;
    final border = context.semantic.border;

    return Semantics(
      label: '${widget.label}: ${widget.value}',
      button: widget.onTap != null,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.standard,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: _hovered ? accent.withValues(alpha: 0.25) : border),
            boxShadow: _hovered ? AppShadows.cardHover : AppShadows.card,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: AppRadius.card,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(widget.icon, color: accent, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.value,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  color: scheme.onSurface,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.micro),
                          Text(
                            widget.label,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

/// Four compact stats in one row (wraps on narrow screens).
class DashboardStatRow extends StatelessWidget {
  const DashboardStatRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1000 ? 4 : width >= 640 ? 2 : 1;
        if (columns == 1) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                children[i],
              ],
            ],
          );
        }
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: columns >= 4 ? 3.4 : 2.8,
          children: children,
        );
      },
    );
  }
}

/// Quick-action grid — replaces plain [ActionChip] wraps on the dashboard.
class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({
    super.key,
    required this.actions,
    this.compact = false,
  });

  final List<QuickAction> actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = constraints.maxWidth >= 900 ? 118.0 : 104.0;
          return Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final action in actions)
                SizedBox(
                  width: tileWidth,
                  child: _CompactQuickActionTile(action: action),
                ),
            ],
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 700 ? 4 : width >= 420 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.35,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) => _QuickActionTile(action: actions[index]),
        );
      },
    );
  }
}

class QuickAction {
  const QuickAction({required this.label, required this.icon, required this.route});

  final String label;
  final IconData icon;
  final String route;
}

class _CompactQuickActionTile extends StatefulWidget {
  const _CompactQuickActionTile({required this.action});

  final QuickAction action;

  @override
  State<_CompactQuickActionTile> createState() => _CompactQuickActionTileState();
}

class _CompactQuickActionTileState extends State<_CompactQuickActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.semantic.textMuted;
    final border = context.semantic.border;

    return Semantics(
      label: widget.action.label,
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.standard,
          height: 88,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: _hovered ? scheme.primary.withValues(alpha: 0.25) : border),
            boxShadow: _hovered ? AppShadows.cardHover : AppShadows.card,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go(widget.action.route),
              borderRadius: AppRadius.card,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.action.icon, color: scheme.primary, size: 22),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.action.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: muted,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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

class _QuickActionTile extends StatefulWidget {
  const _QuickActionTile({required this.action});

  final QuickAction action;

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = context.semantic.border;

    return Semantics(
      label: widget.action.label,
      button: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppCurves.standard,
          decoration: BoxDecoration(
            color: _hovered ? scheme.primaryContainer.withValues(alpha: 0.5) : scheme.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: _hovered ? scheme.primary.withValues(alpha: 0.3) : border),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go(widget.action.route),
              borderRadius: AppRadius.card,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.action.icon, color: scheme.primary, size: 22),
                    const Spacer(),
                    Text(
                      widget.action.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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

/// Welcome panel with three overview mini-cards (reference dashboard).
class DashboardWelcomePanel extends StatelessWidget {
  const DashboardWelcomePanel({
    super.key,
    required this.userName,
    required this.roleLabel,
    required this.prefix,
  });

  final String userName;
  final String roleLabel;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.semantic.textMuted;
    final border = context.semantic.border;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: border),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, $userName!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            "You're logged in as $roleLabel. Today's Overview",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final cards = [
                _OverviewMiniCard(
                  title: "Today's Overview",
                  description: "Check today's attendance, upcoming exams, and pending payments.",
                  icon: Icons.calendar_today_outlined,
                  onTap: () => context.go('$prefix/attendance'),
                ),
                _OverviewMiniCard(
                  title: 'Reports',
                  description: 'Generate detailed reports on student performance, payments, and attendance.',
                  icon: Icons.bar_chart_outlined,
                  onTap: () => context.go('$prefix/revenue-reports'),
                ),
                _OverviewMiniCard(
                  title: 'Settings',
                  description: 'Configure system preferences and manage user permissions.',
                  icon: Icons.settings_outlined,
                  onTap: () => context.go('$prefix/settings'),
                ),
              ];
              if (wide) {
                return Row(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.md),
                      Expanded(child: cards[i]),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    cards[i],
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OverviewMiniCard extends StatefulWidget {
  const _OverviewMiniCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_OverviewMiniCard> createState() => _OverviewMiniCardState();
}

class _OverviewMiniCardState extends State<_OverviewMiniCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.semantic.textMuted;
    final border = context.semantic.border;
    final fill = context.semantic.surfaceContainer;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        decoration: BoxDecoration(
          color: _hovered ? fill : scheme.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: _hovered ? scheme.primary.withValues(alpha: 0.2) : border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppRadius.card,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(widget.icon, color: scheme.primary, size: 22),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    widget.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted, height: 1.35),
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

/// Compact list row for recent branches / students on the dashboard.
class DashboardListTile extends StatelessWidget {
  const DashboardListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.semantic.textMuted;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(icon, color: scheme.primary, size: 20),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(subtitle, style: TextStyle(color: muted, fontSize: 12)),
        trailing: trailing,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
    );
  }
}
