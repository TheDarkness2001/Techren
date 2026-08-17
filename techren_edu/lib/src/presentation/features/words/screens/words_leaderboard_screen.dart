import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/student_navigation.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/go_back_icon_button.dart';
import '../../../../core/widgets/student_leaderboard_list.dart';
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
        GoBackIconButton(fallbackRoute: '/student/words'),
      ],
      body: boardAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (board) {
          final me = board.currentStudent;
          final top10 = board.leaderboard.take(10).toList();

          return StudentLeaderboardList(
            onRefresh: () async => ref.invalidate(wordsLeaderboardProvider),
            currentRank: me?.rank,
            currentName: me?.name,
            currentCode: me?.studentCode,
            emptyMessage: 'No rankings yet — complete a words practice to appear here.',
            entries: [
              for (final entry in top10)
                LeaderboardHubCard(
                  rank: entry.rank,
                  title: compactLeaderboardName(entry.name, entry.studentCode),
                  subtitle: '${entry.studentCode} · ${entry.correctAnswers} correct · ${entry.xp} XP',
                  trailing: '${entry.accuracy}%',
                  highlighted: isCurrentLeaderboardEntry(
                    entryName: entry.name,
                    entryCode: entry.studentCode,
                    entryRank: entry.rank,
                    meName: me?.name,
                    meCode: me?.studentCode,
                    meRank: me?.rank,
                  ),
                ),
            ],
            outsideTopBuilder: me == null
                ? null
                : () => buildOutsideTopCard(
                      rank: me.rank,
                      title: compactLeaderboardName(me.name, me.studentCode),
                      subtitle: '${me.studentCode} · ${me.correctAnswers} correct · ${me.xp} XP',
                      trailing: '${me.accuracy}%',
                    ),
          );
        },
      ),
    );
  }
}
