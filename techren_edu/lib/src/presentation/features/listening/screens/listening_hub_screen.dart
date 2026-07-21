import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/go_back_icon_button.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../providers/listening_provider.dart';
import 'listening_practice_screen.dart';

class ListeningHubScreen extends ConsumerWidget {
  const ListeningHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(studentListeningLevelsProvider);

    final navItems = studentNavItemsOf(context);

    return AdaptiveScaffold(
      title: 'Listening',
      selectedIndex: 1,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      actions: [
        IconButton(
          icon: const Icon(Icons.leaderboard_outlined),
          tooltip: 'Leaderboard',
          onPressed: () => context.go('/student/listening/leaderboard'),
        ),
        GoBackIconButton(fallbackRoute: '/student/learn'),
      ],
      body: levelsAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (levels) {
          if (levels.isEmpty) {
            return const EmptyState(
              title: 'No levels unlocked',
              message: 'Your teacher will unlock listening practice for your group.',
              icon: Icons.headphones_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentListeningLevelsProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final level in levels) ...[
                  HubSectionHeader(title: level.name),
                  ...level.exercises.map(
                    (exercise) => AppHubCard(
                      title: exercise.title,
                      subtitle: exercise.hasAudio ? 'Audio ready · Tap to practice' : 'No audio available',
                      accentColor: const Color(0xFF7C3AED),
                      leadingLabel: '${exercise.order}',
                      locked: !exercise.hasAudio,
                      onTap: exercise.hasAudio
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ListeningPracticeScreen(
                                    levelId: level.id,
                                    levelName: level.name,
                                    exercise: exercise,
                                  ),
                                ),
                              )
                          : null,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
