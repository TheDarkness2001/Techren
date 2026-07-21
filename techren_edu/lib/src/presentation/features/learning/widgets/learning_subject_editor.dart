import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../domain/entities/learning_subject.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../providers/identity_provider.dart';
import '../../../providers/learning_provider.dart';
import '../../../providers/staff_branch_provider.dart';
import '../widgets/learning_subject_widgets.dart';

const _colorPresets = [
  '#2563EB',
  '#0D9488',
  '#7C3AED',
  '#DB2777',
  '#EA580C',
  '#0891B2',
  '#4F46E5',
  '#059669',
  '#CA8A04',
  '#DC2626',
];

const _iconPresets = [
  'translate',
  'menu_book',
  'code',
  'computer',
  'functions',
  'science',
  'eco',
  'school',
];

Future<bool?> showLearningSubjectEditor({
  required BuildContext context,
  required WidgetRef ref,
  LearningSubjectCard? existing,
}) {
  return showAppDialog<bool>(
    context: context,
    builder: (context) => _LearningSubjectEditorDialog(existing: existing),
  );
}

Future<bool?> showLearningModulesEditor({
  required BuildContext context,
  required WidgetRef ref,
  required LearningSubjectDashboard subject,
}) {
  return showAppDialog<bool>(
    context: context,
    builder: (context) => _LearningModulesEditorDialog(subject: subject),
  );
}

class _LearningSubjectEditorDialog extends ConsumerStatefulWidget {
  const _LearningSubjectEditorDialog({this.existing});

  final LearningSubjectCard? existing;

  @override
  ConsumerState<_LearningSubjectEditorDialog> createState() => _LearningSubjectEditorDialogState();
}

class _LearningSubjectEditorDialogState extends ConsumerState<_LearningSubjectEditorDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _descCtrl;
  late String _color;
  late String _icon;
  String _profile = 'language';
  String? _branchId;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _color = e?.color ?? _colorPresets.first;
    _icon = e?.icon ?? 'menu_book';
    _branchId = ref.read(staffBranchFilterProvider.notifier).activeBranchId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final api = ref.read(learningApiProvider);
      if (_isEdit) {
        await api.updateSubject(
          id: widget.existing!.id,
          name: name,
          code: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          color: _color,
          icon: _icon,
        );
      } else {
        var branchId = _branchId;
        if (branchId == null || branchId.isEmpty) {
          final branches = await ref.read(branchesProvider(const PageMeta(limit: 100)).future);
          branchId = branches.items.isNotEmpty ? branches.items.first.id : null;
        }
        if (branchId == null) {
          messenger.showSnackBar(const SnackBar(content: Text('Create a branch first')));
          return;
        }
        await api.createSubject(
          name: name,
          code: _codeCtrl.text.trim().isEmpty ? null : _codeCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          color: _color,
          icon: _icon,
          branchId: branchId,
          profile: _profile,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchesProvider(const PageMeta(limit: 100)));

    return AppDialog(
      title: _isEdit ? 'Edit Subject' : 'Add Subject',
      icon: Icons.auto_stories_outlined,
      maxWidth: 560,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFormColumn(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Subject name *'),
                  textCapitalization: TextCapitalization.words,
                ),
                TextField(
                  controller: _codeCtrl,
                  decoration: const InputDecoration(labelText: 'Code (optional)'),
                ),
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                if (!_isEdit) ...[
                  DropdownButtonFormField<String>(
                    value: _profile,
                    decoration: const InputDecoration(labelText: 'Module profile'),
                    items: const [
                      DropdownMenuItem(value: 'language', child: Text('Language (Words, Sentences…)')),
                      DropdownMenuItem(value: 'programming', child: Text('Programming')),
                      DropdownMenuItem(value: 'stem', child: Text('STEM / Math / Science')),
                    ],
                    onChanged: (v) => setState(() => _profile = v ?? 'language'),
                  ),
                  branchesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(e.toString()),
                    data: (result) {
                      if (result.items.isEmpty) {
                        return const Text('No branches found');
                      }
                      _branchId ??= result.items.first.id;
                      return DropdownButtonFormField<String>(
                        value: result.items.any((b) => b.id == _branchId) ? _branchId : result.items.first.id,
                        decoration: const InputDecoration(labelText: 'Branch'),
                        items: [
                          for (final b in result.items)
                            DropdownMenuItem(value: b.id, child: Text(b.name)),
                        ],
                        onChanged: (v) => setState(() => _branchId = v),
                      );
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Color', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hex in _colorPresets)
                  InkWell(
                    onTap: () => setState(() => _color = hex),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: parseSubjectColor(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == hex ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Icon', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final icon in _iconPresets)
                  ChoiceChip(
                    selected: _icon == icon,
                    label: Icon(iconForLearningKey(icon), size: 18),
                    onSelected: (_) => setState(() => _icon = icon),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context)),
        AppDialogActions.confirm(
          context,
          label: _isEdit ? 'Save' : 'Create',
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

class _LearningModulesEditorDialog extends ConsumerStatefulWidget {
  const _LearningModulesEditorDialog({required this.subject});

  final LearningSubjectDashboard subject;

  @override
  ConsumerState<_LearningModulesEditorDialog> createState() => _LearningModulesEditorDialogState();
}

class _LearningModulesEditorDialogState extends ConsumerState<_LearningModulesEditorDialog> {
  late List<LearningModuleDef> _modules;
  bool _saving = false;
  final _customNameCtrl = TextEditingController();
  String _customCategory = 'learning';
  String _customAudience = 'all';
  String _customIcon = 'menu_book';

  static const _catalog = <LearningModuleDef>[
    LearningModuleDef(key: 'words', label: 'Words', category: 'learning', icon: 'spellcheck'),
    LearningModuleDef(key: 'sentences', label: 'Sentences', category: 'learning', icon: 'format_quote'),
    LearningModuleDef(key: 'listening', label: 'Listening', category: 'learning', icon: 'headphones'),
    LearningModuleDef(key: 'video', label: 'Video Lessons', category: 'learning', icon: 'play_circle'),
    LearningModuleDef(key: 'grammar', label: 'Grammar', category: 'learning', icon: 'menu_book'),
    LearningModuleDef(key: 'flashcards', label: 'Flashcards', category: 'learning', icon: 'style'),
    LearningModuleDef(key: 'reading', label: 'Reading', category: 'learning', icon: 'menu_book'),
    LearningModuleDef(key: 'speaking', label: 'Speaking', category: 'learning', icon: 'record_voice_over'),
    LearningModuleDef(key: 'writing', label: 'Writing', category: 'learning', icon: 'edit_note'),
    LearningModuleDef(key: 'dialogues', label: 'Dialogues', category: 'learning', icon: 'forum'),
    LearningModuleDef(key: 'lessons', label: 'Lessons', category: 'learning', icon: 'school'),
    LearningModuleDef(key: 'projects', label: 'Projects', category: 'learning', icon: 'folder_special'),
    LearningModuleDef(key: 'exercises', label: 'Exercises', category: 'learning', icon: 'code'),
    LearningModuleDef(key: 'challenges', label: 'Challenges', category: 'learning', icon: 'bolt'),
    LearningModuleDef(key: 'practice', label: 'Practice', category: 'learning', icon: 'calculate'),
    LearningModuleDef(key: 'examples', label: 'Worked Examples', category: 'learning', icon: 'lightbulb'),
    LearningModuleDef(key: 'quiz', label: 'Quiz', category: 'assessment', icon: 'quiz'),
    LearningModuleDef(key: 'exam', label: 'Exam', category: 'assessment', icon: 'emoji_events'),
    LearningModuleDef(key: 'cms', label: 'Learning CMS', category: 'management', icon: 'edit_note', audience: 'staff'),
    LearningModuleDef(key: 'import', label: 'Content Import', category: 'management', icon: 'upload_file', audience: 'staff'),
    LearningModuleDef(key: 'progress', label: 'Student Progress', category: 'statistics', icon: 'insights', audience: 'staff'),
  ];

  static const _iconChoices = [
    'menu_book',
    'spellcheck',
    'format_quote',
    'headphones',
    'play_circle',
    'style',
    'school',
    'code',
    'quiz',
    'emoji_events',
    'edit_note',
    'insights',
    'science',
    'translate',
  ];

  Set<String> get _catalogKeys => _catalog.map((m) => m.key).toSet();

  List<LearningModuleDef> get _customModules =>
      _modules.where((m) => !_catalogKeys.contains(m.key)).toList();

  @override
  void initState() {
    super.initState();
    _modules = List.of(widget.subject.allModules.isNotEmpty
        ? widget.subject.allModules
        : widget.subject.modules);
    if (_modules.isEmpty) {
      _modules = List.of(_catalog.take(6));
    }
  }

  @override
  void dispose() {
    _customNameCtrl.dispose();
    super.dispose();
  }

  String _slugify(String label) {
    final slug = label
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (slug.isEmpty) return 'module_${DateTime.now().millisecondsSinceEpoch}';
    var key = slug;
    var i = 2;
    while (_modules.any((m) => m.key == key) || _catalogKeys.contains(key) && !_modules.any((m) => m.key == key)) {
      // Allow picking an existing catalog key via slug only if not already careful;
      // for custom, ensure uniqueness among modules.
      if (!_modules.any((m) => m.key == key)) break;
      key = '${slug}_$i';
      i++;
    }
    while (_modules.any((m) => m.key == key)) {
      key = '${slug}_$i';
      i++;
    }
    return key;
  }

  void _toggleCatalog(LearningModuleDef mod) {
    final exists = _modules.any((m) => m.key == mod.key);
    setState(() {
      if (exists) {
        _modules = _modules.where((m) => m.key != mod.key).toList();
      } else {
        _modules = [..._modules, mod];
      }
    });
  }

  void _addCustomModule() {
    final label = _customNameCtrl.text.trim();
    if (label.isEmpty) return;

    // If label matches a catalog module, just enable that one.
    final catalogMatch = _catalog.where((m) => m.label.toLowerCase() == label.toLowerCase()).firstOrNull;
    if (catalogMatch != null) {
      if (!_modules.any((m) => m.key == catalogMatch.key)) {
        setState(() {
          _modules = [..._modules, catalogMatch];
          _customNameCtrl.clear();
        });
      }
      return;
    }

    final key = _slugify(label);
    setState(() {
      _modules = [
        ..._modules,
        LearningModuleDef(
          key: key,
          label: label,
          category: _customCategory,
          icon: _customIcon,
          audience: _customAudience,
        ),
      ];
      _customNameCtrl.clear();
    });
  }

  void _removeModule(String key) {
    setState(() => _modules = _modules.where((m) => m.key != key).toList());
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(learningApiProvider).updateSubject(
            id: widget.subject.id,
            modules: _modules
                .map(
                  (m) => {
                    'key': m.key,
                    'label': m.label,
                    'category': m.category,
                    'icon': m.icon,
                    'audience': m.audience,
                    'enabled': true,
                  },
                )
                .toList(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedKeys = _modules.map((m) => m.key).toSet();
    final scheme = Theme.of(context).colorScheme;

    return AppDialog(
      title: 'Edit Modules — ${widget.subject.name}',
      icon: Icons.widgets_outlined,
      maxWidth: 640,
      content: SizedBox(
        width: 600,
        height: 480,
        child: ListView(
          children: [
            Text(
              'Turn presets on/off, or add a custom module if it isn’t in the list.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppFormColumn(
                children: [
                  Text('Add custom module', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  TextField(
                    controller: _customNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Module name',
                      hintText: 'e.g. Pronunciation, Debates, Dictionaries',
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _addCustomModule(),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _customCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Category', isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'learning', child: Text('Learning')),
                            DropdownMenuItem(value: 'assessment', child: Text('Assessment')),
                            DropdownMenuItem(value: 'management', child: Text('Content')),
                            DropdownMenuItem(value: 'statistics', child: Text('Statistics')),
                          ],
                          onChanged: (v) => setState(() => _customCategory = v ?? 'learning'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _customAudience,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Who sees it', isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Everyone')),
                            DropdownMenuItem(value: 'staff', child: Text('Staff only')),
                            DropdownMenuItem(value: 'student', child: Text('Students only')),
                          ],
                          onChanged: (v) => setState(() => _customAudience = v ?? 'all'),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Icon', style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final icon in _iconChoices)
                            ChoiceChip(
                              selected: _customIcon == icon,
                              label: Icon(iconForLearningKey(icon), size: 16),
                              onSelected: (_) => setState(() => _customIcon = icon),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _addCustomModule,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add module'),
                    ),
                  ),
                ],
              ),
            ),
            if (_customModules.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Custom modules', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              for (final mod in _customModules)
                ListTile(
                  dense: true,
                  leading: Icon(iconForLearningKey(mod.icon)),
                  title: Text(mod.label),
                  subtitle: Text('${mod.category} · ${mod.audience} · ${mod.key}'),
                  trailing: IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeModule(mod.key),
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text('Preset modules', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            for (final mod in _catalog)
              CheckboxListTile(
                value: selectedKeys.contains(mod.key),
                onChanged: (_) => _toggleCatalog(mod),
                secondary: Icon(iconForLearningKey(mod.icon)),
                title: Text(mod.label),
                subtitle: Text('${mod.category} · ${mod.audience}'),
                dense: true,
              ),
          ],
        ),
      ),
      actions: [
        AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context)),
        AppDialogActions.confirm(
          context,
          label: 'Save modules',
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
