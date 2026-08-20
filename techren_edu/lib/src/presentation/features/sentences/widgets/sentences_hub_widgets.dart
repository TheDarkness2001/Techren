import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/learning_playground.dart';
import '../../../../core/widgets/person_avatar.dart';
import '../../../../domain/entities/learning_cms.dart';
import '../../../../domain/entities/scheduling.dart';
import '../../../../domain/entities/sentences.dart';
import '../../../../domain/entities/student_progress.dart';

enum SentencesHubTab { practice, leaderboard, lessons, permissions, studentProgress }

enum SentencesPracticeStep { levels, classes, practice }

class SentencesHubTabBar extends StatelessWidget {
  const SentencesHubTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final SentencesHubTab selected;
  final ValueChanged<SentencesHubTab> onSelected;

  static const _tabs = [
    PlaygroundTab(id: SentencesHubTab.practice, label: 'Practice', icon: Icons.school_outlined),
    PlaygroundTab(id: SentencesHubTab.leaderboard, label: 'Leaderboard', icon: Icons.emoji_events_outlined),
    PlaygroundTab(id: SentencesHubTab.lessons, label: 'Lessons', icon: Icons.menu_book_outlined),
    PlaygroundTab(id: SentencesHubTab.permissions, label: 'Permissions', icon: Icons.groups_outlined),
    PlaygroundTab(id: SentencesHubTab.studentProgress, label: 'Student Progress', icon: Icons.insights_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return PlaygroundTabBar<SentencesHubTab>(
      tabs: _tabs,
      selected: selected,
      onSelected: onSelected,
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

class SentencesLevelGrid extends StatelessWidget {
  const SentencesLevelGrid({
    super.key,
    required this.levels,
    required this.onLevelTap,
    this.selectedLevelId,
  });

  final List<CmsLevel> levels;
  final ValueChanged<CmsLevel> onLevelTap;
  final String? selectedLevelId;

  @override
  Widget build(BuildContext context) {
    return PlaygroundLevelStrip(
      levels: [for (final level in levels) PlaygroundLevelItem(id: level.id, name: level.name)],
      selectedId: selectedLevelId,
      onSelected: (item) {
        for (final level in levels) {
          if (level.id == item.id) {
            onLevelTap(level);
            return;
          }
        }
      },
    );
  }
}

class SentencesClassGrid extends StatelessWidget {
  const SentencesClassGrid({
    super.key,
    required this.levelName,
    required this.lessons,
    required this.onLessonTap,
    this.selectedLessonId,
    this.onLessonSelected,
  });

  final String levelName;
  final List<CmsLesson> lessons;
  final ValueChanged<CmsLesson> onLessonTap;
  final String? selectedLessonId;
  final ValueChanged<CmsLesson>? onLessonSelected;

  @override
  Widget build(BuildContext context) {
    final units = [for (final lesson in lessons) playgroundUnitFromCmsLesson(lesson, noun: 'sentences')];
    CmsLesson? current;
    for (final lesson in lessons) {
      if (lesson.id == (selectedLessonId ?? lessons.firstOrNull?.id)) current = lesson;
    }
    current ??= lessons.isEmpty ? null : lessons.first;

    return PlaygroundLessonDashboard(
      units: units,
      selectedId: current?.id,
      onSelect: (unit) {
        for (final lesson in lessons) {
          if (lesson.id == unit.id) {
            onLessonSelected?.call(lesson);
            return;
          }
        }
      },
      onPractice: current == null ? null : () => onLessonTap(current!),
      primaryLabel: 'Continue Practice',
      emptyMessage: 'No classes yet.',
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
    this.expanded = false,
  });

  final UnifiedGroupView item;
  final VoidCallback onManageLessons;
  final String actionLabel;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final group = item.group;
    final schedule = item.schedule;
    final subject = group.subjectName ?? 'General';
    final time = schedule != null ? '${schedule.startTime} – ${schedule.endTime}' : '—';
    final teacher = schedule?.teacherName ?? '—';
    final muted = context.semantic.textMuted;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onManageLessons,
        borderRadius: AppRadius.card,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: AppRadius.card,
            border: Border.all(
              color: expanded ? scheme.primary.withValues(alpha: 0.45) : context.semantic.border,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final identity = Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.groups_2_outlined, size: 18, color: Color(0xFF818CF8)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.groupName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(subject, style: TextStyle(color: muted, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              );

              final meta = Row(
                children: [
                  Flexible(child: _InlineMeta(icon: Icons.access_time, text: time)),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(child: _InlineMeta(icon: Icons.person_outline, text: teacher)),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(child: _InlineMeta(icon: Icons.badge_outlined, text: 'ID: ${group.groupName}')),
                ],
              );

              final action = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: onManageLessons,
                    icon: Icon(
                      expanded ? Icons.lock_outline : Icons.lock_open_outlined,
                      size: 14,
                    ),
                    label: Text(actionLabel, style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFA5B4FC),
                      side: BorderSide(color: const Color(0xFF818CF8).withValues(alpha: 0.55)),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: muted,
                  ),
                ],
              );

              if (wide) {
                return Row(
                  children: [
                    Expanded(flex: 3, child: identity),
                    Expanded(flex: 5, child: meta),
                    action,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  identity,
                  const SizedBox(height: AppSpacing.sm),
                  meta,
                  const SizedBox(height: AppSpacing.sm),
                  Align(alignment: Alignment.centerRight, child: action),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF818CF8)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.semantic.textMuted, fontSize: 11),
          ),
        ),
      ],
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
    required this.unlockAction,
    required this.onPressed,
    this.label,
    this.compact = false,
  });

  /// When true, this is an Unlock button; when false, a Lock button.
  final bool unlockAction;
  final VoidCallback? onPressed;
  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = label ?? (unlockAction ? 'Unlock' : 'Lock');
    final icon = unlockAction ? Icons.lock_open_rounded : Icons.lock_rounded;
    final style = TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      textStyle: TextStyle(fontSize: compact ? 11 : 12, fontWeight: FontWeight.w600),
    );
    if (unlockAction) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: compact ? 13 : 14),
        label: Text(text),
        style: style.copyWith(
          backgroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.primary),
          foregroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.onPrimary),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: compact ? 13 : 14),
      label: Text(text),
      style: style,
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.semantic.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _practiceOn ? Icons.check_circle_rounded : Icons.lock_rounded,
                size: 18,
                color: _practiceOn ? scheme.primary : muted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      _practiceOn ? 'Open for this group' : 'Closed for this group',
                      style: TextStyle(color: muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              if (!showExamToggles)
                _LockActionButton(
                  unlockAction: !_practiceOn,
                  compact: true,
                  onPressed: busy ? null : () => onTogglePractice(!_practiceOn),
                ),
              if (showExamToggles && onBulkUnlockLevel != null) ...[
                _LockActionButton(
                  unlockAction: true,
                  label: 'Unlock all',
                  compact: true,
                  onPressed: busy ? null : () => onBulkUnlockLevel!(true),
                ),
                const SizedBox(width: 6),
                _LockActionButton(
                  unlockAction: false,
                  label: 'Lock all',
                  compact: true,
                  onPressed: busy ? null : () => onBulkUnlockLevel!(false),
                ),
              ],
            ],
          ),
          if (showExamToggles) ...[
            const SizedBox(height: AppSpacing.sm),
            if (lessons.isEmpty)
              Text('No classes yet.', style: TextStyle(color: muted, fontSize: 11))
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final lesson in lessons)
                    _UnitLockCard(
                      title: lesson.name,
                      unlocked: lesson.isExamUnlockedFor(groupId),
                      busy: busyLessonIds.contains(lesson.id) || busy,
                      onPressed: () => onToggleExam(lesson, !lesson.isExamUnlockedFor(groupId)),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _UnitLockCard extends StatelessWidget {
  const _UnitLockCard({
    required this.title,
    required this.unlocked,
    required this.busy,
    required this.onPressed,
  });

  final String title;
  final bool unlocked;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.semantic.textMuted;

    return SizedBox(
      width: 118,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.semantic.border.withValues(alpha: 0.8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              size: 18,
              color: unlocked ? scheme.primary : muted,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              unlocked ? 'Class open' : 'Class closed',
              style: TextStyle(color: muted, fontSize: 10),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: busy ? null : onPressed,
              icon: Icon(
                unlocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                size: 12,
              ),
              label: Text(unlocked ? 'Lock' : 'Unlock'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFA5B4FC),
                side: BorderSide(color: const Color(0xFF818CF8).withValues(alpha: 0.55)),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                minimumSize: const Size.fromHeight(28),
              ),
            ),
          ],
        ),
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
