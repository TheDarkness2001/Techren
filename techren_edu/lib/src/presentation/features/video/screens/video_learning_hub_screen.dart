import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../data/datasources/remote/video_api.dart';
import '../../../../domain/entities/video.dart';
import '../../../providers/scheduling_provider.dart';
import '../../../providers/video_provider.dart';
import 'video_player_screen.dart';

/// Subject-scoped Video Lessons: Levels → 11 classes → YouTube + topic + group unlock.
class VideoLearningHubScreen extends ConsumerStatefulWidget {
  const VideoLearningHubScreen({
    super.key,
    required this.subjectId,
    this.isStudent = false,
    this.routePrefix = '/founder',
    this.navItems = const [],
    this.selectedRoute,
  });

  final String subjectId;
  final bool isStudent;
  final String routePrefix;
  final List<NavItem> navItems;
  final String? selectedRoute;

  @override
  ConsumerState<VideoLearningHubScreen> createState() => _VideoLearningHubScreenState();
}

class _VideoLearningHubScreenState extends ConsumerState<VideoLearningHubScreen> {
  VideoTreeLevel? _level;

  String get _subjectHome => widget.isStudent
      ? '${widget.routePrefix}/learn/${widget.subjectId}'
      : '${widget.routePrefix}/learning/${widget.subjectId}';

  String get _learningSelected =>
      widget.selectedRoute ??
      (widget.isStudent ? '${widget.routePrefix}/learn' : '${widget.routePrefix}/learning');

  @override
  Widget build(BuildContext context) {
    final treeAsync = ref.watch(videoSubjectTreeProvider(widget.subjectId));
    final body = treeAsync.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
      error: (e, _) => EmptyState(
        title: 'Could not load video lessons',
        message: e.toString(),
        icon: Icons.error_outline,
        action: FilledButton(
          onPressed: () => ref.invalidate(videoSubjectTreeProvider(widget.subjectId)),
          child: const Text('Retry'),
        ),
      ),
      data: (tree) {
        if (_level == null) {
          return _LevelsView(
            tree: tree,
            isStudent: widget.isStudent,
            onOpenLevel: (level) => setState(() => _level = level),
            onCreateLevel: widget.isStudent ? null : _createLevel,
          );
        }
        return _ClassesView(
          subjectId: widget.subjectId,
          tree: tree,
          level: _level!,
          isStudent: widget.isStudent,
          onBack: () => setState(() => _level = null),
          onOpenVideo: (video) {
            if (widget.isStudent) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoId: video.id)),
              );
            } else {
              _editClass(tree: tree, level: _level!, existing: video);
            }
          },
          onAddOrEditSlot: widget.isStudent
              ? null
              : (order, existing) => _editClass(tree: tree, level: _level!, order: order, existing: existing),
          onUnlock: widget.isStudent ? null : _unlockVideo,
        );
      },
    );

    final actions = <Widget>[
      IconButton(
        tooltip: 'Back',
        onPressed: () {
          if (_level != null) {
            setState(() => _level = null);
          } else {
            context.go(_subjectHome);
          }
        },
        icon: const Icon(Icons.arrow_back),
      ),
    ];

    if (!widget.isStudent && widget.navItems.isNotEmpty) {
      final selectedIndex = widget.navItems.indexWhere(
        (i) => _learningSelected.startsWith(i.route) || i.route.contains('/learning'),
      );
      return AdaptiveScaffold(
        title: 'Video Lessons',
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        selectedRoute: _learningSelected,
        items: widget.navItems,
        onDestinationSelected: (i) => context.go(widget.navItems[i].route),
        actions: actions,
        body: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_level == null ? 'Video Lessons' : _level!.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_level != null) {
              setState(() => _level = null);
            } else {
              context.go(_subjectHome);
            }
          },
        ),
      ),
      body: Padding(padding: AppSpacing.pagePaddingWide, child: body),
    );
  }

  Future<void> _createLevel(VideoSubjectTree tree) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New level'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Level name',
            hintText: 'e.g. A1, Beginner',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(videoApiProvider).createLevel(
            subjectId: widget.subjectId,
            name: name,
            classesCount: 11,
          );
      ref.invalidate(videoSubjectTreeProvider(widget.subjectId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Level “$name” created (11 classes)')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _editClass({
    required VideoSubjectTree tree,
    required VideoTreeLevel level,
    int? order,
    VideoLessonSummary? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? 'Class ${order ?? existing?.order ?? 1}');
    final topicCtrl = TextEditingController(text: existing?.topic ?? '');
    final infoCtrl = TextEditingController(text: existing?.description ?? '');
    final youtubeCtrl = TextEditingController(text: existing?.youtubeUrl ?? '');
    final classOrder = order ?? existing?.order ?? 1;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Class $classOrder' : 'Edit class $classOrder'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: youtubeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'YouTube URL',
                    hintText: 'https://youtube.com/watch?v=…',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(controller: topicCtrl, decoration: const InputDecoration(labelText: 'Topic')),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: infoCtrl,
                  decoration: const InputDecoration(labelText: 'Topic information'),
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;

    final body = {
      'title': titleCtrl.text.trim(),
      'youtubeUrl': youtubeCtrl.text.trim(),
      'topic': topicCtrl.text.trim(),
      'description': infoCtrl.text.trim(),
      'languageId': tree.languageId,
      'levelId': level.id,
      'subjectId': widget.subjectId,
      'order': classOrder,
    };

    try {
      if (existing == null) {
        await ref.read(videoApiProvider).createVideo(body);
      } else {
        await ref.read(videoApiProvider).updateVideo(existing.id, body);
      }
      ref.invalidate(videoLevelClassesProvider((subjectId: widget.subjectId, levelId: level.id)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  Future<void> _unlockVideo(VideoLessonSummary video) async {
    final groups = await ref.read(examGroupsProvider.future);
    if (!mounted) return;
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No groups found')));
      return;
    }
    var selected = groups.first;
    final unlock = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Unlock “${video.title}”'),
          content: DropdownButtonFormField<String>(
            value: selected.id,
            items: [
              for (final g in groups) DropdownMenuItem(value: g.id, child: Text(g.groupName)),
            ],
            onChanged: (id) {
              selected = groups.firstWhere((g) => g.id == id, orElse: () => groups.first);
              setLocal(() {});
            },
            decoration: const InputDecoration(labelText: 'Group'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Lock')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Unlock')),
          ],
        ),
      ),
    );
    if (unlock == null) return;
    try {
      await ref.read(videoApiProvider).toggleWatchUnlock(
            videoId: video.id,
            groupId: selected.id,
            unlock: unlock,
          );
      ref.invalidate(videoLevelClassesProvider((subjectId: widget.subjectId, levelId: video.levelId)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(unlock ? 'Unlocked for ${selected.groupName}' : 'Locked for ${selected.groupName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _LevelsView extends StatelessWidget {
  const _LevelsView({
    required this.tree,
    required this.isStudent,
    required this.onOpenLevel,
    this.onCreateLevel,
  });

  final VideoSubjectTree tree;
  final bool isStudent;
  final ValueChanged<VideoTreeLevel> onOpenLevel;
  final Future<void> Function(VideoSubjectTree tree)? onCreateLevel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Text(
          '${tree.subjectName} · Video levels',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          isStudent
              ? 'Open a level to see unlocked classes.'
              : 'Each level has up to 11 classes. Add a YouTube link and topic info per class, then unlock by group.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        if (!isStudent && onCreateLevel != null)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => onCreateLevel!(tree),
              icon: const Icon(Icons.add),
              label: const Text('Add level'),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (tree.levels.isEmpty)
          EmptyState(
            title: 'No levels yet',
            message: isStudent ? 'Your teacher has not created video levels.' : 'Create a level (e.g. A1) with 11 class slots.',
            icon: Icons.layers_outlined,
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final level in tree.levels)
                SizedBox(
                  width: 140,
                  height: 96,
                  child: Card(
                    child: InkWell(
                      onTap: () => onOpenLevel(level),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(level.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('${level.classesCount} classes', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _ClassesView extends ConsumerWidget {
  const _ClassesView({
    required this.subjectId,
    required this.tree,
    required this.level,
    required this.isStudent,
    required this.onBack,
    required this.onOpenVideo,
    this.onAddOrEditSlot,
    this.onUnlock,
  });

  final String subjectId;
  final VideoSubjectTree tree;
  final VideoTreeLevel level;
  final bool isStudent;
  final VoidCallback onBack;
  final ValueChanged<VideoLessonSummary> onOpenVideo;
  final void Function(int order, VideoLessonSummary? existing)? onAddOrEditSlot;
  final ValueChanged<VideoLessonSummary>? onUnlock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classesAsync = ref.watch(videoLevelClassesProvider((subjectId: subjectId, levelId: level.id)));
    final slots = level.classesCount.clamp(1, 20);

    return classesAsync.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
      error: (e, _) => Text(e.toString()),
      data: (videos) {
        final byOrder = <int, VideoLessonSummary>{
          for (final v in videos) v.order: v,
        };

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to levels'),
              ),
            ),
            Text(
              '${level.name} · Classes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            for (var i = 1; i <= slots; i++) ...[
              _ClassTile(
                order: i,
                video: byOrder[i],
                isStudent: isStudent,
                onOpen: onOpenVideo,
                onEdit: onAddOrEditSlot == null ? null : () => onAddOrEditSlot!(i, byOrder[i]),
                onUnlock: onUnlock,
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        );
      },
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile({
    required this.order,
    required this.video,
    required this.isStudent,
    required this.onOpen,
    this.onEdit,
    this.onUnlock,
  });

  final int order;
  final VideoLessonSummary? video;
  final bool isStudent;
  final ValueChanged<VideoLessonSummary> onOpen;
  final VoidCallback? onEdit;
  final ValueChanged<VideoLessonSummary>? onUnlock;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    if (video == null) {
      return Card(
        child: ListTile(
          leading: CircleAvatar(child: Text('$order')),
          title: Text('Class $order'),
          subtitle: Text(isStudent ? 'Not available' : 'Empty — add YouTube + topic'),
          trailing: onEdit == null ? null : IconButton(icon: const Icon(Icons.add), onPressed: onEdit),
        ),
      );
    }

    final v = video!;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: v.thumbnail.isNotEmpty ? NetworkImage(v.thumbnail) : null,
          child: v.thumbnail.isEmpty ? Text('$order') : null,
        ),
        title: Text(v.title.isEmpty ? 'Class $order' : v.title),
        subtitle: Text(
          [
            if (v.topic.isNotEmpty) v.topic,
            if (v.watchUnlockedFor.isNotEmpty) '${v.watchUnlockedFor.length} groups unlocked',
            if (v.watchUnlockedFor.isEmpty && !isStudent) 'Locked for all groups',
          ].where((s) => s.isNotEmpty).join(' · '),
          style: TextStyle(color: muted, fontSize: 12),
        ),
        onTap: () {
          if (isStudent) {
            onOpen(v);
          } else {
            onEdit?.call();
          }
        },
        trailing: isStudent
            ? const Icon(Icons.play_arrow)
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'unlock') onUnlock?.call(v);
                  if (value == 'preview') onOpen(v);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'unlock', child: Text('Unlock / lock group')),
                  PopupMenuItem(value: 'preview', child: Text('Preview player')),
                ],
              ),
      ),
    );
  }
}
