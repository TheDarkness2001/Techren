import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/ielts.dart';
import '../../../providers/ielts_provider.dart';
import '../../../shells/staff_shell.dart';

/// Staff question bank: reusable listening/reading questions with immutable
/// versions. Adding a bank version into an exam section happens from the
/// exam editor's "Add from bank" dialog.
class IeltsBankScreen extends ConsumerStatefulWidget {
  const IeltsBankScreen({
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
  ConsumerState<IeltsBankScreen> createState() => _IeltsBankScreenState();
}

List<String> typesForSkill(String skill) {
  if (skill == 'listening') {
    return [
      'mcq',
      'matching',
      'form_completion',
      'sentence_completion',
      'table_completion',
      'short_answer',
      'map_labeling',
    ];
  }
  return [
    'tfng',
    'ynng',
    'mcq',
    'matching_headings',
    'summary_completion',
    'table_completion',
    'short_answer',
    'diagram_labeling',
  ];
}

class _IeltsBankScreenState extends ConsumerState<IeltsBankScreen> {
  String? _skillFilter;
  String _search = '';

  String get _hub => '${widget.routePrefix}/learning/${widget.subjectId}/ielts';
  String get _learningSelected => widget.selectedRoute ?? '${widget.routePrefix}/learning';

  ({String? subjectId, String? skill, String? q}) get _args =>
      (subjectId: widget.subjectId, skill: _skillFilter, q: _search.isEmpty ? null : _search);

  Future<void> _openCreate() async {
    var skill = 'reading';
    var type = typesForSkill(skill).first;
    final title = TextEditingController();
    final topic = TextEditingController(text: 'General');
    final difficulty = TextEditingController(text: 'Medium');
    final tags = TextEditingController();
    final prompt = TextEditingController();
    final instruction = TextEditingController();
    final options = TextEditingController();
    final answers = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final showOptions = type == 'mcq' || type == 'tfng' || type == 'ynng';
          return AlertDialog(
            title: const Text('New bank item'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: skill,
                      items: const [
                        DropdownMenuItem(value: 'listening', child: Text('Listening')),
                        DropdownMenuItem(value: 'reading', child: Text('Reading')),
                      ],
                      onChanged: (v) => setLocal(() {
                        skill = v ?? skill;
                        type = typesForSkill(skill).first;
                      }),
                      decoration: const InputDecoration(labelText: 'Skill'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: type,
                      items: typesForSkill(skill).map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setLocal(() => type = v ?? type),
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                    const SizedBox(height: 8),
                    TextField(controller: topic, decoration: const InputDecoration(labelText: 'Topic')),
                    const SizedBox(height: 8),
                    TextField(controller: difficulty, decoration: const InputDecoration(labelText: 'Difficulty')),
                    const SizedBox(height: 8),
                    TextField(controller: tags, decoration: const InputDecoration(labelText: 'Tags (comma-separated)')),
                    const Divider(height: 24),
                    TextField(
                      controller: prompt,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Prompt', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: instruction, decoration: const InputDecoration(labelText: 'Instruction')),
                    if (showOptions) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: options,
                        decoration: const InputDecoration(labelText: 'Options (comma-separated)'),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(
                      controller: answers,
                      decoration: const InputDecoration(labelText: 'Correct answers (comma-separated)'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
            ],
          );
        },
      ),
    );
    if (ok != true) return;

    final opts = options.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final ansList = answers.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    await ref.read(ieltsApiProvider).createBankItem({
      'subjectId': widget.subjectId,
      'skill': skill,
      'type': type,
      'title': title.text.trim(),
      'topic': topic.text.trim().isEmpty ? 'General' : topic.text.trim(),
      'difficulty': difficulty.text.trim().isEmpty ? 'Medium' : difficulty.text.trim(),
      'tags': tags.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      'prompt': prompt.text.trim(),
      'instruction': instruction.text.trim(),
      'options': opts,
      'answers': ansList,
      'acceptedAnswers': {
        'primary': ansList.isNotEmpty ? ansList.first : '',
        'alternatives': ansList.length > 1 ? ansList.sublist(1) : <String>[],
      },
    });
    ref.invalidate(ieltsBankProvider(_args));
  }

  Future<void> _addVersion(IeltsBankItem item) async {
    final latest = item.latestPayload ?? const {};
    final prompt = TextEditingController(text: latest['prompt']?.toString() ?? '');
    final options = TextEditingController(text: (latest['options'] as List<dynamic>? ?? []).join(', '));
    final answers = TextEditingController(text: (latest['answers'] as List<dynamic>? ?? []).join(', '));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New version for "${item.title}"'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: prompt,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Prompt', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(controller: options, decoration: const InputDecoration(labelText: 'Options (comma-separated)')),
              const SizedBox(height: 8),
              TextField(controller: answers, decoration: const InputDecoration(labelText: 'Answers (comma-separated)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Publish version')),
        ],
      ),
    );
    if (ok != true) return;

    final opts = options.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final ansList = answers.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    await ref.read(ieltsApiProvider).publishBankVersion(item.id, {
      'type': item.type,
      'prompt': prompt.text.trim(),
      'options': opts,
      'answers': ansList,
      'acceptedAnswers': {
        'primary': ansList.isNotEmpty ? ansList.first : '',
        'alternatives': ansList.length > 1 ? ansList.sublist(1) : <String>[],
      },
    });
    ref.invalidate(ieltsBankProvider(_args));
  }

  Future<void> _showVersions(IeltsBankItem item) async {
    final full = await ref.read(ieltsApiProvider).getBankItem(item.id);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${full.title} — versions'),
        content: SizedBox(
          width: 460,
          height: 360,
          child: full.versions.isEmpty
              ? const Center(child: Text('No versions yet'))
              : ListView.separated(
                  itemCount: full.versions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final v = full.versions[i];
                    final p = v.payload['prompt']?.toString() ?? '';
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(radius: 14, child: Text('v${v.version}', style: const TextStyle(fontSize: 11))),
                      title: Text(p.isEmpty ? '(no prompt)' : p, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(v.createdAt?.toLocal().toString().split('.').first ?? ''),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _delete(IeltsBankItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${item.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(ieltsApiProvider).deleteBankItem(item.id);
    ref.invalidate(ieltsBankProvider(_args));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ieltsBankProvider(_args));
    final muted = context.semantic.textMuted;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search title or tags',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (v) => setState(() => _search = v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                value: _skillFilter,
                hint: const Text('All skills'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All skills')),
                  DropdownMenuItem(value: 'listening', child: Text('Listening')),
                  DropdownMenuItem(value: 'reading', child: Text('Reading')),
                ],
                onChanged: (v) => setState(() => _skillFilter = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const LoadingState(message: 'Loading bank...'),
            error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(ieltsBankProvider(_args))),
            data: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  title: 'No bank items yet',
                  message: 'Create reusable questions here, then add them into exam sections from the editor.',
                  icon: Icons.storage_outlined,
                  action: FilledButton.icon(
                    onPressed: _openCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('New bank item'),
                  ),
                );
              }
              return ListView.separated(
                padding: AppSpacing.pagePaddingWide,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final item = items[i];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.card,
                      side: BorderSide(color: context.semantic.border),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Icon(
                        item.skill == 'listening' ? Icons.headphones : Icons.menu_book,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      item.title.isEmpty ? '(untitled)' : item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${item.type} · ${item.topic} · ${item.difficulty} · v${item.latestVersion}',
                      style: TextStyle(color: muted),
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'View versions',
                          onPressed: () => _showVersions(item),
                          icon: const Icon(Icons.history, size: 20),
                        ),
                        IconButton(
                          tooltip: 'New version',
                          onPressed: () => _addVersion(item),
                          icon: const Icon(Icons.add_box_outlined, size: 20),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () => _delete(item),
                          icon: const Icon(Icons.delete_outline, size: 20),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    final navItems = widget.navItems.isNotEmpty
        ? widget.navItems
        : (widget.routePrefix.startsWith('/founder') ? founderNavItems : adminNavItems);
    final selectedIndex = navItems.indexWhere(
      (i) => _learningSelected.startsWith(i.route) || i.route.contains('/learning'),
    );

    return AdaptiveScaffold(
      title: 'IELTS Question Bank',
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
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text('New bank item'),
      ),
      body: body,
    );
  }
}
