import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/learning_playground.dart';
import '../../../../domain/entities/words.dart';
import '../../../providers/words_provider.dart';
import 'word_practice_screen.dart';

class WordsHubScreen extends ConsumerStatefulWidget {
  const WordsHubScreen({
    super.key,
    this.navItems,
    required this.selectedRoute,
    this.selectedIndex = 1,
  });

  final List<NavItem>? navItems;
  final String selectedRoute;
  final int selectedIndex;

  @override
  ConsumerState<WordsHubScreen> createState() => _WordsHubScreenState();
}

class _WordsHubScreenState extends ConsumerState<WordsHubScreen> {
  String? _levelId;
  String? _lessonId;

  @override
  Widget build(BuildContext context) {
    final navItems = widget.navItems ?? studentNavItemsOf(context);
    final treeAsync = ref.watch(studentWordsTreeProvider);
    final index = navItems.indexWhere((i) => widget.selectedRoute.startsWith(i.route));

    return AdaptiveScaffold(
      title: 'Words',
      selectedIndex: index >= 0 ? index : widget.selectedIndex,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      actions: [
        IconButton(
          icon: const Icon(Icons.leaderboard_outlined),
          tooltip: 'Leaderboard',
          onPressed: () => context.go('/student/words/leaderboard'),
        ),
        IconButton(
          tooltip: 'Go back',
          onPressed: () => context.go('/student/learn'),
          icon: const Icon(Icons.arrow_back),
        ),
      ],
      body: treeAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (levels) {
          if (levels.isEmpty) {
            return const EmptyState(
              title: 'No lessons unlocked',
              message: 'Your teacher will unlock practice levels for your group.',
              icon: Icons.menu_book_outlined,
            );
          }
          final selectedLevel = _pickLevel(levels);
          final lessons = selectedLevel.lessons;
          final selectedLesson = _pickLesson(lessons);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentWordsTreeProvider),
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
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => WordPracticeScreen(
                                lessonId: selectedLesson.id,
                                lessonName: selectedLesson.name,
                              ),
                            ),
                          ),
                  primaryLabel: 'Continue Practice',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  LearningLevel _pickLevel(List<LearningLevel> levels) {
    for (final level in levels) {
      if (level.id == _levelId) return level;
    }
    return levels.first;
  }

  StudentLesson? _pickLesson(List<StudentLesson> lessons) {
    if (lessons.isEmpty) return null;
    for (final lesson in lessons) {
      if (lesson.id == _lessonId) return lesson;
    }
    return lessons.firstWhere((l) => !l.isLocked, orElse: () => lessons.first);
  }

  PlaygroundUnitItem _unitFor(StudentLesson lesson) {
    final passed = lesson.isPassed;
    final locked = lesson.isLocked;
    return PlaygroundUnitItem(
      id: lesson.id,
      title: lesson.name,
      order: lesson.order,
      countLabel: '${lesson.wordCount} words',
      description: locked
          ? 'This unit is locked until your teacher opens it for your group.'
          : 'Practice these words until they stick. Exams open when your teacher unlocks them.',
      progressPercent: passed
          ? 100
          : (lesson.bestExamScore > 0 ? lesson.bestExamScore : (locked ? 0 : 12)),
      mastered: passed ? lesson.wordCount : 0,
      inReview: !locked && !passed ? lesson.wordCount : 0,
      total: lesson.wordCount,
      locked: locked,
    );
  }
}
