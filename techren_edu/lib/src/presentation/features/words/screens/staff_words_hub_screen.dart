import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/staff_permissions.dart';
import '../../../../domain/entities/learning_cms.dart';
import '../../../../domain/entities/words.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/learning_cms_provider.dart';
import '../../../providers/staff_navigation_provider.dart';
import '../../../providers/words_provider.dart';
import '../../learning/widgets/module_content_manager.dart';
import '../widgets/words_hub_widgets.dart';
import 'word_practice_screen.dart';

class StaffWordsHubScreen extends ConsumerStatefulWidget {
  const StaffWordsHubScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<StaffWordsHubScreen> createState() => _StaffWordsHubScreenState();
}

class _StaffWordsHubScreenState extends ConsumerState<StaffWordsHubScreen> {
  WordsHubTab _tab = WordsHubTab.practice;
  String? _languageId;
  String? _levelId;

  String get _prefix => widget.selectedRoute.startsWith('/founder') ? '/founder' : '/admin';

  bool get _canManageHomework {
    final user = ref.read(authProvider).user;
    final rolePerms = ref.read(staffRolePermissionsProvider);
    return user != null && canAccessStaffRoute(user, '$_prefix/words', rolePerms);
  }

  void _selectLanguage(LearningLanguage language) {
    setState(() {
      _languageId = language.id;
      _levelId = null;
    });
  }

  void _goBack() {
    if (_levelId != null) {
      setState(() => _levelId = null);
      return;
    }
    if (_languageId != null) {
      setState(() => _languageId = null);
      return;
    }
    context.go('$_prefix/learning');
  }

  Future<void> _addLanguage() async {
    final name = await _promptName(title: 'Add language', label: 'Language name');
    if (name == null) return;
    try {
      final created = await ref.read(homeworkApiProvider).createLanguage(
            name: name,
            moduleType: 'words',
          );
      ref.invalidate(cmsLanguagesProvider);
      if (!mounted) return;
      setState(() {
        _languageId = created.id;
        _levelId = null;
        _tab = WordsHubTab.lessons;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created "${created.name}". Add levels & lessons in the Lessons tab.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''))),
      );
    }
  }

  Future<String?> _promptName({required String title, String label = 'Name'}) async {
    final ctrl = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    final languagesAsync = ref.watch(cmsLanguagesProvider);
    final levelsAsync = _languageId == null ? null : ref.watch(cmsLevelsProvider(_languageId!));
    final lessonsAsync = _levelId == null ? null : ref.watch(cmsLessonsProvider(_levelId!));
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));
    final canManage = _canManageHomework;

    return AdaptiveScaffold(
      title: 'Words',
      selectedIndex: selectedIndex < 0 ? 3 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        if (canManage)
          IconButton(
            tooltip: 'Add language',
            onPressed: _addLanguage,
            icon: const Icon(Icons.add),
          ),
        IconButton(
          tooltip: 'Go back',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(cmsLanguagesProvider);
          if (_languageId != null) ref.invalidate(cmsLevelsProvider(_languageId!));
          if (_levelId != null) ref.invalidate(cmsLessonsProvider(_levelId!));
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const WordsHubHeader(),
            const SizedBox(height: AppSpacing.md),
            WordsHubTabBar(
              selected: _tab,
              onSelected: (tab) => setState(() {
                _tab = tab;
                if (tab == WordsHubTab.studentProgress) {
                  _languageId = null;
                  _levelId = null;
                }
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            languagesAsync.when(
              loading: () => const LoadingState(kind: LoadingSkeletonKind.dashboard),
              error: (e, _) => Text(e.toString()),
              data: (languages) => _buildTabBody(
                context,
                languages: languages,
                levelsAsync: levelsAsync,
                lessonsAsync: lessonsAsync,
                canManage: canManage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBody(
    BuildContext context, {
    required List<LearningLanguage> languages,
    required AsyncValue<List<CmsLevel>>? levelsAsync,
    required AsyncValue<List<CmsLesson>>? lessonsAsync,
    required bool canManage,
  }) {
    switch (_tab) {
      case WordsHubTab.studentProgress:
        return WordsHubLinkPanel(
          title: 'Student Progress',
          message: 'Review words accuracy, lessons passed, and per-student learning stats.',
          buttonLabel: 'View Student Progress',
          icon: Icons.insights_outlined,
          onOpen: () => context.go('$_prefix/progress'),
        );
      case WordsHubTab.lessons:
        return const ModuleContentManager(module: ContentManagerModule.words);
      case WordsHubTab.exam:
        return _buildLanguageFlow(
          languages: languages,
          levelsAsync: levelsAsync,
          lessonsAsync: lessonsAsync,
          showExamStatus: true,
          practicePreview: false,
          onAddLanguage: canManage ? _addLanguage : null,
        );
      case WordsHubTab.practice:
        return _buildLanguageFlow(
          languages: languages,
          levelsAsync: levelsAsync,
          lessonsAsync: lessonsAsync,
          showExamStatus: false,
          practicePreview: true,
          onAddLanguage: canManage ? _addLanguage : null,
        );
    }
  }

  Widget _buildLanguageFlow({
    required List<LearningLanguage> languages,
    required AsyncValue<List<CmsLevel>>? levelsAsync,
    required AsyncValue<List<CmsLesson>>? lessonsAsync,
    VoidCallback? onAddLanguage,
    required bool showExamStatus,
    required bool practicePreview,
    void Function(String lessonId, String lessonName)? onLessonTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WordsLanguageSection(
          languages: languages,
          selectedLanguageId: _languageId,
          onLanguageSelected: _selectLanguage,
          onAddLanguage: onAddLanguage,
        ),
        if (_languageId != null && levelsAsync != null)
          levelsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Text(e.toString()),
            data: (levels) => WordsLevelList(
              levels: levels,
              onLevelTap: (id, _) => setState(() => _levelId = id),
            ),
          ),
        if (_levelId != null && lessonsAsync != null)
          lessonsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Text(e.toString()),
            data: (lessons) => WordsLessonList(
              lessons: lessons,
              showExamStatus: showExamStatus,
              onLessonTap: (lessonId, lessonName) {
                if (practicePreview) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => WordPracticeScreen(lessonId: lessonId, lessonName: lessonName),
                    ),
                  );
                  return;
                }
                onLessonTap?.call(lessonId, lessonName);
              },
            ),
          ),
      ],
    );
  }
}
