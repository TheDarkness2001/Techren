import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/go_back_icon_button.dart';
import '../../../../domain/entities/learning_cms.dart';
import '../../../../domain/entities/words.dart';
import '../../../providers/learning_cms_provider.dart';
import '../../../providers/listening_provider.dart';
import '../../../providers/words_provider.dart';
import '../widgets/cms_hub_widgets.dart';

/// BBC news listening CMS only. Words / Sentences are managed from their own hubs.
class LearningCmsScreen extends ConsumerStatefulWidget {
  const LearningCmsScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<LearningCmsScreen> createState() => _LearningCmsScreenState();
}

class _LearningCmsScreenState extends ConsumerState<LearningCmsScreen> {
  static const _moduleType = 'listening';

  String? _languageId;
  String? _levelId;

  Future<void> _refreshTree() async {
    ref.invalidate(cmsListeningLanguagesProvider);
    if (_languageId != null) ref.invalidate(cmsListeningLevelsProvider(_languageId!));
  }

  Future<void> _refreshContent() async {
    if (_levelId != null) ref.invalidate(cmsListeningExercisesProvider(_levelId!));
  }

  String? _englishLanguageId(List<LearningLanguage> languages) {
    for (final language in languages) {
      if (language.name.trim().toLowerCase() == 'english') return language.id;
    }
    return languages.isEmpty ? null : languages.first.id;
  }

  Future<void> _showLevelDialog({CmsLevel? level}) async {
    if (_languageId == null) return;
    final nameCtrl = TextEditingController(text: level?.name ?? '');

    final saved = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: level == null ? 'Add level' : 'Rename level',
        icon: Icons.stacked_bar_chart_outlined,
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Level name'),
          autofocus: true,
        ),
        actions: [
          AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context, false)),
          AppDialogActions.confirm(context, label: 'Save', onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (saved != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    try {
      final api = ref.read(homeworkApiProvider);
      if (level == null) {
        final created = await api.createLevel(languageId: _languageId!, name: name, moduleType: _moduleType);
        setState(() => _levelId = created.id);
      } else {
        await api.updateLevel(level.id, name: name);
      }
      await _refreshTree();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Level saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteLevel(CmsLevel level) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete level?',
      message: 'Remove "${level.name}"? Lessons under this level may also be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;

    try {
      await ref.read(homeworkApiProvider).deleteLevel(level.id);
      setState(() {
        if (_levelId == level.id) _levelId = null;
      });
      await _refreshTree();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showListeningDialog({CmsListeningExercise? exercise}) async {
    if (_levelId == null) return;

    var nextOrder = 1;
    try {
      final existing = await ref.read(cmsListeningExercisesProvider(_levelId!).future);
      if (existing.isNotEmpty) {
        nextOrder = existing.map((e) => e.order).reduce((a, b) => a > b ? a : b) + 1;
      }
    } catch (_) {
      nextOrder = 1;
    }
    if (!mounted) return;

    final titleCtrl = TextEditingController(text: exercise?.title ?? '');
    final scriptCtrl = TextEditingController(text: exercise?.script ?? '');
    final orderCtrl = TextEditingController(
      text: exercise != null ? '${exercise.order}' : '$nextOrder',
    );
    PlatformFile? pickedAudio;
    var audioLabel = exercise?.hasAudio == true ? 'Audio attached (pick to replace)' : 'No audio selected';

    final saved = await showAppDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialog(
          title: exercise == null ? 'Add listening exercise' : 'Edit listening exercise',
          icon: Icons.headphones_outlined,
          maxWidth: 520,
          content: SingleChildScrollView(
            child: AppFormColumn(
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
                TextField(
                  controller: scriptCtrl,
                  decoration: const InputDecoration(labelText: 'Script (expected transcript)'),
                  maxLines: 4,
                ),
                TextField(
                  controller: orderCtrl,
                  decoration: InputDecoration(
                    labelText: 'Order',
                    helperText: exercise == null
                        ? 'Auto-filled with next number ($nextOrder). Clear to keep auto.'
                        : null,
                  ),
                  keyboardType: TextInputType.number,
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(type: FileType.audio, withData: false);
                    if (result != null && result.files.isNotEmpty) {
                      pickedAudio = result.files.first;
                      setDialogState(() => audioLabel = pickedAudio!.name);
                    }
                  },
                  icon: const Icon(Icons.audiotrack_outlined),
                  label: Text(audioLabel),
                ),
              ],
            ),
          ),
          actions: [
            AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context, false)),
            AppDialogActions.confirm(context, label: 'Save', onPressed: () => Navigator.pop(context, true)),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    if (exercise == null && pickedAudio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio file is required for new exercises')),
      );
      return;
    }

    try {
      final api = ref.read(listeningApiProvider);
      final parsedOrder = int.tryParse(orderCtrl.text.trim());
      final order = (parsedOrder != null && parsedOrder > 0) ? parsedOrder : nextOrder;
      if (exercise == null) {
        await api.createExercise(
          levelId: _levelId!,
          title: titleCtrl.text.trim(),
          script: scriptCtrl.text.trim(),
          order: order,
          audioPath: pickedAudio?.path,
          audioFileName: pickedAudio?.name,
        );
      } else {
        await api.updateExercise(
          id: exercise.id,
          title: titleCtrl.text.trim(),
          script: scriptCtrl.text.trim(),
          order: order,
          audioPath: pickedAudio?.path,
          audioFileName: pickedAudio?.name,
        );
      }
      await _refreshContent();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exercise saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteListeningExercise(CmsListeningExercise exercise) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete exercise?',
      message: 'Remove "${exercise.title}"?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;

    try {
      await ref.read(listeningApiProvider).deleteExercise(exercise.id);
      await _refreshContent();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final languagesAsync = ref.watch(cmsListeningLanguagesProvider);
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final hasSelection = _levelId != null;

    return AdaptiveScaffold(
      title: 'BBC news',
      selectedIndex: selectedIndex < 0 ? 3 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        GoBackIconButton(
          fallbackRoute: widget.selectedRoute.startsWith('/founder')
              ? '/founder/learning'
              : widget.selectedRoute.startsWith('/teacher')
                  ? '/teacher/profile'
                  : '/admin/learning',
        ),
      ],
      body: languagesAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (languages) {
          final languageId = _englishLanguageId(languages);
          if (languageId == null) {
            return const EmptyState(
              title: 'No English listening language',
              message: 'BBC news expects an English listening language on the server.',
              icon: Icons.headphones_outlined,
            );
          }
          _languageId = languageId;

          final levelsAsync = ref.watch(cmsListeningLevelsProvider(languageId));
          final listeningAsync =
              _levelId == null ? null : ref.watch(cmsListeningExercisesProvider(_levelId!));

          final tree = _ListeningLevelTree(
            levelId: _levelId,
            levelsAsync: levelsAsync,
            onLevelChanged: (id) => setState(() => _levelId = id),
            onAddLevel: () => _showLevelDialog(),
            onEditLevel: (l) => _showLevelDialog(level: l),
            onDeleteLevel: _deleteLevel,
          );

          final editor = !hasSelection
              ? const Center(child: Text('Select BBC news to manage listening exercises'))
              : listeningAsync!.when(
                  loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
                  error: (e, _) => Text(e.toString()),
                  data: (exercises) => _ListeningExerciseEditor(
                    exercises: exercises,
                    onAdd: () => _showListeningDialog(),
                    onEdit: (e) => _showListeningDialog(exercise: e),
                    onDelete: _deleteListeningExercise,
                  ),
                );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 280, child: tree),
                const VerticalDivider(width: 1),
                Expanded(child: editor),
              ],
            );
          }

          if (!hasSelection) {
            return tree;
          }

          return Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _levelId = null),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to levels'),
                ),
              ),
              Expanded(child: editor),
            ],
          );
        },
      ),
    );
  }
}

class _ListeningLevelTree extends StatelessWidget {
  const _ListeningLevelTree({
    required this.levelId,
    required this.levelsAsync,
    required this.onLevelChanged,
    required this.onAddLevel,
    required this.onEditLevel,
    required this.onDeleteLevel,
  });

  final String? levelId;
  final AsyncValue<List<CmsLevel>>? levelsAsync;
  final ValueChanged<String> onLevelChanged;
  final VoidCallback onAddLevel;
  final void Function(CmsLevel level) onEditLevel;
  final void Function(CmsLevel level) onDeleteLevel;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      children: [
        if (levelsAsync == null)
          const SizedBox.shrink()
        else
          levelsAsync!.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
            data: (levels) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CmsTreeSectionHeader(title: 'Levels'),
                ...levels.map(
                  (level) => CmsTreeItem(
                    title: level.name,
                    subtitle: 'BBC news exercises',
                    selected: levelId == level.id,
                    onTap: () => onLevelChanged(level.id),
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'rename', child: Text('Rename')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                      onSelected: (value) {
                        if (value == 'rename') {
                          onEditLevel(level);
                        } else if (value == 'delete') {
                          onDeleteLevel(level);
                        }
                      },
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onAddLevel,
                  icon: const Icon(Icons.add),
                  label: const Text('Add level'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ListeningExerciseEditor extends StatelessWidget {
  const _ListeningExerciseEditor({
    required this.exercises,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CmsListeningExercise> exercises;
  final VoidCallback onAdd;
  final void Function(CmsListeningExercise exercise) onEdit;
  final void Function(CmsListeningExercise exercise) onDelete;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Text('${exercises.length} exercises', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Add exercise')),
            ],
          ),
        ),
        Expanded(
          child: exercises.isEmpty
              ? const EmptyState(
                  title: 'No listening exercises',
                  message: 'Add exercises with title, transcript script, and audio file.',
                  icon: Icons.headphones_outlined,
                )
              : ListView.builder(
                  padding: AppSpacing.listGutter,
                  itemCount: exercises.length,
                  itemBuilder: (_, i) {
                    final exercise = exercises[i];
                    return CmsContentCard(
                      title: exercise.title,
                      subtitle: exercise.script,
                      leadingIcon: exercise.hasAudio ? Icons.audiotrack : Icons.audio_file_outlined,
                      leadingColor: exercise.hasAudio ? semantic.success : semantic.textMuted,
                      onEdit: () => onEdit(exercise),
                      onDelete: () => onDelete(exercise),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
