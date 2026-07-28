import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/student_navigation.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/go_back_icon_button.dart';
import '../../../../core/widgets/student_leaderboard_list.dart';
import '../../../providers/listening_provider.dart';

class ListeningLeaderboardScreen extends ConsumerWidget {
  const ListeningLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(listeningLeaderboardProvider);
    final navItems = studentNavItemsOf(context);

    return AdaptiveScaffold(
      title: 'Listening Leaderboard',
      selectedIndex: 1,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      actions: [
        GoBackIconButton(fallbackRoute: '/student/listening'),
      ],
      body: boardAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (board) {
          final me = board.currentStudent;
          final top10 = board.leaderboard.take(10).toList();

          return StudentLeaderboardList(
            onRefresh: () async => ref.invalidate(listeningLeaderboardProvider),
            currentRank: me?.rank,
            currentName: me?.name,
            currentCode: me?.studentCode,
            emptyMessage: 'No rankings yet — complete a listening practice to appear here.',
            entries: [
              for (final entry in top10)
                LeaderboardHubCard(
                  rank: entry.rank,
                  title: compactLeaderboardName(entry.name, entry.studentCode),
                  subtitle: '${entry.studentCode} · ${entry.totalAttempts} attempts',
                  trailing: '${entry.avgBestAccuracy}%',
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
                      subtitle: '${me.studentCode} · ${me.totalAttempts} attempts',
                      trailing: '${me.avgBestAccuracy}%',
                    ),
          );
        },
      ),
    );
  }
}
