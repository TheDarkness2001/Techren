import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/ielts.dart';
import '../../../providers/ielts_provider.dart';
import '../../../shells/staff_shell.dart';

/// Staff library CMS: books, audio recordings, and articles used as the
/// origin of listening/reading sections and bank items.
class IeltsSourcesScreen extends ConsumerStatefulWidget {
  const IeltsSourcesScreen({
    super.key,
    required this.subjectId,
    this.routePrefix = '/admin',
    this.navItems = const [],
    this.selectedRoute,
  });

  final String subjectId;
  final String routePrefix;
  final List<NavItem> navItems;
  final String? selectedRoute;

  @override
  ConsumerState<IeltsSourcesScreen> createState() => _IeltsSourcesScreenState();
}

class _IeltsSourcesScreenState extends ConsumerState<IeltsSourcesScreen> {
  String get _hub => '${widget.routePrefix}/learning/${widget.subjectId}/ielts';
  String get _learningSelected => widget.selectedRoute ?? '${widget.routePrefix}/learning';

  static const _kinds = ['listening', 'reading', 'mixed', 'other'];
  static const _difficulties = ['Easy', 'Medium', 'Hard', 'IELTS 5', 'IELTS 6', 'IELTS 7', 'IELTS 8', 'IELTS 9'];
  static const _topics = [
    'Science',
    'Business',
    'Education',
    'Environment',
    'Technology',
    'History',
    'Travel',
    'Medicine',
    'Culture',
    'Nature',
    'Psychology',
    'Economics',
    'Engineering',
    'General',
    'Custom',
  ];

  Future<void> _openEditor({IeltsSource? existing}) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final author = TextEditingController(text: existing?.author ?? '');
    final publisher = TextEditingController(text: existing?.publisher ?? '');
    final url = TextEditingController(text: existing?.originalUrl ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    final tags = TextEditingController(text: (existing?.tags ?? const []).join(', '));
    var kind = existing?.kind ?? 'reading';
    var difficulty = existing?.difficulty ?? 'Medium';
    var topic = existing?.topic ?? 'General';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add source' : 'Edit source'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                  const SizedBox(height: 8),
                  TextField(controller: author, decoration: const InputDecoration(labelText: 'Author')),
                  const SizedBox(height: 8),
                  TextField(controller: publisher, decoration: const InputDecoration(labelText: 'Publisher / publication')),
                  const SizedBox(height: 8),
                  TextField(controller: url, decoration: const InputDecoration(labelText: 'Original URL')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: kind,
                    items: _kinds.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                    onChanged: (v) => setLocal(() => kind = v ?? kind),
                    decoration: const InputDecoration(labelText: 'Kind'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: topic,
                    items: _topics.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setLocal(() => topic = v ?? topic),
                    decoration: const InputDecoration(labelText: 'Topic'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: difficulty,
                    items: _difficulties.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setLocal(() => difficulty = v ?? difficulty),
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                  ),
                  const SizedBox(height: 8),
                  TextField(controller: tags, decoration: const InputDecoration(labelText: 'Tags (comma-separated)')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(existing == null ? 'Add' : 'Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;

    final body = {
      'subjectId': widget.subjectId,
      'title': title.text.trim(),
      'author': author.text.trim(),
      'publisher': publisher.text.trim(),
      'originalUrl': url.text.trim(),
      'kind': kind,
      'topic': topic,
      'difficulty': difficulty,
      'tags': tags.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'notes': notes.text.trim(),
    };

    if (existing == null) {
      await ref.read(ieltsApiProvider).createSource(body);
    } else {
      await ref.read(ieltsApiProvider).updateSource(existing.id, body);
    }
    ref.invalidate(ieltsSourcesProvider(widget.subjectId));
  }

  Future<void> _delete(IeltsSource source) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${source.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(ieltsApiProvider).deleteSource(source.id);
    ref.invalidate(ieltsSourcesProvider(widget.subjectId));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ieltsSourcesProvider(widget.subjectId));
    final muted = context.semantic.textMuted;

    final body = async.when(
      loading: () => const LoadingState(message: 'Loading sources...'),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(ieltsSourcesProvider(widget.subjectId))),
      data: (sources) {
        if (sources.isEmpty) {
          return EmptyState(
            title: 'No sources yet',
            message: 'Add books, audio recordings, or articles to track provenance for exam content.',
            icon: Icons.source_outlined,
            action: FilledButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Add source'),
            ),
          );
        }
        return ListView.separated(
          padding: AppSpacing.pagePaddingWide,
          itemCount: sources.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final s = sources[i];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.card,
                side: BorderSide(color: context.semantic.border),
              ),
              title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                [
                  s.kind,
                  s.topic,
                  s.difficulty,
                  if (s.author.isNotEmpty) 'by ${s.author}',
                ].join(' · '),
                style: TextStyle(color: muted),
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => _openEditor(existing: s),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => _delete(s),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final navItems = widget.navItems.isNotEmpty
        ? widget.navItems
        : (widget.routePrefix.startsWith('/founder') ? founderNavItems : adminNavItems);
    final selectedIndex = navItems.indexWhere(
      (i) => _learningSelected.startsWith(i.route) || i.route.contains('/learning'),
    );

    return AdaptiveScaffold(
      title: 'IELTS Sources',
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      selectedRoute: _learningSelected,
      items: navItems,
      onDestinationSelected: (i) => context.go(navItems[i].route),
      actions: [
        IconButton(
          tooltip: 'Back to IELTS Preparation',
          onPressed: () => context.go(_hub),
          icon: const Icon(Icons.arrow_back),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add source'),
      ),
      body: body,
    );
  }
}
