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
import '../ielts_ui.dart';

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
          insetPadding: IeltsUi.dialogInset,
          titlePadding: IeltsUi.titlePadding,
          contentPadding: IeltsUi.contentPadding,
          actionsPadding: IeltsUi.actionsPadding,
          title: Text(existing == null ? 'Add source' : 'Edit source'),
          content: ConstrainedBox(
            constraints: IeltsUi.dialogConstraints(ctx),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(controller: title, decoration: IeltsUi.field('Title')),
                  IeltsUi.fieldGap,
                  TextField(controller: author, decoration: IeltsUi.field('Author')),
                  IeltsUi.fieldGap,
                  TextField(controller: publisher, decoration: IeltsUi.field('Publisher / publication')),
                  IeltsUi.fieldGap,
                  TextField(controller: url, decoration: IeltsUi.field('Original URL')),
                  IeltsUi.fieldGap,
                  DropdownButtonFormField<String>(
                    value: kind,
                    items: _kinds.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                    onChanged: (v) => setLocal(() => kind = v ?? kind),
                    decoration: IeltsUi.field('Kind'),
                  ),
                  IeltsUi.fieldGap,
                  DropdownButtonFormField<String>(
                    value: topic,
                    items: _topics.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setLocal(() => topic = v ?? topic),
                    decoration: IeltsUi.field('Topic'),
                  ),
                  IeltsUi.fieldGap,
                  DropdownButtonFormField<String>(
                    value: difficulty,
                    items: _difficulties.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (v) => setLocal(() => difficulty = v ?? difficulty),
                    decoration: IeltsUi.field('Difficulty'),
                  ),
                  IeltsUi.fieldGap,
                  TextField(controller: tags, decoration: IeltsUi.field('Tags (comma-separated)')),
                  IeltsUi.fieldGap,
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: IeltsUi.field('Notes', alignHint: true),
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
        insetPadding: IeltsUi.dialogInset,
        titlePadding: IeltsUi.titlePadding,
        actionsPadding: IeltsUi.actionsPadding,
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
          separatorBuilder: (_, __) => const SizedBox(height: IeltsUi.listGap),
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
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Edit',
                    onPressed: () => _openEditor(existing: s),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
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
