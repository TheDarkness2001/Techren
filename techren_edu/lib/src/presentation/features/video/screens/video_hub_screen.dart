import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/go_back_icon_button.dart';

import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/learning_playground.dart';
import '../../../../domain/entities/video.dart';
import '../../../providers/video_provider.dart';
import 'video_player_screen.dart';

class VideoHubScreen extends ConsumerStatefulWidget {
  const VideoHubScreen({super.key});

  @override
  ConsumerState<VideoHubScreen> createState() => _VideoHubScreenState();
}

class _VideoHubScreenState extends ConsumerState<VideoHubScreen> {
  String? _levelName;
  String? _videoId;

  @override
  Widget build(BuildContext context) {
    final videosAsync = ref.watch(studentVideosProvider);
    final navItems = studentNavItemsOf(context);

    return AdaptiveScaffold(
      title: 'Video Lessons',
      selectedIndex: 1,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      actions: [
        const GoBackIconButton(fallbackRoute: '/student/learn'),
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

          final levelNames = <String>[];
          for (final video in videos) {
            final name = video.levelName.trim().isEmpty ? 'Lessons' : video.levelName;
            if (!levelNames.contains(name)) levelNames.add(name);
          }
          final selectedLevel = levelNames.contains(_levelName) ? _levelName! : levelNames.first;
          final inLevel = videos
              .where((v) {
                final name = v.levelName.trim().isEmpty ? 'Lessons' : v.levelName;
                return name == selectedLevel;
              })
              .toList();
          VideoLessonSummary selected;
          final match = inLevel.where((v) => v.id == _videoId);
          selected = match.isNotEmpty ? match.first : inLevel.first;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentVideosProvider),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                PlaygroundLevelStrip(
                  levels: [
                    for (final name in levelNames) PlaygroundLevelItem(id: name, name: name),
                  ],
                  selectedId: selectedLevel,
                  onSelected: (item) => setState(() {
                    _levelName = item.id;
                    _videoId = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                PlaygroundLessonDashboard(
                  units: [
                    for (var i = 0; i < inLevel.length; i++) _unitFor(inLevel[i], i),
                  ],
                  selectedId: selected.id,
                  onSelect: (unit) => setState(() => _videoId = unit.id),
                  onPractice: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoId: selected.id)),
                  ),
                  primaryLabel: 'Watch Lesson',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PlaygroundUnitItem _unitFor(VideoLessonSummary video, int index) {
    final percent = video.progress?.watchPercent ?? 0;
    final done = video.progress?.completed == true;
    return PlaygroundUnitItem(
      id: video.id,
      title: video.title,
      order: index + 1,
      countLabel: video.hasTest ? 'Video · has test' : 'Video lesson',
      description: video.description.trim().isEmpty
          ? 'Watch this lesson. Your progress is saved as you go.'
          : video.description,
      progressPercent: percent,
      mastered: done ? 1 : 0,
      inReview: done ? 0 : 1,
      total: 1,
      masteredLabel: 'Done',
      reviewLabel: 'Watching',
      totalLabel: 'Videos',
    );
  }
}
