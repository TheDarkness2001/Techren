import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/learning_playground.dart';
import '../../../../domain/entities/learning_cms.dart';

enum WordsHubTab { practice, exam, lessons, permissions, studentProgress }

class WordsHubTabBar extends StatelessWidget {
  const WordsHubTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final WordsHubTab selected;
  final ValueChanged<WordsHubTab> onSelected;

  static const _tabs = [
    PlaygroundTab(id: WordsHubTab.practice, label: 'Practice', icon: Icons.school_outlined),
    PlaygroundTab(id: WordsHubTab.exam, label: 'Exam', icon: Icons.description_outlined),
    PlaygroundTab(id: WordsHubTab.lessons, label: 'Lessons', icon: Icons.menu_book_outlined),
    PlaygroundTab(id: WordsHubTab.permissions, label: 'Permissions', icon: Icons.groups_outlined),
    PlaygroundTab(id: WordsHubTab.studentProgress, label: 'Student Progress', icon: Icons.insights_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return PlaygroundTabBar<WordsHubTab>(
      tabs: _tabs,
      selected: selected,
      onSelected: onSelected,
    );
  }
}

class WordsHubHeader extends StatelessWidget {
  const WordsHubHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Practice words and track your progress',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.semantic.textMuted),
    );
  }
}

class WordsLevelList extends StatelessWidget {
  const WordsLevelList({
    super.key,
    required this.levels,
    required this.onLevelTap,
    this.selectedLevelId,
    this.emptyMessage = 'No levels yet.',
  });

  final List<CmsLevel> levels;
  final String? selectedLevelId;
  final void Function(String levelId, String levelName) onLevelTap;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (levels.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Text(emptyMessage, style: TextStyle(color: context.semantic.textMuted)),
      );
    }

    return PlaygroundLevelStrip(
      levels: [for (final level in levels) PlaygroundLevelItem(id: level.id, name: level.name)],
      selectedId: selectedLevelId,
      onSelected: (level) => onLevelTap(level.id, level.name),
    );
  }
}

class WordsLessonList extends StatelessWidget {
  const WordsLessonList({
    super.key,
    required this.lessons,
    required this.onLessonTap,
    this.selectedLessonId,
    this.onLessonSelected,
    this.showExamStatus = false,
    this.primaryLabel,
  });

  final List<CmsLesson> lessons;
  final void Function(String lessonId, String lessonName) onLessonTap;
  final void Function(String lessonId, String lessonName)? onLessonSelected;
  final String? selectedLessonId;
  final bool showExamStatus;
  final String? primaryLabel;

  @override
  Widget build(BuildContext context) {
    final units = [for (final lesson in lessons) playgroundUnitFromCmsLesson(lesson, noun: 'words')];
    final selected = selectedLessonId ?? (units.isEmpty ? null : units.first.id);
    PlaygroundUnitItem? current;
    for (final unit in units) {
      if (unit.id == selected) {
        current = unit;
        break;
      }
    }
    current ??= units.isEmpty ? null : units.first;
    final active = current;

    return PlaygroundLessonDashboard(
      units: units,
      selectedId: active?.id,
      onSelect: (unit) => onLessonSelected?.call(unit.id, unit.title),
      onPractice: active == null ? null : () => onLessonTap(active.id, active.title),
      primaryLabel: primaryLabel ?? (showExamStatus ? 'Start Exam' : 'Continue Practice'),
      emptyMessage: 'No lessons yet.',
    );
  }
}

class WordsHubLinkPanel extends StatelessWidget {
  const WordsHubLinkPanel({
    super.key,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onOpen,
    required this.icon,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onOpen;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: semantic.border),
      ),
      child: Column(
        children: [
          PlaygroundPlanet(color: const Color(0xFF818CF8)),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: semantic.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: onOpen, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
