import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/go_back_icon_button.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../providers/sentences_provider.dart';
import 'sentence_practice_screen.dart';

class SentencesHubScreen extends ConsumerWidget {
  const SentencesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        GoBackIconButton(fallbackRoute: '/student/learn'),
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
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentSentencesTreeProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final level in levels) ...[
                  HubSectionHeader(title: level.name),
                  ...level.lessons.map(
                    (lesson) => AppHubCard(
                      title: lesson.name,
                      subtitle: '${lesson.sentenceCount} sentences · ${lesson.status}',
                      accentColor: AppColors.secondary,
                      leadingLabel: '${lesson.order}',
                      locked: lesson.isLocked,
                      onTap: lesson.isLocked
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SentencePracticeScreen(lessonId: lesson.id, lessonName: lesson.name),
                                ),
                              ),
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
