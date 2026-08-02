import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/news.dart';
import '../../../providers/news_provider.dart';

class NewsCmsScreen extends ConsumerStatefulWidget {
  const NewsCmsScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<NewsCmsScreen> createState() => _NewsCmsScreenState();
}

class _NewsCmsScreenState extends ConsumerState<NewsCmsScreen> {
  String _status = '';

  Future<void> _createOrEdit({NewsPost? existing}) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final body = TextEditingController(text: existing?.body ?? '');
    final category = TextEditingController(text: existing?.category ?? 'News');
    var type = existing?.type ?? 'announcement';
    var audienceMode = existing?.audience.mode ?? 'everyone';
    var pinned = existing?.pinned ?? false;
    var commentsEnabled = existing?.commentsEnabled ?? true;
    var reactionsEnabled = existing?.reactionsEnabled ?? true;
    var showQuote = existing?.showAsQuoteOfDay ?? false;
    var includePoll = existing?.poll != null || existing?.type == 'poll_embed';
    final pollQuestion = TextEditingController(text: existing?.poll?.question ?? '');
    final optA = TextEditingController(
      text: existing?.poll?.options.isNotEmpty == true ? existing!.poll!.options[0].label : 'Yes',
    );
    final optB = TextEditingController(
      text: (existing?.poll?.options.length ?? 0) > 1 ? existing!.poll!.options[1].label : 'No',
    );
    var pollType = existing?.poll?.pollType ?? 'single';
    var schedulePublish = existing?.status == 'scheduled';
    DateTime? publishAt = existing?.publishAt;
    final eventLocation = TextEditingController(text: existing?.event?.location ?? '');
    final eventJoin = TextEditingController(text: existing?.event?.joinUrl ?? '');
    DateTime? eventStarts = existing?.event?.startsAt;
    final linkUrl = TextEditingController(
      text: existing?.links.isNotEmpty == true ? existing!.links.first.url : '',
    );
    DateTime? quoteDate = existing?.quoteDate ?? (showQuote ? DateTime.now() : null);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Create post' : 'Edit post'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                  TextField(controller: body, decoration: const InputDecoration(labelText: 'Body'), maxLines: 4),
                  TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'announcement', child: Text('Announcement')),
                      DropdownMenuItem(value: 'news', child: Text('News')),
                      DropdownMenuItem(value: 'event', child: Text('Event')),
                      DropdownMenuItem(value: 'motivation', child: Text('Motivation')),
                      DropdownMenuItem(value: 'quote', child: Text('Quote')),
                      DropdownMenuItem(value: 'poll_embed', child: Text('Poll')),
                      DropdownMenuItem(value: 'reminder', child: Text('Reminder')),
                      DropdownMenuItem(value: 'scholarship', child: Text('Scholarship')),
                    ],
                    onChanged: (v) => setLocal(() {
                      type = v ?? type;
                      if (type == 'poll_embed') includePoll = true;
                    }),
                  ),
                  DropdownButtonFormField<String>(
                    value: audienceMode,
                    decoration: const InputDecoration(labelText: 'Audience'),
                    items: const [
                      DropdownMenuItem(value: 'everyone', child: Text('Everyone')),
                      DropdownMenuItem(value: 'roles', child: Text('Roles (students)')),
                      DropdownMenuItem(value: 'branches', child: Text('Branches')),
                      DropdownMenuItem(value: 'groups', child: Text('Groups')),
                      DropdownMenuItem(value: 'subjects', child: Text('Subjects')),
                    ],
                    onChanged: (v) => setLocal(() => audienceMode = v ?? audienceMode),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pinned'),
                    value: pinned,
                    onChanged: (v) => setLocal(() => pinned = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Comments'),
                    value: commentsEnabled,
                    onChanged: (v) => setLocal(() => commentsEnabled = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reactions'),
                    value: reactionsEnabled,
                    onChanged: (v) => setLocal(() => reactionsEnabled = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Quote of the Day'),
                    value: showQuote,
                    onChanged: (v) => setLocal(() {
                      showQuote = v;
                      quoteDate ??= DateTime.now();
                    }),
                  ),
                  if (showQuote)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Quote date: ${quoteDate != null ? quoteDate!.toLocal().toString().split(' ').first : 'Today'}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: quoteDate ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setLocal(() => quoteDate = picked);
                      },
                    ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Schedule publish'),
                    value: schedulePublish,
                    onChanged: (v) => setLocal(() {
                      schedulePublish = v;
                      publishAt ??= DateTime.now().add(const Duration(hours: 1));
                    }),
                  ),
                  if (schedulePublish)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Publish at: ${publishAt?.toLocal() ?? 'pick'}'),
                      trailing: const Icon(Icons.schedule),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: publishAt ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d == null) return;
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.fromDateTime(publishAt ?? DateTime.now()),
                        );
                        if (t == null) return;
                        setLocal(() {
                          publishAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                        });
                      },
                    ),
                  if (type == 'event') ...[
                    TextField(controller: eventLocation, decoration: const InputDecoration(labelText: 'Event location')),
                    TextField(controller: eventJoin, decoration: const InputDecoration(labelText: 'Join URL')),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Starts: ${eventStarts?.toLocal() ?? 'pick date/time'}'),
                      trailing: const Icon(Icons.event),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: eventStarts ?? DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (d == null) return;
                        final t = await showTimePicker(
                          context: ctx,
                          initialTime: TimeOfDay.fromDateTime(eventStarts ?? DateTime.now()),
                        );
                        if (t == null) return;
                        setLocal(() {
                          eventStarts = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                        });
                      },
                    ),
                  ],
                  TextField(controller: linkUrl, decoration: const InputDecoration(labelText: 'Link URL (optional)')),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include poll'),
                    value: includePoll,
                    onChanged: (v) => setLocal(() => includePoll = v),
                  ),
                  if (includePoll) ...[
                    TextField(controller: pollQuestion, decoration: const InputDecoration(labelText: 'Poll question')),
                    DropdownButtonFormField<String>(
                      value: pollType,
                      decoration: const InputDecoration(labelText: 'Poll type'),
                      items: const [
                        DropdownMenuItem(value: 'single', child: Text('Single choice')),
                        DropdownMenuItem(value: 'multiple', child: Text('Multiple')),
                        DropdownMenuItem(value: 'yes_no', child: Text('Yes / No')),
                        DropdownMenuItem(value: 'true_false', child: Text('True / False')),
                        DropdownMenuItem(value: 'rating', child: Text('Rating 1–5')),
                        DropdownMenuItem(value: 'emoji', child: Text('Emoji mood')),
                      ],
                      onChanged: (v) => setLocal(() => pollType = v ?? pollType),
                    ),
                    if (pollType == 'single' || pollType == 'multiple') ...[
                      TextField(controller: optA, decoration: const InputDecoration(labelText: 'Option A')),
                      TextField(controller: optB, decoration: const InputDecoration(labelText: 'Option B')),
                    ],
                    if (pollType == 'rating' || pollType == 'emoji')
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Options are generated automatically for this poll type.'),
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true) return;

    List<Map<String, dynamic>> links = [];
    final url = linkUrl.text.trim();
    if (url.isNotEmpty) {
      try {
        final preview = await ref.read(newsApiProvider).fetchLinkPreview(url);
        links = [preview.toJson()];
      } catch (_) {
        links = [
          {'url': url, 'previewTitle': url},
        ];
      }
    }

    final payload = <String, dynamic>{
      'title': title.text.trim(),
      'body': body.text.trim(),
      'category': category.text.trim().isEmpty ? 'News' : category.text.trim(),
      'type': includePoll ? 'poll_embed' : type,
      'pinned': pinned,
      'commentsEnabled': commentsEnabled,
      'reactionsEnabled': reactionsEnabled,
      'showAsQuoteOfDay': showQuote,
      if (showQuote && quoteDate != null) 'quoteDate': quoteDate!.toIso8601String(),
      if (schedulePublish && publishAt != null) ...{
        'status': 'scheduled',
        'publishAt': publishAt!.toIso8601String(),
      },
      if (type == 'event')
        'event': {
          'location': eventLocation.text.trim(),
          'joinUrl': eventJoin.text.trim(),
          if (eventStarts != null) 'startsAt': eventStarts!.toIso8601String(),
        },
      if (links.isNotEmpty) 'links': links,
      'audience': {
        'mode': audienceMode,
        if (audienceMode == 'roles') 'roles': ['student'],
      },
      if (includePoll)
        'poll': {
          'question': pollQuestion.text.trim().isEmpty ? title.text.trim() : pollQuestion.text.trim(),
          'pollType': pollType,
          if (pollType == 'single' || pollType == 'multiple')
            'options': [
              {'label': optA.text.trim().isEmpty ? 'Option A' : optA.text.trim()},
              {'label': optB.text.trim().isEmpty ? 'Option B' : optB.text.trim()},
            ],
          'status': schedulePublish ? 'scheduled' : 'published',
        },
    };

    try {
      final api = ref.read(newsApiProvider);
      if (existing == null) {
        final created = await api.createPost({
          ...payload,
          if (!schedulePublish) 'status': 'draft',
        });
        if (!schedulePublish) {
          await api.publish(created.id);
        }
      } else {
        await api.updatePost(existing.id, payload);
        if (!schedulePublish && existing.status != 'published') {
          await api.publish(existing.id);
        }
      }
      ref.invalidate(newsAdminProvider(_status));
      ref.invalidate(newsFeedProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _action(NewsPost post, String action) async {
    final api = ref.read(newsApiProvider);
    try {
      switch (action) {
        case 'publish':
          await api.publish(post.id);
          break;
        case 'unpublish':
          await api.unpublish(post.id);
          break;
        case 'pin':
          await api.pin(post.id, pinned: !post.pinned);
          break;
        case 'archive':
          await api.archive(post.id);
          break;
        case 'duplicate':
          await api.duplicate(post.id);
          break;
        case 'delete':
          await api.deletePost(post.id);
          break;
        case 'export_poll':
          if (post.pollId == null || post.pollId!.isEmpty) {
            throw Exception('No poll on this post');
          }
          final csv = await api.exportPollCsv(post.pollId!);
          if (mounted) {
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Poll results CSV'),
                content: SingleChildScrollView(child: SelectableText(csv)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                ],
              ),
            );
          }
          break;
      }
      ref.invalidate(newsAdminProvider(_status));
      ref.invalidate(newsFeedProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navItems.indexWhere(
      (i) => widget.selectedRoute.startsWith(i.route) || i.route.contains('/news'),
    );
    final async = ref.watch(newsAdminProvider(_status));

    return AdaptiveScaffold(
      title: 'News',
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(newsAdminProvider(_status)),
          icon: const Icon(Icons.refresh),
        ),
        FilledButton.tonalIcon(
          onPressed: () => _createOrEdit(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New post'),
        ),
      ],
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                for (final s in [
                  ('', 'All'),
                  ('draft', 'Draft'),
                  ('published', 'Published'),
                  ('scheduled', 'Scheduled'),
                  ('archived', 'Archived'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(s.$2),
                      selected: _status == s.$1,
                      onSelected: (_) => setState(() => _status = s.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const LoadingState(message: 'Loading posts…'),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(newsAdminProvider(_status)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EmptyState(
                    title: 'No posts',
                    message: 'Create an announcement, poll, or quote for the campus feed.',
                    action: FilledButton(onPressed: () => _createOrEdit(), child: const Text('Create post')),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(newsAdminProvider(_status)),
                  child: ListView.separated(
                    padding: AppSpacing.pagePaddingWide,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final p = items[i];
                      return Card(
                        child: ListTile(
                          title: Text(p.title),
                          subtitle: Text(
                            [
                              p.status,
                              p.category,
                              p.type,
                              if (p.pinned) 'pinned',
                              if (p.status == 'scheduled' && p.publishAt != null)
                                p.publishAt!.toLocal().toString().split('.').first,
                              '${p.stats.views} views',
                              '${p.stats.clicks} clicks',
                            ].join(' · '),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') {
                                _createOrEdit(existing: p);
                              } else {
                                _action(p, v);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: p.status == 'published' ? 'unpublish' : 'publish',
                                child: Text(p.status == 'published' ? 'Unpublish' : 'Publish'),
                              ),
                              PopupMenuItem(value: 'pin', child: Text(p.pinned ? 'Unpin' : 'Pin')),
                              const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                              if (p.pollId != null && p.pollId!.isNotEmpty)
                                const PopupMenuItem(value: 'export_poll', child: Text('Export poll CSV')),
                              const PopupMenuItem(value: 'archive', child: Text('Archive')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                          onTap: () => _createOrEdit(existing: p),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
