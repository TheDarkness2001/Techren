import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../providers/words_provider.dart';

class WordsLeaderboardScreen extends ConsumerWidget {
  const WordsLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(wordsLeaderboardProvider);
    final navItems = studentNavItemsOf(context);

    return AdaptiveScaffold(
      title: 'Leaderboard',
      selectedIndex: 1,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      actions: [
        IconButton(
          tooltip: 'Go back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student/words'),
        ),
      ],
      body: boardAsync.when(

        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),

        error: (e, _) => Center(child: Text(e.toString())),

        data: (board) {

          return RefreshIndicator(

            onRefresh: () async => ref.invalidate(wordsLeaderboardProvider),

            child: ListView(

              padding: AppSpacing.listGutter,

              children: [

                if (board.currentStudent != null)

                  LeaderboardHubCard(

                    rank: board.currentStudent!.rank,

                    title: 'You — ${board.currentStudent!.name}',

                    subtitle: board.currentStudent!.studentCode,

                    trailing: '${board.currentStudent!.accuracy}%',

                    highlighted: true,

                  ),

                if (board.currentStudent != null) const SizedBox(height: AppSpacing.xs),

                ...board.leaderboard.map(

                  (entry) => LeaderboardHubCard(

                    rank: entry.rank,

                    title: entry.name,

                    subtitle: entry.studentCode,

                    trailing: '${entry.accuracy}%',

                  ),

                ),

              ],

            ),

          );

        },

      ),

    );

  }

}


