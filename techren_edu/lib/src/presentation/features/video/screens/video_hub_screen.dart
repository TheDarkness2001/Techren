import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/go_back_icon_button.dart';

import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/video.dart';
import '../../../providers/video_provider.dart';
import 'video_player_screen.dart';

class VideoHubScreen extends ConsumerWidget {
  const VideoHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(studentVideosProvider);

    final navItems = studentNavItemsOf(context);

    return AdaptiveScaffold(
      title: 'Video Lessons',
      selectedIndex: 1,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      actions: [
        GoBackIconButton(fallbackRoute: '/student/learn'),
      ],
      body: videosAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (videos) {
          if (videos.isEmpty) {
            return const EmptyState(
              title: 'No videos unlocked',
              message: 'Your teacher will unlock video lessons for your group.',
              icon: Icons.play_circle_outline,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentVideosProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: videos.map((video) => _VideoCard(video: video)).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});

  final VideoLessonSummary video;

  @override
  Widget build(BuildContext context) {
    final progress = video.progress;
    final percent = progress?.watchPercent ?? 0;

    return AppHubMediaCard(
      title: video.title,
      subtitle: video.levelName,
      imageUrl: video.thumbnail.isNotEmpty ? video.thumbnail : null,
      progressPercent: percent,
      completed: progress?.completed == true,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoId: video.id)),
      ),
    );
  }
}
