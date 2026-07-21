import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../core/widgets/app_hub_card.dart';

import '../../../../core/widgets/common_widgets.dart';

import '../../../providers/video_provider.dart';



class VideoTestLeaderboardScreen extends ConsumerWidget {

  const VideoTestLeaderboardScreen({super.key, required this.videoId, required this.videoTitle});



  final String videoId;

  final String videoTitle;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final boardAsync = ref.watch(videoTestLeaderboardProvider(videoId));



    return Scaffold(

      appBar: AppBar(title: Text('$videoTitle — Leaderboard')),

      body: boardAsync.when(

        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),

        error: (e, _) => Center(child: Text(e.toString())),

        data: (entries) => RefreshIndicator(

          onRefresh: () async => ref.invalidate(videoTestLeaderboardProvider(videoId)),

          child: entries.isEmpty

              ? ListView(

                  children: const [

                    SizedBox(height: AppSpacing.emptyStateTop),

                    EmptyState(

                      title: 'No exam results yet',

                      message: 'Scores appear here after students complete the video test.',

                      icon: Icons.leaderboard_outlined,

                    ),

                  ],

                )

              : ListView.builder(

                  padding: AppSpacing.listGutter,

                  itemCount: entries.length,

                  itemBuilder: (_, i) {

                    final entry = entries[i];

                    return LeaderboardHubCard(

                      rank: entry.rank,

                      title: entry.name,

                      subtitle: '${entry.studentCode} · ${entry.attempts} attempts',

                      trailing: '${entry.bestScore}%',

                    );

                  },

                ),

        ),

      ),

    );

  }

}


