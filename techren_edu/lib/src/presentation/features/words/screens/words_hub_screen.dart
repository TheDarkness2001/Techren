import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/words.dart';
import '../../../providers/words_provider.dart';
import 'word_practice_screen.dart';

class WordsHubScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final navItems = this.navItems ?? studentNavItemsOf(context);
    final treeAsync = ref.watch(studentWordsTreeProvider);
    final index = navItems.indexWhere((i) => selectedRoute.startsWith(i.route));
    final semantic = context.semantic;

    return AdaptiveScaffold(
      title: 'Words',
      selectedIndex: index >= 0 ? index : selectedIndex,
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
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentWordsTreeProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                for (final level in levels) ...[
                  HubSectionHeader(title: level.name),
                  ...level.lessons.map(
                    (lesson) => AppHubCard(
                      title: lesson.name,
                      subtitle: _lessonSubtitle(lesson),
                      accentColor: lesson.isPassed ? semantic.success : AppColors.primary,
                      leadingLabel: '${lesson.order}',
                      locked: lesson.isLocked,
                      onTap: lesson.isLocked
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => WordPracticeScreen(lessonId: lesson.id, lessonName: lesson.name),
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

  String _lessonSubtitle(StudentLesson lesson) {
    final parts = ['${lesson.wordCount} words', lesson.status];
    if (lesson.bestExamScore > 0) parts.add('Best ${lesson.bestExamScore}%');
    return parts.join(' · ');
  }
}
