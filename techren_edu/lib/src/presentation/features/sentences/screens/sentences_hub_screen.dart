import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/go_back_icon_button.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/learning_playground.dart';
import '../../../../domain/entities/sentences.dart';
import '../../../providers/sentences_provider.dart';
import 'sentence_practice_screen.dart';

class SentencesHubScreen extends ConsumerStatefulWidget {
  const SentencesHubScreen({super.key});

  @override
  ConsumerState<SentencesHubScreen> createState() => _SentencesHubScreenState();
}

class _SentencesHubScreenState extends ConsumerState<SentencesHubScreen> {
  String? _levelId;
  String? _lessonId;

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(studentSentencesTreeProvider);
    final navItems = studentNavItemsOf(context);

    return AdaptiveScaffold(
      title: 'Sentences',
      selectedIndex: 1,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      actions: [
        IconButton(
          icon: const Icon(Icons.leaderboard_outlined),
          tooltip: 'Leaderboard',
          onPressed: () => context.go('/student/sentences/leaderboard'),
        ),
        const GoBackIconButton(fallbackRoute: '/student/learn'),
      ],
      body: treeAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (levels) {
          if (levels.isEmpty) {
            return const EmptyState(
              title: 'No lessons unlocked',
              message: 'Your teacher will unlock sentence practice for your group.',
              icon: Icons.format_quote_outlined,
            );
          }
          final selectedLevel = _pickLevel(levels);
          final lessons = selectedLevel.lessons;
          final selectedLesson = _pickLesson(lessons);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentSentencesTreeProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                PlaygroundLevelStrip(
                  levels: [for (final level in levels) PlaygroundLevelItem(id: level.id, name: level.name)],
                  selectedId: selectedLevel.id,
                  onSelected: (item) => setState(() {
                    _levelId = item.id;
                    _lessonId = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                PlaygroundLessonDashboard(
                  units: [for (final lesson in lessons) _unitFor(lesson)],
                  selectedId: selectedLesson?.id,
                  onSelect: (unit) => setState(() => _lessonId = unit.id),
                  onPractice: selectedLesson == null || selectedLesson.isLocked
                      ? null
                      : () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SentencePracticeScreen(
                                lessonId: selectedLesson.id,
                                lessonName: selectedLesson.name,
                              ),
                            ),
                          );
                          ref.invalidate(studentSentencesTreeProvider);
                        },
                  primaryLabel: 'Continue Practice',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  SentenceLevel _pickLevel(List<SentenceLevel> levels) {
    for (final level in levels) {
      if (level.id == _levelId) return level;
    }
    return levels.first;
  }

  SentenceLesson? _pickLesson(List<SentenceLesson> lessons) {
    if (lessons.isEmpty) return null;
    for (final lesson in lessons) {
      if (lesson.id == _lessonId) return lesson;
    }
    return lessons.firstWhere((l) => !l.isLocked, orElse: () => lessons.first);
  }

  PlaygroundUnitItem _unitFor(SentenceLesson lesson) {
    final remaining = (lesson.sentenceCount - lesson.completedCount).clamp(0, lesson.sentenceCount);
    return PlaygroundUnitItem(
      id: lesson.id,
      title: lesson.name,
      order: lesson.order,
      countLabel: '${lesson.sentenceCount} sentences',
      description: lesson.isLocked
          ? 'This unit is locked until your teacher opens it for your group.'
          : 'Translate these sentences and get grammar feedback as you go.',
      progressPercent: lesson.progressPercent,
      mastered: lesson.completedCount,
      inReview: remaining,
      total: lesson.sentenceCount,
      locked: lesson.isLocked,
    );
  }
}
