import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/person_avatar.dart';
import '../../../../domain/entities/learning_cms.dart';
import '../../../../domain/entities/scheduling.dart';
import '../../../../domain/entities/sentences.dart';
import '../../../../domain/entities/student_progress.dart';
import '../../../../domain/entities/words.dart';

enum SentencesHubTab { practice, leaderboard, lessons, permissions, studentProgress }

enum SentencesPracticeStep { languages, levels, classes, practice }

class SentencesHubTabBar extends StatelessWidget {
  const SentencesHubTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final SentencesHubTab selected;
  final ValueChanged<SentencesHubTab> onSelected;

  static const _labels = {
    SentencesHubTab.practice: 'Practice',
    SentencesHubTab.leaderboard: 'Leaderboard',
    SentencesHubTab.lessons: 'Lessons',
    SentencesHubTab.permissions: 'Permissions',
    SentencesHubTab.studentProgress: 'Student Progress',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xxs),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in SentencesHubTab.values)
              _TabButton(
                label: _labels[tab]!,
                selected: selected == tab,
                onTap: () => onSelected(tab),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.micro),
        child: Material(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            hoverColor: selected ? null : scheme.onSurface.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                  color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SentencesSubNavBar extends StatelessWidget {
  const SentencesSubNavBar({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
    );
  }
}

class SentencesBackButton extends StatelessWidget {
  const SentencesBackButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF5A6268),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class SentencesLanguageGrid extends StatelessWidget {
  const SentencesLanguageGrid({
    super.key,
    required this.languages,
    required this.onLanguageTap,
  });

  final List<LearningLanguage> languages;
  final ValueChanged<LearningLanguage> onLanguageTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Select a Language', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        if (languages.isEmpty)
          AspectRatio(
            aspectRatio: 2.6,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: AppRadius.card,
                border: Border.all(color: context.semantic.border),
                boxShadow: AppShadows.card,
              ),
              child: Text(
                'No languages yet.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.semantic.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 5
                  : constraints.maxWidth >= 700
                      ? 4
                      : constraints.maxWidth >= 480
                          ? 3
                          : 2;
              final spacing = AppSpacing.sm;
              final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final language in languages)
                    SizedBox(
                      width: cardWidth,
                      height: 88,
                      child: Material(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: AppRadius.card,
                          child: InkWell(
                            onTap: () => onLanguageTap(language),
                            borderRadius: AppRadius.card,
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.card,
                                border: Border.all(color: context.semantic.border),
                                boxShadow: AppShadows.card,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.language, size: 26, color: AppColors.primary.withValues(alpha: 0.75)),
                                  const SizedBox(height: AppSpacing.xs),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                    child: Text(
                                      language.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class SentencesLevelGrid extends StatelessWidget {
  const SentencesLevelGrid({
    super.key,
    required this.levels,
    required this.onLevelTap,
  });

  final List<CmsLevel> levels;
  final ValueChanged<CmsLevel> onLevelTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Select a Level', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final level in levels)
              SizedBox(
                width: 112,
                height: 96,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppRadius.card,
                  child: InkWell(
                    onTap: () => onLevelTap(level),
                    borderRadius: AppRadius.card,
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.card,
                        border: Border.all(color: context.semantic.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📚', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: AppSpacing.sm),
                          Text(level.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class SentencesClassGrid extends StatelessWidget {
  const SentencesClassGrid({
    super.key,
    required this.levelName,
    required this.lessons,
    required this.onLessonTap,
  });

  final String levelName;
  final List<CmsLesson> lessons;
  final ValueChanged<CmsLesson> onLessonTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$levelName — Select a Class',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final lesson in lessons)
              SizedBox(
                width: 220,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppRadius.card,
                  child: InkWell(
                    onTap: () => onLessonTap(lesson),
                    borderRadius: AppRadius.card,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.card,
                        border: Border.all(color: context.semantic.border),
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 88,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: AppColors.primary,
                                    child: Text('${lesson.order}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(lesson.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        Text('📝 Sentences', style: TextStyle(color: context.semantic.textMuted, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class SentencesAddLanguageCard extends StatelessWidget {
  const SentencesAddLanguageCard({
    super.key,
    required this.controller,
    required this.onAdd,
  });

  final TextEditingController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add Language', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Language name (e.g., English)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(onPressed: onAdd, child: const Text('Add')),
            ],
          ),
        ],
      ),
    );
  }
}

class SentencesLanguageListTile extends StatelessWidget {
  const SentencesLanguageListTile({
    super.key,
    required this.language,
    required this.onDelete,
  });

  final LearningLanguage language;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.language, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(language.name, style: const TextStyle(fontWeight: FontWeight.w700))),
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
    );
  }
}

class SentencesLeaderboardTable extends StatelessWidget {
  const SentencesLeaderboardTable({super.key, required this.entries});

  final List<SentencesLeaderboardEntry> entries;

  String _medalForRank(int rank) {
    return switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Top 10 Sentence Writers', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: context.semantic.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text('RANK', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(flex: 5, child: Text('STUDENT NAME', style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(child: Text('ATTEMPTS', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(child: Text('CORRECT', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700))),
                    Expanded(child: Text('ACCURACY', textAlign: TextAlign.end, style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text('No leaderboard data yet.', style: TextStyle(color: muted)),
                )
              else
                for (final entry in entries)
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                _medalForRank(entry.rank).isNotEmpty ? _medalForRank(entry.rank) : '${entry.rank}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.name,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                  ),
                                  if (entry.studentCode.isNotEmpty)
                                    Text(
                                      '#${entry.studentCode}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(child: Text('${entry.totalAttempts}', textAlign: TextAlign.center)),
                            Expanded(child: Text('${entry.totalCorrect}', textAlign: TextAlign.center)),
                            Expanded(child: Text('${entry.accuracy}%', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700))),
                          ],
                        ),
                      ),
                      if (entry != entries.last) const Divider(height: 1),
                    ],
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class SentencesGroupCard extends StatelessWidget {
  const SentencesGroupCard({
    super.key,
    required this.item,
    required this.onManageLessons,
    this.actionLabel = 'Unlock / Lock Lessons',
  });

  final UnifiedGroupView item;
  final VoidCallback onManageLessons;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final group = item.group;
    final schedule = item.schedule;
    final subject = group.subjectName ?? 'General';
    final time = schedule != null ? '${schedule.startTime}-${schedule.endTime}' : '—';
    final teacher = schedule?.teacherName ?? '—';

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_2_outlined, color: Color(0xFF7C3AED)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.semantic.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('ID: ${group.groupName}', style: TextStyle(color: context.semantic.textMuted, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(group.groupName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          Text(subject, style: TextStyle(color: context.semantic.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          _Meta(icon: Icons.access_time, text: time),
          _Meta(icon: Icons.person_outline, text: teacher),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var i = 0; i < 3 && i < group.studentCount; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: context.semantic.surfaceContainer,
                    child: Icon(Icons.person, size: 14, color: context.semantic.textMuted),
                  ),
                ),
              if (group.studentCount > 3)
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text('+${group.studentCount - 3}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onManageLessons,
            icon: const Icon(Icons.lock_open_outlined, size: 18),
            label: Text(actionLabel),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: context.semantic.textMuted),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(text, style: TextStyle(color: context.semantic.textMuted, fontSize: 13))),
        ],
      ),
    );
  }
}

/// Level + lesson lock controls for one group.
class SentencesLessonAccessPanel extends StatelessWidget {
  const SentencesLessonAccessPanel({
    super.key,
    required this.groupName,
    required this.levels,
    required this.lessonsByLevel,
    required this.groupId,
    required this.busyIds,
    required this.onTogglePractice,
    required this.onToggleExam,
    required this.onBack,
    this.showBackButton = true,
    this.showExamToggles = true,
    this.bulkBusy = false,
    this.onBulkUnlockLevel,
  });

  final String groupName;
  final List<CmsLevel> levels;
  final Map<String, List<CmsLesson>> lessonsByLevel;
  final String groupId;
  final Set<String> busyIds;
  final Future<void> Function(CmsLevel level, bool unlock) onTogglePractice;
  final Future<void> Function(CmsLesson lesson, bool unlock) onToggleExam;
  final VoidCallback onBack;
  final bool showBackButton;
  final bool showExamToggles;
  final bool bulkBusy;
  final Future<void> Function(CmsLevel level, bool unlock)? onBulkUnlockLevel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBackButton) ...[
          SentencesBackButton(label: 'Back to Groups', onPressed: onBack),
          const SizedBox(height: AppSpacing.md),
        ],
        if (levels.isEmpty)
          const EmptyState(
            title: 'No levels',
            message: 'Create levels under Lessons first.',
            icon: Icons.lock_outline,
          )
        else
          for (final level in levels) ...[
            _LevelAccessCard(
              level: level,
              groupId: groupId,
              lessons: showExamToggles ? (lessonsByLevel[level.id] ?? const []) : const [],
              busy: busyIds.contains(level.id) || bulkBusy,
              busyLessonIds: busyIds,
              onTogglePractice: (unlock) => onTogglePractice(level, unlock),
              onToggleExam: onToggleExam,
              onBulkUnlockLevel: onBulkUnlockLevel == null
                  ? null
                  : (unlock) => onBulkUnlockLevel!(level, unlock),
              showExamToggles: showExamToggles,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _LockActionButton extends StatelessWidget {
  const _LockActionButton({
    required this.unlocked,
    required this.onPressed,
    this.labelWhenLocked = 'Unlock',
    this.labelWhenUnlocked = 'Lock',
    this.compact = false,
  });

  final bool unlocked;
  final VoidCallback? onPressed;
  final String labelWhenLocked;
  final String labelWhenUnlocked;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = unlocked ? labelWhenUnlocked : labelWhenLocked;
    final icon = unlocked ? Icons.lock_outline : Icons.lock_open;
    if (unlocked) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: compact ? 16 : 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          visualDensity: compact ? VisualDensity.compact : null,
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs)
              : null,
        ),
      );
    }
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: compact ? 16 : 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        visualDensity: compact ? VisualDensity.compact : null,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs)
            : null,
      ),
    );
  }
}

class _LevelAccessCard extends StatelessWidget {
  const _LevelAccessCard({
    required this.level,
    required this.groupId,
    required this.lessons,
    required this.busy,
    required this.busyLessonIds,
    required this.onTogglePractice,
    required this.onToggleExam,
    this.onBulkUnlockLevel,
    this.showExamToggles = true,
  });

  final CmsLevel level;
  final String groupId;
  final List<CmsLesson> lessons;
  final bool busy;
  final Set<String> busyLessonIds;
  final ValueChanged<bool> onTogglePractice;
  final Future<void> Function(CmsLesson lesson, bool unlock) onToggleExam;
  final ValueChanged<bool>? onBulkUnlockLevel;
  final bool showExamToggles;

  bool get _practiceOn => level.isPracticeUnlockedFor(groupId);

  bool get _allUnlocked {
    if (!_practiceOn) return false;
    if (!showExamToggles || lessons.isEmpty) return true;
    return lessons.every((l) => l.isExamUnlockedFor(groupId));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _practiceOn ? Icons.lock_open : Icons.lock_outline,
                color: _practiceOn ? scheme.primary : context.semantic.textMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(level.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              if (!showExamToggles)
                _LockActionButton(
                  unlocked: _practiceOn,
                  onPressed: busy ? null : () => onTogglePractice(!_practiceOn),
                ),
            ],
          ),
          if (showExamToggles && onBulkUnlockLevel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: _LockActionButton(
                unlocked: _allUnlocked,
                labelWhenLocked: 'Unlock all ${level.name}',
                labelWhenUnlocked: 'Lock all ${level.name}',
                onPressed: busy ? null : () => onBulkUnlockLevel!(!_allUnlocked),
              ),
            ),
          ],
          if (showExamToggles) ...[
            const SizedBox(height: AppSpacing.sm),
            _AccessRow(
              title: 'Practice',
              subtitle: _practiceOn ? 'Unlocked for this group' : 'Locked for this group',
              unlocked: _practiceOn,
              busy: busy,
              onPressed: () => onTogglePractice(!_practiceOn),
            ),
            for (final lesson in lessons)
              _AccessRow(
                title: lesson.name,
                subtitle: lesson.isExamUnlockedFor(groupId) ? 'Exam unlocked' : 'Exam locked',
                unlocked: lesson.isExamUnlockedFor(groupId),
                busy: busyLessonIds.contains(lesson.id) || busy,
                onPressed: () => onToggleExam(lesson, !lesson.isExamUnlockedFor(groupId)),
              ),
          ],
        ],
      ),
    );
  }
}

class _AccessRow extends StatelessWidget {
  const _AccessRow({
    required this.title,
    required this.subtitle,
    required this.unlocked,
    required this.busy,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final bool unlocked;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  subtitle,
                  style: TextStyle(color: context.semantic.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          _LockActionButton(
            unlocked: unlocked,
            compact: true,
            onPressed: busy ? null : onPressed,
          ),
        ],
      ),
    );
  }
}

class SentencesProgressFilters extends StatelessWidget {
  const SentencesProgressFilters({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateChanged;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    onDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _FilterCard(
            label: 'SUBJECT',
            child: Row(
              children: [
                const Text('🎨', style: TextStyle(fontSize: 18)),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(child: Text('All Subjects')),
                Icon(Icons.expand_more, color: context.semantic.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _FilterCard(
            label: 'DATE',
            child: InkWell(
              onTap: () => _pickDate(context),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      selectedDate == null
                          ? 'mm/dd/yyyy'
                          : '${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.year}',
                      style: TextStyle(color: context.semantic.textMuted),
                    ),
                  ),
                  Icon(Icons.calendar_month_outlined, size: 18, color: context.semantic.textMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: context.semantic.textMuted, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class SentencesProgressTable extends StatelessWidget {
  const SentencesProgressTable({
    super.key,
    required this.groupName,
    required this.subjectName,
    required this.students,
  });

  final String groupName;
  final String subjectName;
  final List<StudentProgressSummary> students;

  Color _pillColor(int value) {
    if (value == 0) return const Color(0xFFFCE7F3);
    if (value < 30) return const Color(0xFFFECDD3);
    if (value < 50) return const Color(0xFFFFEDD5);
    if (value < 70) return const Color(0xFFFEF3C7);
    return const Color(0xFFDCFCE7);
  }

  Color _pillTextColor(int value) {
    if (value == 0) return const Color(0xFFBE123C);
    if (value < 30) return const Color(0xFFB91C1C);
    if (value < 50) return const Color(0xFFC2410C);
    if (value < 70) return const Color(0xFFB45309);
    return const Color(0xFF15803D);
  }

  Widget _pill(int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _pillColor(value),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text('$value%', style: TextStyle(color: _pillTextColor(value), fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }

  int _wordExamPercent(StudentProgressSummary student) {
    if (student.lessonsPassed <= 0) return 0;
    return (student.lessonsPassed * 20).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                const Text('📁', style: TextStyle(fontSize: 18)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(groupName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text(subjectName, style: TextStyle(color: muted, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.semantic.border),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Text('All Lessons', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('${students.length} students', style: TextStyle(color: muted, fontSize: 11)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
            child: Row(
              children: [
                Expanded(flex: 4, child: Text('Student Name', style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 11))),
                Expanded(flex: 2, child: Text('Word Practice', textAlign: TextAlign.center, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 11))),
                Expanded(flex: 2, child: Text('Word Exam', textAlign: TextAlign.center, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 11))),
                Expanded(flex: 2, child: Text('Sentence Practice', textAlign: TextAlign.center, style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 11))),
              ],
            ),
          ),
          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('No students in this group.', style: TextStyle(color: muted, fontSize: 12)),
            )
          else
            for (final student in students)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Row(
                            children: [
                              PersonAvatar(
                                name: student.name,
                                profileImage: student.profileImage,
                                radius: 12,
                                isStudent: true,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  student.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(flex: 2, child: Center(child: _pill(student.wordsAccuracy))),
                        Expanded(flex: 2, child: Center(child: _pill(_wordExamPercent(student)))),
                        Expanded(flex: 2, child: Center(child: _pill(student.sentencesAccuracy))),
                      ],
                    ),
                  ),
                  if (student != students.last) const Divider(height: 1),
                ],
              ),
        ],
      ),
    );
  }
}
