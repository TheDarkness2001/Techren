import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/learning_cms.dart';
import '../../../../domain/entities/words.dart';

enum WordsHubTab { practice, exam, lessons, permissions, studentProgress }

/// Horizontal tab bar — segmented control (filled active chip, no underline).
class WordsHubTabBar extends StatelessWidget {
  const WordsHubTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final WordsHubTab selected;
  final ValueChanged<WordsHubTab> onSelected;

  static const _labels = {
    WordsHubTab.practice: 'Practice',
    WordsHubTab.exam: 'Exam',
    WordsHubTab.lessons: 'Lessons',
    WordsHubTab.permissions: 'Permissions',
    WordsHubTab.studentProgress: 'Student Progress',
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
            for (final tab in WordsHubTab.values)
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

/// Page header — title left, subtitle right.
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

/// Language picker grid for Practice / Exam tabs.
class WordsLanguageSection extends StatelessWidget {
  const WordsLanguageSection({
    super.key,
    required this.languages,
    required this.selectedLanguageId,
    required this.onLanguageSelected,
    this.onAddLanguage,
  });

  final List<LearningLanguage> languages;
  final String? selectedLanguageId;
  final ValueChanged<LearningLanguage> onLanguageSelected;
  final VoidCallback? onAddLanguage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Select a Language', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            if (onAddLanguage != null)
              TextButton.icon(
                onPressed: onAddLanguage,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add language'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (languages.isEmpty)
          WordsLanguageEmptyCard(onAddLanguage: onAddLanguage)
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
              final cardWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final language in languages)
                    SizedBox(
                      width: cardWidth,
                      height: 88,
                      child: WordsLanguageCard(
                        language: language,
                        selected: selectedLanguageId == language.id,
                        onTap: () => onLanguageSelected(language),
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

class WordsLanguageEmptyCard extends StatelessWidget {
  const WordsLanguageEmptyCard({super.key, this.onAddLanguage});

  final VoidCallback? onAddLanguage;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.translate_outlined, size: 36, color: muted),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No languages yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            onAddLanguage != null
                ? 'Create a language to start adding levels, lessons, and words.'
                : 'Ask an admin to create languages, or open Lessons if you have content permission.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
          ),
          if (onAddLanguage != null) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onAddLanguage,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add language'),
            ),
          ],
        ],
      ),
    );
  }
}

class WordsLanguageCard extends StatelessWidget {
  const WordsLanguageCard({
    super.key,
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final LearningLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: AppShadows.card,
            color: selected ? AppColors.primaryContainer.withValues(alpha: 0.25) : Theme.of(context).colorScheme.surface,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                language.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WordsLevelList extends StatelessWidget {
  const WordsLevelList({
    super.key,
    required this.levels,
    required this.onLevelTap,
    this.emptyMessage = 'No levels for this language yet.',
  });

  final List<CmsLevel> levels;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text('Select a Level', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final level in levels)
              ActionChip(
                label: Text(level.name),
                onPressed: () => onLevelTap(level.id, level.name),
              ),
          ],
        ),
      ],
    );
  }
}

class WordsLessonList extends StatelessWidget {
  const WordsLessonList({
    super.key,
    required this.lessons,
    required this.onLessonTap,
    this.showExamStatus = false,
  });

  final List<CmsLesson> lessons;
  final void Function(String lessonId, String lessonName) onLessonTap;
  final bool showExamStatus;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Text('No lessons yet.', style: TextStyle(color: context.semantic.textMuted)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text('Lessons', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        for (final lesson in lessons)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              title: Text(lesson.name),
              subtitle: Text(
                showExamStatus
                    ? '${lesson.wordCount} words · Exam ${lesson.examUnlockedFor.isNotEmpty ? 'unlocked' : 'locked'}'
                    : '${lesson.wordCount} words',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onLessonTap(lesson.id, lesson.name),
            ),
          ),
      ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.semantic.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: onOpen, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
