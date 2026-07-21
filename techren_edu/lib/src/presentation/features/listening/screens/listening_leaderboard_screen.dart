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

        IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/student/listening')),

        GoBackIconButton(fallbackRoute: '/student/listening'),

      ],

      body: boardAsync.when(

        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),

        error: (e, _) => Center(child: Text(e.toString())),

        data: (board) => RefreshIndicator(

          onRefresh: () async => ref.invalidate(listeningLeaderboardProvider),

          child: ListView(

            padding: AppSpacing.listGutter,

            children: [

              if (board.currentStudent != null)

                LeaderboardHubCard(

                  rank: board.currentStudent!.rank,

                  title: 'You — ${board.currentStudent!.name}',

                  subtitle:

                      '${board.currentStudent!.avgBestAccuracy}% avg · ${board.currentStudent!.totalAttempts} attempts',

                  trailing: '${board.currentStudent!.avgBestAccuracy}%',

                  highlighted: true,

                ),

              if (board.currentStudent != null) const SizedBox(height: AppSpacing.xs),

              ...board.leaderboard.map(

                (entry) => LeaderboardHubCard(

                  rank: entry.rank,

                  title: entry.name,

                  subtitle: '${entry.studentCode} · ${entry.totalAttempts} attempts',

                  trailing: '${entry.avgBestAccuracy}%',

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}


