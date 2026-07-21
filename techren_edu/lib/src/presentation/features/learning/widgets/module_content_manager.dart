import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/learning_cms.dart';
import '../../../../domain/entities/upload.dart';
import '../../../../domain/entities/words.dart';
import '../../../providers/learning_cms_provider.dart';
import '../../../providers/sentences_provider.dart';
import '../../../providers/upload_provider.dart';
import '../../../providers/words_provider.dart';

String _mediaAbsoluteUrl(String path) {
  if (path.startsWith('http')) return path;
  final base = Uri.parse(ApiConstants.baseUrl);
  final origin = '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
  return '$origin$path';
}

enum ContentManagerModule { words, sentences }

enum _Step { languages, levels, lessons, pairs }

/// In-hub Language → Level → Lesson → pairs CRUD for Words / Sentences.
class ModuleContentManager extends ConsumerStatefulWidget {
  const ModuleContentManager({
    super.key,
    required this.module,
  });

  final ContentManagerModule module;

  @override
  ConsumerState<ModuleContentManager> createState() => _ModuleContentManagerState();
}

class _ModuleContentManagerState extends ConsumerState<ModuleContentManager> {
  _Step _step = _Step.languages;
  String? _languageId;
  String? _languageName;
  String? _levelId;
  String? _levelName;
  String? _lessonId;
  String? _lessonName;

  String get _moduleType => widget.module == ContentManagerModule.sentences ? 'sentences' : 'words';
  String get _pairLabel => widget.module == ContentManagerModule.sentences ? 'sentence' : 'word';
  String get _pairLabelPlural => widget.module == ContentManagerModule.sentences ? 'Sentences' : 'Words';

  void _goLanguages() {
    setState(() {
      _step = _Step.languages;
      _languageId = null;
      _languageName = null;
      _levelId = null;
      _levelName = null;
      _lessonId = null;
      _lessonName = null;
    });
  }

  void _goLevels({required String languageId, required String languageName}) {
    setState(() {
      _step = _Step.levels;
      _languageId = languageId;
      _languageName = languageName;
      _levelId = null;
      _levelName = null;
      _lessonId = null;
      _lessonName = null;
    });
  }

  void _goLessons({required String levelId, required String levelName}) {
    setState(() {
      _step = _Step.lessons;
      _levelId = levelId;
      _levelName = levelName;
      _lessonId = null;
      _lessonName = null;
    });
  }

  void _goPairs({required String lessonId, required String lessonName}) {
    setState(() {
      _step = _Step.pairs;
      _lessonId = lessonId;
      _lessonName = lessonName;
    });
  }

  Future<void> _refreshTree() async {
    if (widget.module == ContentManagerModule.sentences) {
      ref.invalidate(cmsSentencesLanguagesProvider);
      if (_languageId != null) ref.invalidate(cmsSentencesLevelsProvider(_languageId!));
      if (_levelId != null) ref.invalidate(cmsSentencesLessonsProvider(_levelId!));
      if (_lessonId != null) ref.invalidate(cmsLessonSentencesProvider(_lessonId!));
    } else {
      ref.invalidate(cmsLanguagesProvider);
      if (_languageId != null) ref.invalidate(cmsLevelsProvider(_languageId!));
      if (_levelId != null) ref.invalidate(cmsLessonsProvider(_levelId!));
      if (_lessonId != null) ref.invalidate(cmsLessonWordsProvider(_lessonId!));
    }
  }

  Future<String?> _promptName({
    required String title,
    String? initial,
    String label = 'Name',
  }) async {
    final ctrl = TextEditingController(text: initial ?? '');
    final saved = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: title,
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context, false)),
          AppDialogActions.confirm(context, label: 'Save', onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (saved != true) return null;
    final value = ctrl.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _showPairDialog({
    String? id,
    String? english,
    String? uzbek,
    String? task,
    String? imageUrl,
  }) async {
    if (_lessonId == null) return;
    final englishCtrl = TextEditingController(text: english ?? '');
    final uzbekCtrl = TextEditingController(text: uzbek ?? '');
    final taskCtrl = TextEditingController(text: task ?? '');
    var currentImageUrl = imageUrl?.trim() ?? '';
    var busy = false;

    final saved = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialog(
          title: id == null ? 'Add $_pairLabel' : 'Edit $_pairLabel',
          content: AppFormColumn(
            children: [
              TextField(
                controller: englishCtrl,
                decoration: const InputDecoration(labelText: 'English'),
                maxLines: 2,
                autofocus: true,
              ),
              TextField(
                controller: uzbekCtrl,
                decoration: const InputDecoration(labelText: 'Uzbek'),
                maxLines: 2,
              ),
              if (widget.module == ContentManagerModule.sentences) ...[
                TextField(
                  controller: taskCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Task (optional)',
                    hintText: 'e.g. Task 1: Translate the sentences',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.xs),
                if (currentImageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _mediaAbsoluteUrl(currentImageUrl),
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              final picked = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                                withData: true,
                              );
                              if (picked == null) return;
                              final file = picked.files.single;
                              if (file.path == null && file.bytes == null) return;
                              setDialogState(() => busy = true);
                              try {
                                final uploaded = await ref.read(uploadApiProvider).uploadImage(
                                      filePath: file.path,
                                      bytes: file.bytes,
                                      fileName: file.name,
                                    );
                                setDialogState(() => currentImageUrl = uploaded.url);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              } finally {
                                setDialogState(() => busy = false);
                              }
                            },
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: Text(currentImageUrl.isEmpty ? 'Add image' : 'Change image'),
                    ),
                    if (currentImageUrl.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      TextButton(
                        onPressed: busy ? null : () => setDialogState(() => currentImageUrl = ''),
                        child: const Text('Remove'),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
          actions: [
            AppDialogActions.cancel(dialogContext, onPressed: () => Navigator.pop(dialogContext, false)),
            AppDialogActions.confirm(
              dialogContext,
              label: 'Save',
              onPressed: busy ? null : () => Navigator.pop(dialogContext, true),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    final en = englishCtrl.text.trim();
    final uz = uzbekCtrl.text.trim();
    if (en.isEmpty || uz.isEmpty) return;

    try {
      if (widget.module == ContentManagerModule.sentences) {
        final api = ref.read(sentencesApiProvider);
        if (id == null) {
          await api.addSentence(
            lessonId: _lessonId!,
            english: en,
            uzbek: uz,
            task: taskCtrl.text.trim(),
            imageUrl: currentImageUrl,
          );
        } else {
          await api.updateSentence(
            id,
            english: en,
            uzbek: uz,
            task: taskCtrl.text.trim(),
            imageUrl: currentImageUrl,
          );
        }
      } else {
        final api = ref.read(homeworkApiProvider);
        if (id == null) {
          await api.addWord(lessonId: _lessonId!, english: en, uzbek: uz);
        } else {
          await api.updateWord(id, english: en, uzbek: uz);
        }
      }
      await _refreshTree();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_pairLabel[0].toUpperCase()}${_pairLabel.substring(1)} saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _importWordFile() async {
    if (_lessonId == null) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['docx', 'txt'],
      withData: true,
    );
    if (picked == null || !mounted) return;
    final file = picked.files.single;
    if (file.path == null && file.bytes == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    ParseImportResult? parsed;
    Object? error;
    try {
      parsed = await ref.read(uploadApiProvider).parseDocx(
            filePath: file.path,
            bytes: file.bytes,
            fileName: file.name,
          );
    } catch (e) {
      error = e;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (error != null || parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      return;
    }
    if (parsed.pairs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            parsed.message ??
                'No English – Uzbek pairs found. Use lines like: You are ready. - Sen tayyorsan.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: 'Import ${parsed!.pairs.length} $_pairLabelPlural',
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                [
                  if (parsed.tasks.isNotEmpty) '${parsed.tasks.length} task line(s)',
                  if (parsed.images.isNotEmpty) '${parsed.images.length} image(s)',
                  'Previewing first ${parsed.pairs.length.clamp(0, 6)} pair(s)',
                ].where((s) => s.isNotEmpty).join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final pair in parsed.pairs.take(6))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: pair.imageUrl == null || pair.imageUrl!.isEmpty
                            ? null
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  _mediaAbsoluteUrl(pair.imageUrl!),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                        title: Text(pair.english, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          [
                            pair.uzbek,
                            if (pair.task != null && pair.task!.isNotEmpty) pair.task!,
                          ].join('\n'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (parsed.pairs.length > 6)
                      Text('…and ${parsed.pairs.length - 6} more', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context, false)),
          AppDialogActions.confirm(context, label: 'Import', onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final api = ref.read(uploadApiProvider);
      final result = widget.module == ContentManagerModule.sentences
          ? await api.bulkImportSentences(lessonId: _lessonId!, pairs: parsed.pairs)
          : await api.bulkImportWords(lessonId: _lessonId!, pairs: parsed.pairs);
      await _refreshTree();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${result.created}, skipped ${result.skipped}')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _confirmDelete(String title, String message, Future<void> Function() action) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: title,
      message: message,
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;
    try {
      await action();
      await _refreshTree();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languagesAsync = widget.module == ContentManagerModule.sentences
        ? ref.watch(cmsSentencesLanguagesProvider)
        : ref.watch(cmsLanguagesProvider);

    return languagesAsync.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.dashboard),
      error: (e, _) => Text('$e'),
      data: (languages) {
        switch (_step) {
          case _Step.languages:
            return _LanguagesStep(
              languages: languages,
              onOpen: (lang) => _goLevels(languageId: lang.id, languageName: lang.name),
              onAdd: () async {
                final name = await _promptName(title: 'Add language', label: 'Language name');
                if (name == null) return;
                try {
                  final created = await ref.read(homeworkApiProvider).createLanguage(
                        name: name,
                        moduleType: _moduleType,
                      );
                  await _refreshTree();
                  if (mounted) {
                    _goLevels(languageId: created.id, languageName: created.name);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
              onRename: (lang) async {
                final name = await _promptName(title: 'Rename language', initial: lang.name, label: 'Language name');
                if (name == null) return;
                try {
                  await ref.read(homeworkApiProvider).updateLanguage(lang.id, name: name);
                  await _refreshTree();
                  if (_languageId == lang.id) setState(() => _languageName = name);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
              onDelete: (lang) => _confirmDelete(
                'Delete language?',
                'Remove "${lang.name}" and its content?',
                () async {
                  await ref.read(homeworkApiProvider).deleteLanguage(lang.id);
                  if (_languageId == lang.id) _goLanguages();
                },
              ),
            );
          case _Step.levels:
            final levelsAsync = widget.module == ContentManagerModule.sentences
                ? ref.watch(cmsSentencesLevelsProvider(_languageId!))
                : ref.watch(cmsLevelsProvider(_languageId!));
            return levelsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (levels) => _LevelsStep(
                languageName: _languageName ?? 'Language',
                levels: levels,
                onBack: _goLanguages,
                onOpen: (level) => _goLessons(levelId: level.id, levelName: level.name),
                onAdd: () async {
                  final name = await _promptName(title: 'Add level', label: 'Level name');
                  if (name == null) return;
                  try {
                    final created = await ref.read(homeworkApiProvider).createLevel(
                          languageId: _languageId!,
                          name: name,
                          moduleType: _moduleType,
                        );
                    await _refreshTree();
                    if (mounted) {
                      _goLessons(levelId: created.id, levelName: created.name);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
                onRename: (level) async {
                  final name = await _promptName(title: 'Rename level', initial: level.name, label: 'Level name');
                  if (name == null) return;
                  try {
                    await ref.read(homeworkApiProvider).updateLevel(level.id, name: name);
                    await _refreshTree();
                    if (_levelId == level.id) setState(() => _levelName = name);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
                onDelete: (level) => _confirmDelete(
                  'Delete level?',
                  'Remove "${level.name}" and its lessons?',
                  () async {
                    await ref.read(homeworkApiProvider).deleteLevel(level.id);
                    if (_levelId == level.id) {
                      _goLevels(languageId: _languageId!, languageName: _languageName!);
                    }
                  },
                ),
              ),
            );
          case _Step.lessons:
            final lessonsAsync = widget.module == ContentManagerModule.sentences
                ? ref.watch(cmsSentencesLessonsProvider(_levelId!))
                : ref.watch(cmsLessonsProvider(_levelId!));
            return lessonsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (lessons) => _LessonsStep(
                levelName: _levelName ?? 'Level',
                lessons: lessons,
                onBack: () => _goLevels(languageId: _languageId!, languageName: _languageName!),
                onOpen: (lesson) => _goPairs(lessonId: lesson.id, lessonName: lesson.name),
                onAdd: () async {
                  final name = await _promptName(title: 'Add lesson', label: 'Lesson name');
                  if (name == null) return;
                  try {
                    final created = await ref.read(homeworkApiProvider).createLesson(
                          levelId: _levelId!,
                          name: name,
                          type: _moduleType,
                          order: lessons.length + 1,
                        );
                    await _refreshTree();
                    if (mounted) {
                      _goPairs(lessonId: created.id, lessonName: created.name);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
                onRename: (lesson) async {
                  final name = await _promptName(title: 'Rename lesson', initial: lesson.name, label: 'Lesson name');
                  if (name == null) return;
                  try {
                    await ref.read(homeworkApiProvider).updateLesson(lesson.id, name: name);
                    await _refreshTree();
                    if (_lessonId == lesson.id) setState(() => _lessonName = name);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                    }
                  }
                },
                onDelete: (lesson) => _confirmDelete(
                  'Delete lesson?',
                  'Remove "${lesson.name}" and its $_pairLabelPlural?',
                  () async {
                    await ref.read(homeworkApiProvider).deleteLesson(lesson.id);
                    if (_lessonId == lesson.id) {
                      _goLessons(levelId: _levelId!, levelName: _levelName!);
                    }
                  },
                ),
              ),
            );
          case _Step.pairs:
            if (widget.module == ContentManagerModule.sentences) {
              final pairsAsync = ref.watch(cmsLessonSentencesProvider(_lessonId!));
              return pairsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (pairs) => _PairsStep(
                  lessonName: _lessonName ?? 'Lesson',
                  pairLabelPlural: _pairLabelPlural,
                  items: [
                    for (final p in pairs)
                      _PairItem(
                        id: p.id,
                        english: p.english,
                        uzbek: p.uzbek,
                        task: p.task,
                        imageUrl: p.imageUrl,
                      ),
                  ],
                  onBack: () => _goLessons(levelId: _levelId!, levelName: _levelName!),
                  onAdd: () => _showPairDialog(),
                  onImport: _importWordFile,
                  onEdit: (item) => _showPairDialog(
                    id: item.id,
                    english: item.english,
                    uzbek: item.uzbek,
                    task: item.task,
                    imageUrl: item.imageUrl,
                  ),
                  onDelete: (item) => _confirmDelete(
                    'Delete $_pairLabel?',
                    'Remove "${item.english}"?',
                    () => ref.read(sentencesApiProvider).deleteSentence(item.id),
                  ),
                ),
              );
            }
            final wordsAsync = ref.watch(cmsLessonWordsProvider(_lessonId!));
            return wordsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (pairs) => _PairsStep(
                lessonName: _lessonName ?? 'Lesson',
                pairLabelPlural: _pairLabelPlural,
                items: [
                  for (final p in pairs)
                    _PairItem(id: p.id, english: p.english, uzbek: p.uzbek),
                ],
                onBack: () => _goLessons(levelId: _levelId!, levelName: _levelName!),
                onAdd: () => _showPairDialog(),
                onImport: _importWordFile,
                onEdit: (item) => _showPairDialog(id: item.id, english: item.english, uzbek: item.uzbek),
                onDelete: (item) => _confirmDelete(
                  'Delete $_pairLabel?',
                  'Remove "${item.english}"?',
                  () => ref.read(homeworkApiProvider).deleteWord(item.id),
                ),
              ),
            );
        }
      },
    );
  }
}

class _PairItem {
  const _PairItem({
    required this.id,
    required this.english,
    required this.uzbek,
    this.task = '',
    this.imageUrl = '',
  });
  final String id;
  final String english;
  final String uzbek;
  final String task;
  final String imageUrl;
}

class _BackRow extends StatelessWidget {
  const _BackRow({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        if (secondaryLabel != null && onSecondary != null) ...[
          OutlinedButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
          const SizedBox(width: AppSpacing.xs),
        ],
        FilledButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    required this.title,
    this.subtitle,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        onTap: onOpen,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle == null ? null : Text(subtitle!, style: TextStyle(color: muted)),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'rename') onRename();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'rename', child: Text('Rename')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _LanguagesStep extends StatelessWidget {
  const _LanguagesStep({
    required this.languages,
    required this.onOpen,
    required this.onAdd,
    required this.onRename,
    required this.onDelete,
  });

  final List<LearningLanguage> languages;
  final ValueChanged<LearningLanguage> onOpen;
  final VoidCallback onAdd;
  final ValueChanged<LearningLanguage> onRename;
  final ValueChanged<LearningLanguage> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'Languages', actionLabel: 'Add language', onAction: onAdd),
        const SizedBox(height: AppSpacing.md),
        if (languages.isEmpty)
          const EmptyState(
            title: 'No languages yet',
            message: 'Add a language, then create levels and lessons for content.',
            icon: Icons.translate_outlined,
          )
        else
          for (final language in languages)
            _ManageTile(
              title: language.name,
              onOpen: () => onOpen(language),
              onRename: () => onRename(language),
              onDelete: () => onDelete(language),
            ),
      ],
    );
  }
}

class _LevelsStep extends StatelessWidget {
  const _LevelsStep({
    required this.languageName,
    required this.levels,
    required this.onBack,
    required this.onOpen,
    required this.onAdd,
    required this.onRename,
    required this.onDelete,
  });

  final String languageName;
  final List<CmsLevel> levels;
  final VoidCallback onBack;
  final ValueChanged<CmsLevel> onOpen;
  final VoidCallback onAdd;
  final ValueChanged<CmsLevel> onRename;
  final ValueChanged<CmsLevel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackRow(label: 'Back to Languages', onPressed: onBack),
        const SizedBox(height: AppSpacing.sm),
        _SectionHeader(title: '$languageName · Levels', actionLabel: 'Add level', onAction: onAdd),
        const SizedBox(height: AppSpacing.md),
        if (levels.isEmpty)
          const EmptyState(
            title: 'No levels yet',
            message: 'Add a level (e.g. Beginner), then create lessons under it.',
            icon: Icons.layers_outlined,
          )
        else
          for (final level in levels)
            _ManageTile(
              title: level.name,
              onOpen: () => onOpen(level),
              onRename: () => onRename(level),
              onDelete: () => onDelete(level),
            ),
      ],
    );
  }
}

class _LessonsStep extends StatelessWidget {
  const _LessonsStep({
    required this.levelName,
    required this.lessons,
    required this.onBack,
    required this.onOpen,
    required this.onAdd,
    required this.onRename,
    required this.onDelete,
  });

  final String levelName;
  final List<CmsLesson> lessons;
  final VoidCallback onBack;
  final ValueChanged<CmsLesson> onOpen;
  final VoidCallback onAdd;
  final ValueChanged<CmsLesson> onRename;
  final ValueChanged<CmsLesson> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackRow(label: 'Back to Levels', onPressed: onBack),
        const SizedBox(height: AppSpacing.sm),
        _SectionHeader(title: '$levelName · Lessons', actionLabel: 'Add lesson', onAction: onAdd),
        const SizedBox(height: AppSpacing.md),
        if (lessons.isEmpty)
          const EmptyState(
            title: 'No lessons yet',
            message: 'Add a lesson, then open it to manage English / Uzbek pairs.',
            icon: Icons.menu_book_outlined,
          )
        else
          for (final lesson in lessons)
            _ManageTile(
              title: lesson.name,
              subtitle: 'Open to manage content',
              onOpen: () => onOpen(lesson),
              onRename: () => onRename(lesson),
              onDelete: () => onDelete(lesson),
            ),
      ],
    );
  }
}

class _PairsStep extends StatelessWidget {
  const _PairsStep({
    required this.lessonName,
    required this.pairLabelPlural,
    required this.items,
    required this.onBack,
    required this.onAdd,
    required this.onImport,
    required this.onEdit,
    required this.onDelete,
  });

  final String lessonName;
  final String pairLabelPlural;
  final List<_PairItem> items;
  final VoidCallback onBack;
  final VoidCallback onAdd;
  final VoidCallback onImport;
  final ValueChanged<_PairItem> onEdit;
  final ValueChanged<_PairItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackRow(label: 'Back to Lessons', onPressed: onBack),
        const SizedBox(height: AppSpacing.sm),
        _SectionHeader(
          title: '$lessonName · $pairLabelPlural',
          actionLabel: 'Add',
          onAction: onAdd,
          secondaryLabel: 'Import',
          onSecondary: onImport,
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          EmptyState(
            title: 'No $pairLabelPlural yet',
            message: 'Add English / Uzbek pairs, or import a Word (.docx) file with pairs, tasks, and images.',
            icon: Icons.translate_outlined,
          )
        else
          for (final item in items)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: item.imageUrl.isEmpty
                    ? null
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _mediaAbsoluteUrl(item.imageUrl),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                title: Text(item.english, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  [
                    item.uzbek,
                    if (item.task.isNotEmpty) item.task,
                  ].join('\n'),
                  style: TextStyle(color: muted),
                ),
                isThreeLine: item.task.isNotEmpty,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(onPressed: () => onEdit(item), child: const Text('Edit')),
                    TextButton(
                      onPressed: () => onDelete(item),
                      style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
