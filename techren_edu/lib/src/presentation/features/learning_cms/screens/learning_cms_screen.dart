import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/go_back_icon_button.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/learning_cms.dart';
import '../../../../domain/entities/words.dart';
import '../../../providers/learning_cms_provider.dart';
import '../../../providers/listening_provider.dart';
import '../../../providers/sentences_provider.dart';
import '../../../providers/words_provider.dart';
import '../widgets/cms_hub_widgets.dart';

enum CmsModule { words, sentences, listening }

class LearningCmsScreen extends ConsumerStatefulWidget {
  const LearningCmsScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
    required this.importRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;
  final String importRoute;

  @override
  ConsumerState<LearningCmsScreen> createState() => _LearningCmsScreenState();
}

class _LearningCmsScreenState extends ConsumerState<LearningCmsScreen> with SingleTickerProviderStateMixin {
  late final TabController _moduleTabs;
  String? _languageId;
  String? _levelId;
  String? _lessonId;

  @override
  void initState() {
    super.initState();
    _moduleTabs = TabController(length: 3, vsync: this);
    _moduleTabs.addListener(_onModuleChanged);
  }

  void _onModuleChanged() {
    if (!_moduleTabs.indexIsChanging) return;
    setState(() {
      _languageId = null;
      _levelId = null;
      _lessonId = null;
    });
  }

  @override
  void dispose() {
    _moduleTabs.removeListener(_onModuleChanged);
    _moduleTabs.dispose();
    super.dispose();
  }

  CmsModule get _module {
    switch (_moduleTabs.index) {
      case 1:
        return CmsModule.sentences;
      case 2:
        return CmsModule.listening;
      default:
        return CmsModule.words;
    }
  }

  String get _moduleType {
    switch (_module) {
      case CmsModule.sentences:
        return 'sentences';
      case CmsModule.listening:
        return 'listening';
      default:
        return 'words';
    }
  }

  String get _lessonType => _moduleType == 'sentences' ? 'sentences' : 'words';

  Future<void> _refreshTree() async {
    final module = _module;
    if (module == CmsModule.listening) {
      ref.invalidate(cmsListeningLanguagesProvider);
      if (_languageId != null) ref.invalidate(cmsListeningLevelsProvider(_languageId!));
      return;
    }
    if (module == CmsModule.words) {
      ref.invalidate(cmsLanguagesProvider);
      if (_languageId != null) ref.invalidate(cmsLevelsProvider(_languageId!));
      if (_levelId != null) ref.invalidate(cmsLessonsProvider(_levelId!));
    } else {
      ref.invalidate(cmsSentencesLanguagesProvider);
      if (_languageId != null) ref.invalidate(cmsSentencesLevelsProvider(_languageId!));
      if (_levelId != null) ref.invalidate(cmsSentencesLessonsProvider(_levelId!));
    }
  }

  Future<void> _showLanguageDialog({LearningLanguage? language}) async {
    final nameCtrl = TextEditingController(text: language?.name ?? '');

    final saved = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: language == null ? 'Add language' : 'Rename language',
        icon: Icons.language_outlined,
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Language name'),
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
      if (language == null) {
        final created = await api.createLanguage(name: name, moduleType: _moduleType);
        setState(() {
          _languageId = created.id;
          _levelId = null;
          _lessonId = null;
        });
      } else {
        await api.updateLanguage(language.id, name: name);
      }
      await _refreshTree();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Language saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteLanguage(LearningLanguage language) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete language?',
      message: 'Remove "${language.name}" and its levels?',
      confirmLabel: 'Delete',
      destructive: true,
      icon: Icons.delete_outline,
    );
    if (confirmed != true) return;

    try {
      await ref.read(homeworkApiProvider).deleteLanguage(language.id);
      setState(() {
        _languageId = null;
        _levelId = null;
        _lessonId = null;
      });
      await _refreshTree();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
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
        setState(() {
          _levelId = created.id;
          _lessonId = null;
        });
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
        if (_levelId == level.id) {
          _levelId = null;
          _lessonId = null;
        }
      });
      await _refreshTree();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showLessonDialog({CmsLesson? lesson, int nextOrder = 1}) async {
    if (_levelId == null) return;
    final nameCtrl = TextEditingController(text: lesson?.name ?? '');
    final orderCtrl = TextEditingController(text: '${lesson?.order ?? nextOrder}');

    final saved = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: lesson == null ? 'Add lesson' : 'Edit lesson',
        icon: Icons.menu_book_outlined,
        content: AppFormColumn(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Lesson name'),
              autofocus: true,
            ),
            TextField(
              controller: orderCtrl,
              decoration: const InputDecoration(labelText: 'Order'),
              keyboardType: TextInputType.number,
            ),
          ],
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
    final order = int.tryParse(orderCtrl.text.trim()) ?? nextOrder;

    try {
      final api = ref.read(homeworkApiProvider);
      if (lesson == null) {
        final created = await api.createLesson(levelId: _levelId!, name: name, type: _lessonType, order: order);
        setState(() => _lessonId = created.id);
      } else {
        await api.updateLesson(lesson.id, name: name, order: order);
      }
      await _refreshTree();
      await _refreshContent();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lesson saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteLesson(CmsLesson lesson) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete lesson?',
      message: 'Remove "${lesson.name}" and its content?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;

    try {
      await ref.read(homeworkApiProvider).deleteLesson(lesson.id);
      setState(() {
        if (_lessonId == lesson.id) _lessonId = null;
      });
      await _refreshTree();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _refreshContent() async {
    if (_module == CmsModule.listening) {
      if (_levelId != null) ref.invalidate(cmsListeningExercisesProvider(_levelId!));
      return;
    }
    if (_lessonId == null) return;
    if (_module == CmsModule.words) {
      ref.invalidate(cmsLessonWordsProvider(_lessonId!));
    } else {
      ref.invalidate(cmsLessonSentencesProvider(_lessonId!));
    }
  }

  Future<void> _showWordDialog({CmsWord? word}) async {
    if (_lessonId == null) return;
    final englishCtrl = TextEditingController(text: word?.english ?? '');
    final uzbekCtrl = TextEditingController(text: word?.uzbek ?? '');

    final saved = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: word == null ? 'Add word' : 'Edit word',
        icon: Icons.abc,
        content: AppFormColumn(
          children: [
            TextField(controller: englishCtrl, decoration: const InputDecoration(labelText: 'English')),
            TextField(controller: uzbekCtrl, decoration: const InputDecoration(labelText: 'Uzbek')),
          ],
        ),
        actions: [
          AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context, false)),
          AppDialogActions.confirm(context, label: 'Save', onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    try {
      final api = ref.read(homeworkApiProvider);
      if (word == null) {
        await api.addWord(lessonId: _lessonId!, english: englishCtrl.text.trim(), uzbek: uzbekCtrl.text.trim());
      } else {
        await api.updateWord(word.id, english: englishCtrl.text.trim(), uzbek: uzbekCtrl.text.trim());
      }
      await _refreshContent();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Word saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showSentenceDialog({CmsSentence? sentence}) async {
    if (_lessonId == null) return;
    final englishCtrl = TextEditingController(text: sentence?.english ?? '');
    final uzbekCtrl = TextEditingController(text: sentence?.uzbek ?? '');

    final saved = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: sentence == null ? 'Add sentence' : 'Edit sentence',
        icon: Icons.translate,
        content: AppFormColumn(
          children: [
            TextField(
              controller: englishCtrl,
              decoration: const InputDecoration(labelText: 'English'),
              maxLines: 2,
            ),
            TextField(
              controller: uzbekCtrl,
              decoration: const InputDecoration(labelText: 'Uzbek'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context, false)),
          AppDialogActions.confirm(context, label: 'Save', onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    try {
      final api = ref.read(sentencesApiProvider);
      if (sentence == null) {
        await api.addSentence(lessonId: _lessonId!, english: englishCtrl.text.trim(), uzbek: uzbekCtrl.text.trim());
      } else {
        await api.updateSentence(sentence.id, english: englishCtrl.text.trim(), uzbek: uzbekCtrl.text.trim());
      }
      await _refreshContent();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sentence saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteWord(CmsWord word) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete word?',
      message: 'Remove "${word.english}" from this lesson?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;

    try {
      await ref.read(homeworkApiProvider).deleteWord(word.id);
      await _refreshContent();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _deleteSentence(CmsSentence sentence) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete sentence?',
      message: 'Remove "${sentence.english}" from this lesson?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (confirmed != true) return;

    try {
      await ref.read(sentencesApiProvider).deleteSentence(sentence.id);
      await _refreshContent();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showListeningDialog({CmsListeningExercise? exercise}) async {
    if (_levelId == null) return;
    final titleCtrl = TextEditingController(text: exercise?.title ?? '');
    final scriptCtrl = TextEditingController(text: exercise?.script ?? '');
    final orderCtrl = TextEditingController(text: '${exercise?.order ?? 1}');
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
                  decoration: const InputDecoration(labelText: 'Order'),
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
      final order = int.tryParse(orderCtrl.text.trim()) ?? 1;
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
    final module = _module;
    final isWords = module == CmsModule.words;
    final isListening = module == CmsModule.listening;
    final languagesAsync = ref.watch(
      isListening
          ? cmsListeningLanguagesProvider
          : isWords
              ? cmsLanguagesProvider
              : cmsSentencesLanguagesProvider,
    );
    final levelsAsync = _languageId == null
        ? null
        : ref.watch(
            isListening
                ? cmsListeningLevelsProvider(_languageId!)
                : isWords
                    ? cmsLevelsProvider(_languageId!)
                    : cmsSentencesLevelsProvider(_languageId!),
          );
    final lessonsAsync = isListening || _levelId == null
        ? null
        : ref.watch(isWords ? cmsLessonsProvider(_levelId!) : cmsSentencesLessonsProvider(_levelId!));
    final wordsAsync = !isWords || _lessonId == null ? null : ref.watch(cmsLessonWordsProvider(_lessonId!));
    final sentencesAsync = isWords || isListening || _lessonId == null
        ? null
        : ref.watch(cmsLessonSentencesProvider(_lessonId!));
    final listeningAsync =
        !isListening || _levelId == null ? null : ref.watch(cmsListeningExercisesProvider(_levelId!));
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final hasSelection = isListening ? _levelId != null : _lessonId != null;

    return AdaptiveScaffold(
      title: 'Learning CMS',
      selectedIndex: selectedIndex < 0 ? 3 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        IconButton(
          icon: const Icon(Icons.upload_file_outlined),
          tooltip: 'DOCX / OCR import',
          onPressed: () => context.go(widget.importRoute),
        ),
        GoBackIconButton(
          fallbackRoute: widget.selectedRoute.startsWith('/founder')
              ? '/founder/learning'
              : widget.selectedRoute.startsWith('/teacher')
                  ? '/teacher/profile'
                  : '/admin/learning',
        ),
      ],
      body: Column(
        children: [
          HubTabBarShell(
            tabBar: TabBar(
              controller: _moduleTabs,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Words'),
                Tab(text: 'Sentences'),
                Tab(text: 'Listening'),
              ],
            ),
          ),
          Expanded(
            child: languagesAsync.when(
              loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (languages) {
                if (languages.isEmpty) {
                  return EmptyState(
                    title: 'No languages',
                    message: isListening
                        ? 'Listening demo content is created on first backend startup.'
                        : isWords
                            ? 'Seed demo content or create a language in the API.'
                            : 'Sentence demo content is created on first backend startup.',
                    icon: Icons.menu_book_outlined,
                  );
                }

                _languageId ??= languages.first.id;

                final tree = isListening
                    ? _ListeningLevelTree(
                        languages: languages,
                        languageId: _languageId!,
                        levelId: _levelId,
                        levelsAsync: levelsAsync,
                        onLanguageChanged: (id) => setState(() {
                          _languageId = id;
                          _levelId = null;
                        }),
                        onLevelChanged: (id) => setState(() => _levelId = id),
                        onAddLanguage: () => _showLanguageDialog(),
                        onEditLanguage: (l) => _showLanguageDialog(language: l),
                        onDeleteLanguage: _deleteLanguage,
                        onAddLevel: () => _showLevelDialog(),
                        onEditLevel: (l) => _showLevelDialog(level: l),
                        onDeleteLevel: _deleteLevel,
                      )
                    : _ContentTree(
                        languages: languages,
                        languageId: _languageId!,
                        levelId: _levelId,
                        lessonId: _lessonId,
                        levelsAsync: levelsAsync,
                        lessonsAsync: lessonsAsync,
                        lessonSubtitle: (lesson) => isWords ? '${lesson.wordCount} words' : 'Sentence lesson',
                        onLanguageChanged: (id) => setState(() {
                          _languageId = id;
                          _levelId = null;
                          _lessonId = null;
                        }),
                        onLevelChanged: (id) => setState(() {
                          _levelId = id;
                          _lessonId = null;
                        }),
                        onLessonChanged: (id) => setState(() => _lessonId = id),
                        onAddLanguage: () => _showLanguageDialog(),
                        onEditLanguage: (l) => _showLanguageDialog(language: l),
                        onDeleteLanguage: _deleteLanguage,
                        onAddLevel: () => _showLevelDialog(),
                        onEditLevel: (l) => _showLevelDialog(level: l),
                        onDeleteLevel: _deleteLevel,
                        onAddLesson: (nextOrder) => _showLessonDialog(nextOrder: nextOrder),
                        onEditLesson: (l) => _showLessonDialog(lesson: l),
                        onDeleteLesson: _deleteLesson,
                      );

                final editor = !hasSelection
                    ? Center(
                        child: Text(
                          isListening
                              ? 'Select a level to manage listening exercises'
                              : isWords
                                  ? 'Select a lesson to manage words'
                                  : 'Select a lesson to manage sentences',
                        ),
                      )
                    : isListening
                        ? listeningAsync!.when(
                            loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
                            error: (e, _) => Text(e.toString()),
                            data: (exercises) => _ListeningExerciseEditor(
                              exercises: exercises,
                              onAdd: () => _showListeningDialog(),
                              onEdit: (e) => _showListeningDialog(exercise: e),
                              onDelete: _deleteListeningExercise,
                            ),
                          )
                        : isWords
                            ? wordsAsync!.when(
                                loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
                                error: (e, _) => Text(e.toString()),
                                data: (words) => _WordEditor(
                                  words: words,
                                  onAdd: () => _showWordDialog(),
                                  onEdit: (w) => _showWordDialog(word: w),
                                  onDelete: _deleteWord,
                                ),
                              )
                            : sentencesAsync!.when(
                                loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
                                error: (e, _) => Text(e.toString()),
                                data: (sentences) => _SentenceEditor(
                                  sentences: sentences,
                                  onAdd: () => _showSentenceDialog(),
                                  onEdit: (s) => _showSentenceDialog(sentence: s),
                                  onDelete: _deleteSentence,
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
                        onPressed: () => setState(() {
                          if (isListening) {
                            _levelId = null;
                          } else {
                            _lessonId = null;
                          }
                        }),
                        icon: const Icon(Icons.arrow_back),
                        label: Text(isListening ? 'Back to levels' : 'Back to lessons'),
                      ),
                    ),
                    Expanded(child: editor),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ListeningLevelTree extends StatelessWidget {
  const _ListeningLevelTree({
    required this.languages,
    required this.languageId,
    required this.levelId,
    required this.levelsAsync,
    required this.onLanguageChanged,
    required this.onLevelChanged,
    required this.onAddLanguage,
    required this.onEditLanguage,
    required this.onDeleteLanguage,
    required this.onAddLevel,
    required this.onEditLevel,
    required this.onDeleteLevel,
  });

  final List<LearningLanguage> languages;
  final String languageId;
  final String? levelId;
  final AsyncValue<List<CmsLevel>>? levelsAsync;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onLevelChanged;
  final VoidCallback onAddLanguage;
  final void Function(LearningLanguage language) onEditLanguage;
  final void Function(LearningLanguage language) onDeleteLanguage;
  final VoidCallback onAddLevel;
  final void Function(CmsLevel level) onEditLevel;
  final void Function(CmsLevel level) onDeleteLevel;

  @override
  Widget build(BuildContext context) {
    final currentLanguage = languages.firstWhere((l) => l.id == languageId, orElse: () => languages.first);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: languageId,
                decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder()),
                items: languages.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                onChanged: (id) {
                  if (id != null) onLanguageChanged(id);
                },
              ),
            ),
            IconButton(
              tooltip: 'Add language',
              onPressed: onAddLanguage,
              icon: const Icon(Icons.add),
            ),
            PopupMenuButton<String>(
              tooltip: 'Language actions',
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                if (value == 'rename') {
                  onEditLanguage(currentLanguage);
                } else if (value == 'delete') {
                  onDeleteLanguage(currentLanguage);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
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
                    subtitle: 'Listening exercises',
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

class _ContentTree extends StatelessWidget {
  const _ContentTree({
    required this.languages,
    required this.languageId,
    required this.levelId,
    required this.lessonId,
    required this.levelsAsync,
    required this.lessonsAsync,
    required this.lessonSubtitle,
    required this.onLanguageChanged,
    required this.onLevelChanged,
    required this.onLessonChanged,
    required this.onAddLanguage,
    required this.onEditLanguage,
    required this.onDeleteLanguage,
    required this.onAddLevel,
    required this.onEditLevel,
    required this.onDeleteLevel,
    required this.onAddLesson,
    required this.onEditLesson,
    required this.onDeleteLesson,
  });

  final List<LearningLanguage> languages;
  final String languageId;
  final String? levelId;
  final String? lessonId;
  final AsyncValue<List<CmsLevel>>? levelsAsync;
  final AsyncValue<List<CmsLesson>>? lessonsAsync;
  final String Function(CmsLesson lesson) lessonSubtitle;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<String> onLevelChanged;
  final ValueChanged<String> onLessonChanged;
  final VoidCallback onAddLanguage;
  final void Function(LearningLanguage language) onEditLanguage;
  final void Function(LearningLanguage language) onDeleteLanguage;
  final VoidCallback onAddLevel;
  final void Function(CmsLevel level) onEditLevel;
  final void Function(CmsLevel level) onDeleteLevel;
  final void Function(int nextOrder) onAddLesson;
  final void Function(CmsLesson lesson) onEditLesson;
  final void Function(CmsLesson lesson) onDeleteLesson;

  @override
  Widget build(BuildContext context) {
    final currentLanguage = languages.firstWhere((l) => l.id == languageId, orElse: () => languages.first);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: languageId,
                decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder()),
                items: languages.map((l) => DropdownMenuItem(value: l.id, child: Text(l.name))).toList(),
                onChanged: (id) {
                  if (id != null) onLanguageChanged(id);
                },
              ),
            ),
            IconButton(
              tooltip: 'Add language',
              onPressed: onAddLanguage,
              icon: const Icon(Icons.add),
            ),
            PopupMenuButton<String>(
              tooltip: 'Language actions',
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                if (value == 'rename') {
                  onEditLanguage(currentLanguage);
                } else if (value == 'delete') {
                  onDeleteLanguage(currentLanguage);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
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
                  (level) => ExpansionTile(
                    title: Text(level.name),
                    initiallyExpanded: levelId == level.id,
                    trailing: PopupMenuButton<String>(
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'rename', child: Text('Rename level')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete level')),
                      ],
                      onSelected: (value) {
                        if (value == 'rename') {
                          onEditLevel(level);
                        } else if (value == 'delete') {
                          onDeleteLevel(level);
                        }
                      },
                    ),
                    onExpansionChanged: (open) {
                      if (open) onLevelChanged(level.id);
                    },
                    children: [
                      if (levelId == level.id && lessonsAsync != null)
                        lessonsAsync!.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: CircularProgressIndicator(),
                          ),
                          error: (e, _) => Padding(padding: const EdgeInsets.all(AppSpacing.xs), child: Text(e.toString())),
                          data: (lessons) => Column(
                            children: [
                              ...lessons.map(
                                (lesson) => CmsTreeItem(
                                  dense: true,
                                  title: lesson.name,
                                  subtitle: lessonSubtitle(lesson),
                                  selected: lessonId == lesson.id,
                                  onTap: () => onLessonChanged(lesson.id),
                                  trailing: PopupMenuButton<String>(
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit lesson')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete lesson')),
                                    ],
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        onEditLesson(lesson);
                                      } else if (value == 'delete') {
                                        onDeleteLesson(lesson);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () => onAddLesson(lessons.length + 1),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add lesson'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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

class _WordEditor extends StatelessWidget {
  const _WordEditor({
    required this.words,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CmsWord> words;
  final VoidCallback onAdd;
  final void Function(CmsWord word) onEdit;
  final void Function(CmsWord word) onDelete;

  @override
  Widget build(BuildContext context) {
    return _PairEditor(
      countLabel: '${words.length} words',
      addLabel: 'Add word',
      emptyTitle: 'No words in lesson',
      emptyMessage: 'Add words manually or use bulk import.',
      emptyIcon: Icons.abc,
      items: words
          .map(
            (word) => _PairItem(
              primary: word.english,
              secondary: word.uzbek,
              onEdit: () => onEdit(word),
              onDelete: () => onDelete(word),
            ),
          )
          .toList(),
      onAdd: onAdd,
    );
  }
}

class _SentenceEditor extends StatelessWidget {
  const _SentenceEditor({
    required this.sentences,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CmsSentence> sentences;
  final VoidCallback onAdd;
  final void Function(CmsSentence sentence) onEdit;
  final void Function(CmsSentence sentence) onDelete;

  @override
  Widget build(BuildContext context) {
    return _PairEditor(
      countLabel: '${sentences.length} sentences',
      addLabel: 'Add sentence',
      emptyTitle: 'No sentences in lesson',
      emptyMessage: 'Add sentences manually or use bulk import on the Sentences tab.',
      emptyIcon: Icons.translate,
      items: sentences
          .map(
            (sentence) => _PairItem(
              primary: sentence.english,
              secondary: sentence.uzbek,
              onEdit: () => onEdit(sentence),
              onDelete: () => onDelete(sentence),
            ),
          )
          .toList(),
      onAdd: onAdd,
    );
  }
}

class _PairItem {
  const _PairItem({
    required this.primary,
    required this.secondary,
    required this.onEdit,
    required this.onDelete,
  });

  final String primary;
  final String secondary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
}

class _PairEditor extends StatelessWidget {
  const _PairEditor({
    required this.countLabel,
    required this.addLabel,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.items,
    required this.onAdd,
  });

  final String countLabel;
  final String addLabel;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final List<_PairItem> items;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Text(countLabel, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: Text(addLabel)),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? EmptyState(title: emptyTitle, message: emptyMessage, icon: emptyIcon)
              : ListView.builder(
                  padding: AppSpacing.listGutter,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return CmsContentCard(
                      title: item.primary,
                      subtitle: item.secondary,
                      onEdit: item.onEdit,
                      onDelete: item.onDelete,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
