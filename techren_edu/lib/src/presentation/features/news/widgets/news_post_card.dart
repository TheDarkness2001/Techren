import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/communications_socket.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../domain/entities/news.dart';
import '../../../providers/communications_provider.dart';
import '../../../providers/news_provider.dart';

const _reactionEmojis = {
  'like': '👍',
  'love': '❤️',
  'celebrate': '🎉',
  'fire': '🔥',
  'helpful': '💡',
};

class NewsPostCard extends ConsumerStatefulWidget {
  const NewsPostCard({
    super.key,
    required this.post,
    this.onUpdated,
    this.compact = false,
  });

  final NewsPost post;
  final ValueChanged<NewsPost>? onUpdated;
  final bool compact;

  @override
  ConsumerState<NewsPostCard> createState() => _NewsPostCardState();
}

class _NewsPostCardState extends ConsumerState<NewsPostCard> {
  late NewsPost _post;
  bool _showComments = false;
  final _commentCtrl = TextEditingController();
  bool _busy = false;
  CommunicationsSocket? _socket;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindPollSocket());
  }

  Future<void> _bindPollSocket() async {
    final pollId = _post.poll?.id;
    if (pollId == null || pollId.isEmpty) return;
    final socket = ref.read(communicationsSocketProvider);
    _socket = socket;
    await socket.connect();
    socket.joinPoll(pollId);
    socket.on('poll-results', _onPollResults);
    socket.on('poll-closed', _onPollResults);
  }

  void _onPollResults(dynamic data) {
    if (data is! Map) return;
    final poll = NewsPoll.fromJson(Map<String, dynamic>.from(data));
    if (poll.id != _post.poll?.id) return;
    if (!mounted) return;
    setState(() => _post = _post.copyWith(poll: poll));
  }

  @override
  void didUpdateWidget(covariant NewsPostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id || oldWidget.post.poll != widget.post.poll) {
      _post = widget.post;
    }
  }

  @override
  void dispose() {
    final pollId = _post.poll?.id;
    if (pollId != null) {
      _socket?.leavePoll(pollId);
      _socket?.off('poll-results', _onPollResults);
      _socket?.off('poll-closed', _onPollResults);
    }
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _react(String emoji) async {
    if (_busy || !_post.reactionsEnabled) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(newsApiProvider);
      final updated = _post.myReaction == emoji
          ? await api.unreact(_post.id)
          : await api.react(_post.id, emoji);
      setState(() => _post = updated);
      widget.onUpdated?.call(updated);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _vote(String optionId) async {
    final poll = _post.poll;
    if (poll == null || _busy) return;
    if (!poll.open) return;
    if (poll.hasVoted && !poll.allowChangeVote) return;
    setState(() => _busy = true);
    try {
      List<String> selected;
      if (poll.pollType == 'multiple') {
        selected = [...poll.myOptionIds];
        if (selected.contains(optionId)) {
          selected.remove(optionId);
        } else {
          selected.add(optionId);
        }
        if (selected.isEmpty) {
          setState(() => _busy = false);
          return;
        }
      } else {
        selected = [optionId];
      }
      final updatedPoll = await ref.read(newsApiProvider).vote(poll.id, selected);
      final updated = _post.copyWith(poll: updatedPoll);
      setState(() => _post = updated);
      widget.onUpdated?.call(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(newsApiProvider).addComment(_post.id, text);
      _commentCtrl.clear();
      ref.invalidate(newsCommentsProvider(_post.id));
      final refreshed = await ref.read(newsApiProvider).getPost(_post.id);
      setState(() => _post = refreshed);
      widget.onUpdated?.call(refreshed);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final bodyPreview = _post.body.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    final poll = _post.poll;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: semantic.surfaceContainer,
        borderRadius: AppRadius.card,
        border: Border.all(color: semantic.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_post.pinned)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.push_pin, size: 16, color: semantic.textMuted),
                ),
              Expanded(
                child: Text(_post.title, style: Theme.of(context).textTheme.titleMedium),
              ),
              Chip(
                label: Text(_post.category, style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (_post.authorName.isNotEmpty) _post.authorName,
              if (_post.publishAt != null) _formatDate(_post.publishAt!),
              _post.type,
            ].where((e) => e.isNotEmpty).join(' · '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: semantic.textMuted),
          ),
          if (bodyPreview.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              bodyPreview,
              maxLines: widget.compact ? 4 : 12,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (_post.event != null && (_post.event!.location.isNotEmpty || _post.event!.startsAt != null)) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              [
                if (_post.event!.startsAt != null) _formatDate(_post.event!.startsAt!),
                if (_post.event!.location.isNotEmpty) _post.event!.location,
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_post.event!.startsAt != null)
              Text(
                _countdown(_post.event!.startsAt!),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            Wrap(
              spacing: 8,
              children: [
                if (_post.event!.joinUrl.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await ref.read(newsApiProvider).recordClick(_post.id);
                      launchUrl(Uri.parse(_post.event!.joinUrl));
                    },
                    child: const Text('Join event'),
                  ),
                TextButton(
                  onPressed: (_busy || _post.event!.registered)
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          try {
                            final updated = await ref.read(newsApiProvider).registerForEvent(_post.id);
                            setState(() => _post = updated);
                            widget.onUpdated?.call(updated);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  child: Text(
                    _post.event!.registered
                        ? 'Registered${_post.event!.registrationCount > 0 ? ' (${_post.event!.registrationCount})' : ''}'
                        : 'Register${_post.event!.registrationCount > 0 ? ' (${_post.event!.registrationCount})' : ''}',
                  ),
                ),
              ],
            ),
          ],
          for (final m in _post.media.take(2))
            if (m.kind == 'image' && m.url.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: ClipRRect(
                  borderRadius: AppRadius.card,
                  child: Image.network(
                    resolveMediaUrl(m.url),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
          for (final link in _post.links.take(2))
            if (link.url.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(top: 8),
                child: ListTile(
                  leading: link.previewImage.isNotEmpty
                      ? Image.network(resolveMediaUrl(link.previewImage), width: 48, height: 48, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.link))
                      : const Icon(Icons.link),
                  title: Text(link.previewTitle.isEmpty ? link.url : link.previewTitle, maxLines: 2),
                  subtitle: link.previewDesc.isEmpty ? null : Text(link.previewDesc, maxLines: 2),
                  onTap: () async {
                    await ref.read(newsApiProvider).recordClick(_post.id);
                    launchUrl(Uri.parse(link.url));
                  },
                ),
              ),
          Text(
            '${_post.stats.views} views · ${_post.stats.clicks} clicks',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: semantic.textMuted),
          ),
          if (poll != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(poll.question, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            for (final opt in poll.options) _PollOptionBar(option: opt, poll: poll, onTap: () => _vote(opt.id)),
            if (poll.totalVoters != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${poll.totalVoters} vote${poll.totalVoters == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: semantic.textMuted),
                ),
              ),
          ],
          if (_post.reactionsEnabled) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 4,
              children: [
                for (final e in _reactionEmojis.entries)
                  ActionChip(
                    avatar: Text(e.value),
                    label: Text('${_post.stats.reactionCounts[e.key] ?? 0}'),
                    onPressed: () => _react(e.key),
                    backgroundColor: _post.myReaction == e.key
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
          if (_post.commentsEnabled) ...[
            TextButton.icon(
              onPressed: () => setState(() => _showComments = !_showComments),
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: Text('Comments (${_post.stats.commentCount})'),
            ),
            if (_showComments) ...[
              _CommentsBlock(postId: _post.id),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: const InputDecoration(hintText: 'Add a comment…', isDense: true),
                      onSubmitted: (_) => _submitComment(),
                    ),
                  ),
                  IconButton(onPressed: _busy ? null : _submitComment, icon: const Icon(Icons.send)),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _countdown(DateTime startsAt) {
    final diff = startsAt.toLocal().difference(DateTime.now());
    if (diff.isNegative) return 'Started';
    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;
    if (days > 0) return 'Starts in ${days}d ${hours}h';
    if (hours > 0) return 'Starts in ${hours}h ${mins}m';
    return 'Starts in ${mins}m';
  }
}

class _PollOptionBar extends StatelessWidget {
  const _PollOptionBar({required this.option, required this.poll, required this.onTap});

  final PollOption option;
  final NewsPoll poll;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = poll.myOptionIds.contains(option.id);
    final percent = (option.percent ?? 0).clamp(0, 100) / 100;
    final showBar = option.percent != null || option.count != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: poll.open && (!poll.hasVoted || poll.allowChangeVote || poll.pollType == 'multiple')
            ? onTap
            : null,
        borderRadius: AppRadius.chip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: AppRadius.chip,
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.primary : context.semantic.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(option.label)),
                  if (option.percent != null) Text('${option.percent!.toStringAsFixed(0)}%'),
                  if (option.count != null && option.percent == null) Text('${option.count}'),
                ],
              ),
              if (showBar) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent.toDouble(),
                    minHeight: 6,
                    backgroundColor: context.semantic.border.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentsBlock extends ConsumerWidget {
  const _CommentsBlock({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(newsCommentsProvider(postId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Text('$e'),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('No comments yet', style: TextStyle(color: context.semantic.textMuted)),
          );
        }
        return Column(
          children: [
            for (final c in items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(c.authorName.isEmpty ? 'User' : c.authorName),
                subtitle: Text(c.body),
              ),
          ],
        );
      },
    );
  }
}
