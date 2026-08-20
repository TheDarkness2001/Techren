import 'package:flutter/material.dart';

import '../../domain/entities/learning_cms.dart';
import '../theme/app_durations.dart';
import '../theme/app_radius.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

/// Accent cycle for level planets / unit chips (matches the Words mock).
const playgroundAccents = <Color>[
  Color(0xFF38BDF8),
  Color(0xFF60A5FA),
  Color(0xFF34D399),
  Color(0xFFFBBF24),
  Color(0xFFF472B6),
  Color(0xFFA78BFA),
];

Color playgroundAccentAt(int index) => playgroundAccents[index.abs() % playgroundAccents.length];

class PlaygroundTab<T> {
  const PlaygroundTab({required this.id, required this.label, required this.icon});

  final T id;
  final String label;
  final IconData icon;
}

/// Gradient pill tabs — no boxed chrome.
class PlaygroundTabBar<T> extends StatelessWidget {
  const PlaygroundTabBar({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<PlaygroundTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in tabs)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: _PlaygroundTabChip(
                label: tab.label,
                icon: tab.icon,
                selected: tab.id == selected,
                onTap: () => onSelected(tab.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _PlaygroundTabChip extends StatelessWidget {
  const _PlaygroundTabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.semantic.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: AppCurves.standard,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              gradient: selected
                  ? const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    )
                  : null,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: selected ? Colors.white : muted),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                    color: selected ? Colors.white : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlaygroundLevelItem {
  const PlaygroundLevelItem({required this.id, required this.name});

  final String id;
  final String name;
}

/// Horizontal planet cards for CEFR / named levels.
class PlaygroundLevelStrip extends StatelessWidget {
  const PlaygroundLevelStrip({
    super.key,
    required this.levels,
    required this.selectedId,
    required this.onSelected,
    this.title = 'Select a Level',
  });

  final List<PlaygroundLevelItem> levels;
  final String? selectedId;
  final void Function(PlaygroundLevelItem level) onSelected;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) {
      return Text('No levels yet.', style: TextStyle(color: context.semantic.textMuted));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: levels.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final level = levels[index];
              return _LevelPlanetCard(
                name: level.name,
                accent: playgroundAccentAt(index),
                selected: level.id == selectedId,
                onTap: () => onSelected(level),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LevelPlanetCard extends StatelessWidget {
  const _LevelPlanetCard({
    required this.name,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;

    return Semantics(
      button: true,
      selected: selected,
      label: name,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardLarge,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            width: 132,
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: AppRadius.cardLarge,
              border: Border.all(
                color: selected ? const Color(0xFF818CF8) : semantic.border,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: scheme.brightness == Brightness.dark ? 0.28 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    PlaygroundPlanet(color: accent),
                    const Spacer(),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                if (selected)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: _SelectedCheck(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedCheck extends StatelessWidget {
  const _SelectedCheck();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)]),
      ),
      child: const Icon(Icons.check, size: 14, color: Colors.white),
    );
  }
}

class PlaygroundPlanet extends StatelessWidget {
  const PlaygroundPlanet({super.key, required this.color, this.size = 56});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ring = size * 0.78;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: 1),
              ],
            ),
          ),
          Container(
            width: ring,
            height: ring,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.45)],
                center: const Alignment(-0.35, -0.4),
              ),
            ),
          ),
          Transform.rotate(
            angle: -0.4,
            child: Container(
              width: ring * 1.05,
              height: ring * 0.22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: color.withValues(alpha: 0.85), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlaygroundUnitItem {
  const PlaygroundUnitItem({
    required this.id,
    required this.title,
    required this.order,
    required this.countLabel,
    required this.description,
    required this.progressPercent,
    required this.mastered,
    required this.inReview,
    required this.total,
    this.masteredLabel = 'Mastered',
    this.reviewLabel = 'In Review',
    this.totalLabel = 'Total',
    this.locked = false,
  });

  final String id;
  final String title;
  final int order;
  final String countLabel;
  final String description;
  final int progressPercent;
  final int mastered;
  final int inReview;
  final int total;
  final String masteredLabel;
  final String reviewLabel;
  final String totalLabel;
  final bool locked;
}

/// Two-pane unit picker + detail (no overall-progress sidebar).
class PlaygroundLessonDashboard extends StatelessWidget {
  const PlaygroundLessonDashboard({
    super.key,
    required this.units,
    required this.selectedId,
    required this.onSelect,
    required this.onPractice,
    this.onSecondary,
    this.primaryLabel = 'Continue Practice',
    this.secondaryLabel = 'View Words',
    this.emptyMessage = 'No lessons yet.',
  });

  final List<PlaygroundUnitItem> units;
  final String? selectedId;
  final ValueChanged<PlaygroundUnitItem> onSelect;
  final VoidCallback? onPractice;
  final VoidCallback? onSecondary;
  final String primaryLabel;
  final String secondaryLabel;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Text(emptyMessage, style: TextStyle(color: context.semantic.textMuted)),
      );
    }

    final selected = units.cast<PlaygroundUnitItem?>().firstWhere(
          (u) => u!.id == selectedId,
          orElse: () => units.first,
        )!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 720;
        final list = _UnitList(
          units: units,
          selectedId: selected.id,
          onSelect: onSelect,
        );
        final detail = _UnitDetail(
          unit: selected,
          onPractice: selected.locked ? null : onPractice,
          onSecondary: selected.locked ? null : onSecondary,
          primaryLabel: primaryLabel,
          secondaryLabel: secondaryLabel,
        );

        if (!sideBySide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 280, child: list),
              const SizedBox(height: AppSpacing.md),
              detail,
            ],
          );
        }

        return SizedBox(
          height: 420,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 280, child: list),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: detail),
            ],
          ),
        );
      },
    );
  }
}

class _UnitList extends StatelessWidget {
  const _UnitList({
    required this.units,
    required this.selectedId,
    required this.onSelect,
  });

  final List<PlaygroundUnitItem> units;
  final String selectedId;
  final ValueChanged<PlaygroundUnitItem> onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: semantic.border),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.sm),
        itemCount: units.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          final unit = units[index];
          final selected = unit.id == selectedId;
          final accent = playgroundAccentAt(index);
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(unit),
              borderRadius: AppRadius.card,
              child: AnimatedContainer(
                duration: AppDurations.fast,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.card,
                  color: selected ? const Color(0xFF6366F1).withValues(alpha: 0.14) : Colors.transparent,
                  border: Border.all(
                    color: selected ? const Color(0xFF818CF8).withValues(alpha: 0.7) : Colors.transparent,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        unit.locked ? Icons.lock_outline : Icons.auto_stories_outlined,
                        size: 18,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        unit.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UnitDetail extends StatelessWidget {
  const _UnitDetail({
    required this.unit,
    required this.onPractice,
    required this.primaryLabel,
    required this.secondaryLabel,
    this.onSecondary,
  });

  final PlaygroundUnitItem unit;
  final VoidCallback? onPractice;
  final VoidCallback? onSecondary;
  final String primaryLabel;
  final String secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;
    final progress = unit.progressPercent.clamp(0, 100) / 100;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.cardLarge,
        border: Border.all(color: semantic.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(unit.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: AppSpacing.xxs),
          Text(unit.countLabel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: semantic.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          Text(unit.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: semantic.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  Container(color: semantic.surfaceContainer),
                  FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${unit.progressPercent.clamp(0, 100)}%',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF818CF8),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatMini(
                  icon: Icons.favorite_outline,
                  value: '${unit.mastered}',
                  label: unit.masteredLabel,
                  color: const Color(0xFFF472B6),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatMini(
                  icon: Icons.sync,
                  value: '${unit.inReview}',
                  label: unit.reviewLabel,
                  color: const Color(0xFF38BDF8),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatMini(
                  icon: Icons.menu_book_outlined,
                  value: '${unit.total}',
                  label: unit.totalLabel,
                  color: const Color(0xFFA78BFA),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (constraints.maxHeight.isFinite) const Spacer(),
          Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.button,
                    gradient: onPractice == null
                        ? null
                        : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)]),
                    color: onPractice == null ? semantic.surfaceContainer : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onPractice,
                      borderRadius: AppRadius.button,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: onPractice == null ? semantic.textMuted : Colors.white,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              primaryLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: onPractice == null ? semantic.textMuted : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (onSecondary != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSecondary,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text(secondaryLabel),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: scheme.onSurface,
                      side: BorderSide(color: semantic.border),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
          );
        },
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: semantic.surfaceContainer.withValues(alpha: 0.65),
        borderRadius: AppRadius.card,
        border: Border.all(color: semantic.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: semantic.textMuted)),
        ],
      ),
    );
  }
}

PlaygroundUnitItem playgroundUnitFromCmsLesson(
  CmsLesson lesson, {
  required String noun,
}) {
  final examUnlocked = lesson.examUnlockedFor.isNotEmpty;
  return PlaygroundUnitItem(
    id: lesson.id,
    title: lesson.name,
    order: lesson.order,
    countLabel: '${lesson.wordCount} $noun',
    description:
        'Work through this unit at your own pace. Keep going until these $noun feel automatic.',
    progressPercent: examUnlocked ? 40 : 0,
    mastered: 0,
    inReview: examUnlocked ? lesson.wordCount : 0,
    total: lesson.wordCount,
    totalLabel: 'Total',
    locked: false,
  );
}
