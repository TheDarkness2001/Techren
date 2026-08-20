import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/go_back_icon_button.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/learning_playground.dart';
import '../../../../domain/entities/listening.dart';
import '../../../providers/listening_provider.dart';
import 'listening_practice_screen.dart';

class ListeningHubScreen extends ConsumerStatefulWidget {
  const ListeningHubScreen({super.key});

  @override
  ConsumerState<ListeningHubScreen> createState() => _ListeningHubScreenState();
}

class _ListeningHubScreenState extends ConsumerState<ListeningHubScreen> {
  String? _levelId;
  String? _exerciseId;

  @override
  Widget build(BuildContext context) {
    final levelsAsync = ref.watch(studentListeningLevelsProvider);
    final navItems = studentNavItemsOf(context);

    return AdaptiveScaffold(
      title: 'BBC news',
      selectedIndex: 1,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      actions: [
        IconButton(
          icon: const Icon(Icons.leaderboard_outlined),
          tooltip: 'Leaderboard',
          onPressed: () => context.go('/student/listening/leaderboard'),
        ),
        const GoBackIconButton(fallbackRoute: '/student/learn'),
      ],
      body: levelsAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (levels) {
          if (levels.isEmpty) {
            return const EmptyState(
              title: 'No BBC news tasks unlocked',
              message: 'Your teacher will unlock BBC news listening for your group.',
              icon: Icons.headphones_outlined,
            );
          }
          final selectedLevel = _pickLevel(levels);
          final exercises = selectedLevel.exercises;
          final selected = _pickExercise(exercises);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentListeningLevelsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                PlaygroundLevelStrip(
                  levels: [for (final level in levels) PlaygroundLevelItem(id: level.id, name: level.name)],
                  selectedId: selectedLevel.id,
                  onSelected: (item) => setState(() {
                    _levelId = item.id;
                    _exerciseId = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                PlaygroundLessonDashboard(
                  units: [for (final exercise in exercises) _unitFor(exercise)],
                  selectedId: selected?.id,
                  onSelect: (unit) => setState(() => _exerciseId = unit.id),
                  onPractice: selected == null || !selected.hasAudio
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ListeningPracticeScreen(
                                levelId: selectedLevel.id,
                                levelName: selectedLevel.name,
                                exercise: selected,
                              ),
                            ),
                          ),
                  primaryLabel: 'Continue Practice',
                  emptyMessage: 'No listening tasks yet.',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  ListeningLevel _pickLevel(List<ListeningLevel> levels) {
    for (final level in levels) {
      if (level.id == _levelId) return level;
    }
    return levels.first;
  }

  ListeningExerciseSummary? _pickExercise(List<ListeningExerciseSummary> exercises) {
    if (exercises.isEmpty) return null;
    for (final exercise in exercises) {
      if (exercise.id == _exerciseId) return exercise;
    }
    return exercises.firstWhere((e) => e.hasAudio, orElse: () => exercises.first);
  }

  PlaygroundUnitItem _unitFor(ListeningExerciseSummary exercise) {
    return PlaygroundUnitItem(
      id: exercise.id,
      title: exercise.title,
      order: exercise.order,
      countLabel: exercise.hasAudio ? 'Audio ready' : 'No audio',
      description: exercise.hasAudio
          ? 'Listen to the clip and transcribe what you hear. Accuracy is scored as you go.'
          : 'Audio is not available for this task yet.',
      progressPercent: 0,
      mastered: 0,
      inReview: exercise.hasAudio ? 1 : 0,
      total: 1,
      masteredLabel: 'Mastered',
      reviewLabel: 'Ready',
      totalLabel: 'Tracks',
      locked: !exercise.hasAudio,
    );
  }
}
