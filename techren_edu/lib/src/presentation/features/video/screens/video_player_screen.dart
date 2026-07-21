import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../providers/video_provider.dart';
import 'video_test_leaderboard_screen.dart';
import 'video_test_screen.dart';

class VideoPlayerScreen extends ConsumerStatefulWidget {
  const VideoPlayerScreen({super.key, required this.videoId});

  final String videoId;

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  double _watchPercent = 0;
  bool _saving = false;

  Future<void> _openYouTube(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      await ref.read(videoApiProvider).trackProgress(widget.videoId, watchPercent: _watchPercent.toInt(), newSession: true);
    }
  }

  Future<void> _saveProgress() async {
    setState(() => _saving = true);
    try {
      final progress = await ref.read(videoApiProvider).trackProgress(
            widget.videoId,
            watchPercent: _watchPercent.round(),
            delta: 15,
          );
      if (mounted) setState(() => _watchPercent = progress.watchPercent.toDouble());
      ref.invalidate(videoDetailProvider(widget.videoId));
      ref.invalidate(studentVideosProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(videoDetailProvider(widget.videoId));

    return Scaffold(
      appBar: AppBar(title: const Text('Video Lesson')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (detail) {
          final video = detail.lesson;
          final progress = detail.progress ?? video.progress;
          final currentPercent = _watchPercent > 0 ? _watchPercent : (progress?.watchPercent ?? 0).toDouble();
          final threshold = video.requireWatchPercent;
          final canTakeExam = currentPercent >= threshold;

          return ListView(
            padding: AppSpacing.listGutter,
            children: [
              if (video.thumbnail.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(video.thumbnail, fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Text(video.title, style: Theme.of(context).textTheme.headlineSmall),
              if (video.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(video.description),
              ],
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => _openYouTube(video.youtubeUrl),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Watch on YouTube'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Watch progress', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Slider(
                value: currentPercent.clamp(0, 100),
                min: 0,
                max: 100,
                divisions: 20,
                label: '${currentPercent.round()}%',
                onChanged: (v) => setState(() => _watchPercent = v),
              ),
              Text('Required for exam: $threshold%'),
              const SizedBox(height: AppSpacing.xs),
              FilledButton(
                onPressed: _saving ? null : _saveProgress,
                child: Text(_saving ? 'Saving...' : 'Save progress'),
              ),
              if (progress?.completed == true || currentPercent >= threshold)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Chip(
                    avatar: Icon(Icons.check_circle, color: AppColors.success, size: 18),
                    label: const Text('Watch requirement met'),
                  ),
                ),
              if (detail.hasTest) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Topic test', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (detail.testMeta?.practiceEnabled == true)
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VideoTestScreen(videoId: widget.videoId, mode: 'practice'),
                          ),
                        ),
                        child: const Text('Practice test'),
                      ),
                    FilledButton(
                      onPressed: canTakeExam
                          ? () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => VideoTestScreen(videoId: widget.videoId, mode: 'exam'),
                                ),
                              )
                          : null,
                      child: const Text('Take exam'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => VideoTestLeaderboardScreen(videoId: widget.videoId, videoTitle: video.title),
                        ),
                      ),
                      child: const Text('Leaderboard'),
                    ),
                  ],
                ),
                if (!canTakeExam)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      'Watch at least $threshold% before taking the exam.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
