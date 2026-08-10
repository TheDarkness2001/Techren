import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/learning_cms.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../../domain/entities/scheduling.dart';
import '../../../../domain/entities/words.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/learning_cms_provider.dart';
import '../../../providers/scheduling_provider.dart';
import '../../../providers/staff_navigation_provider.dart';
import '../../../providers/words_provider.dart';
import '../../learning/widgets/module_content_manager.dart';
import '../../sentences/widgets/sentences_hub_widgets.dart';
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
  String? _permissionsLanguageId;
  String? _permissionsLanguageName;
  String? _permissionsExpandedGroupId;
  final Set<String> _permissionsBusyIds = {};
  bool _permissionsBulkBusy = false;

  String get _prefix => widget.selectedRoute.startsWith('/founder') ? '/founder' : '/admin';

  bool get _canEditHomework {
    final user = ref.read(authProvider).user;
    final rolePerms = ref.read(staffRolePermissionsProvider);
    return user != null && user.canEditHomeworkFor(rolePerms);
  }

  bool get _canDeleteHomework {
    final user = ref.read(authProvider).user;
    final rolePerms = ref.read(staffRolePermissionsProvider);
    return user != null && user.canManageHomeworkFor(rolePerms);
  }

  void _selectLanguage(LearningLanguage language) {
    setState(() {
      _languageId = language.id;
      _levelId = null;
    });
  }

  void _resetPermissions() {
    setState(() {
      _permissionsLanguageId = null;
      _permissionsLanguageName = null;
      _permissionsExpandedGroupId = null;
      _permissionsBusyIds.clear();
      _permissionsBulkBusy = false;
    });
  }

  void _goBack() {
    if (_tab == WordsHubTab.permissions && _permissionsLanguageId != null) {
      _resetPermissions();
      return;
    }
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

  List<UnifiedGroupView> _groupsForSubject(
    List<UnifiedGroupView> items,
    String? subjectName,
  ) {
    if (subjectName == null || subjectName.trim().isEmpty) return items;
    final key = subjectName.trim().toLowerCase();
    final matched = items
        .where((i) => (i.group.subjectName ?? '').trim().toLowerCase() == key)
        .toList();
    return matched.isNotEmpty ? matched : items;
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

  Future<void> _togglePractice(CmsLevel level, bool unlock, String groupId) async {
    setState(() => _permissionsBusyIds.add(level.id));
    try {
      await ref.read(homeworkApiProvider).togglePracticeUnlock(
            levelId: level.id,
            groupId: groupId,
            unlock: unlock,
          );
      if (_permissionsLanguageId != null) {
        ref.invalidate(cmsLevelsProvider(_permissionsLanguageId!));
      }
      ref.invalidate(cmsLessonsProvider(level.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _permissionsBusyIds.remove(level.id));
    }
  }

  Future<void> _toggleExam(CmsLesson lesson, bool unlock, String groupId) async {
    setState(() => _permissionsBusyIds.add(lesson.id));
    try {
      await ref.read(homeworkApiProvider).toggleExamLock(
            lessonId: lesson.id,
            groupId: groupId,
            unlock: unlock,
          );
      ref.invalidate(cmsLessonsProvider(lesson.levelId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _permissionsBusyIds.remove(lesson.id));
    }
  }

  Future<void> _bulkUnlockLevel(
    CmsLevel level,
    bool unlock,
    String groupId,
    List<CmsLesson> lessons,
  ) async {
    setState(() {
      _permissionsBulkBusy = true;
      _permissionsBusyIds.add(level.id);
      for (final lesson in lessons) {
        _permissionsBusyIds.add(lesson.id);
      }
    });
    try {
      await ref.read(homeworkApiProvider).bulkUnlockLevel(
            levelId: level.id,
            groupId: groupId,
            unlock: unlock,
          );
      if (_permissionsLanguageId != null) {
        ref.invalidate(cmsLevelsProvider(_permissionsLanguageId!));
      }
      ref.invalidate(cmsLessonsProvider(level.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              unlock ? 'Unlocked all of ${level.name}' : 'Locked all of ${level.name}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _permissionsBulkBusy = false;
          _permissionsBusyIds.remove(level.id);
          for (final lesson in lessons) {
            _permissionsBusyIds.remove(lesson.id);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languagesAsync = ref.watch(cmsLanguagesProvider);
    final levelsAsync = _languageId == null ? null : ref.watch(cmsLevelsProvider(_languageId!));
    final lessonsAsync = _levelId == null ? null : ref.watch(cmsLessonsProvider(_levelId!));
    final groupsAsync = ref.watch(unifiedGroupsProvider((page: 1, search: '')));
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));
    final canManage = _canEditHomework;

    return AdaptiveScaffold(
      title: 'Words',
      selectedIndex: selectedIndex < 0 ? 3 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        if (canManage && _tab != WordsHubTab.permissions)
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
          ref.invalidate(unifiedGroupsProvider((page: 1, search: '')));
          if (_languageId != null) ref.invalidate(cmsLevelsProvider(_languageId!));
          if (_levelId != null) ref.invalidate(cmsLessonsProvider(_levelId!));
          if (_permissionsLanguageId != null) {
            ref.invalidate(cmsLevelsProvider(_permissionsLanguageId!));
          }
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
                if (tab == WordsHubTab.studentProgress || tab == WordsHubTab.permissions) {
                  _languageId = null;
                  _levelId = null;
                }
                if (tab != WordsHubTab.permissions) _resetPermissions();
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
                groupsAsync: groupsAsync,
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
    required AsyncValue<PaginatedResult<UnifiedGroupView>> groupsAsync,
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
        return ModuleContentManager(
          module: ContentManagerModule.words,
          allowDelete: _canDeleteHomework,
        );
      case WordsHubTab.permissions:
        return groupsAsync.when(
          loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
          error: (e, _) => Text(e.toString()),
          data: (result) => _buildPermissionsTab(result.items, languages),
        );
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

  Widget _buildPermissionsTab(List<UnifiedGroupView> items, List<LearningLanguage> languages) {
    if (_permissionsLanguageId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose a language / subject',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          WordsLanguageSection(
            languages: languages,
            selectedLanguageId: null,
            onLanguageSelected: (language) => setState(() {
              _permissionsLanguageId = language.id;
              _permissionsLanguageName = language.name;
              _permissionsExpandedGroupId = null;
            }),
          ),
        ],
      );
    }

    final relatedGroups = _groupsForSubject(items, _permissionsLanguageName);
    final levelsAsync = ref.watch(cmsLevelsProvider(_permissionsLanguageId!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SentencesBackButton(label: 'Back to Languages', onPressed: _resetPermissions),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Groups for ${_permissionsLanguageName ?? 'subject'}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Teachers unlock only their groups. Manager and founder can unlock any group.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
        ),
        const SizedBox(height: AppSpacing.md),
        if (relatedGroups.isEmpty)
          const EmptyState(
            title: 'No groups for this subject',
            message: 'Create groups under this subject in scheduling first.',
            icon: Icons.groups_outlined,
          )
        else
          levelsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
            data: (levels) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in relatedGroups) ...[
                  SentencesGroupCard(
                    item: item,
                    onManageLessons: () => setState(() {
                      _permissionsExpandedGroupId =
                          _permissionsExpandedGroupId == item.group.id ? null : item.group.id;
                    }),
                    actionLabel: _permissionsExpandedGroupId == item.group.id
                        ? 'Hide lesson locks'
                        : 'Unlock / Lock Lessons',
                  ),
                  if (_permissionsExpandedGroupId == item.group.id) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _WordsPermissionsLevelsLoader(
                      group: item,
                      levels: levels,
                      busyIds: _permissionsBusyIds,
                      bulkBusy: _permissionsBulkBusy,
                      onBack: () => setState(() => _permissionsExpandedGroupId = null),
                      onTogglePractice: (level, unlock) =>
                          _togglePractice(level, unlock, item.group.id),
                      onToggleExam: (lesson, unlock) =>
                          _toggleExam(lesson, unlock, item.group.id),
                      onBulkUnlockLevel: (level, unlock, lessons) =>
                          _bulkUnlockLevel(level, unlock, item.group.id, lessons),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
      ],
    );
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

class _WordsPermissionsLevelsLoader extends ConsumerWidget {
  const _WordsPermissionsLevelsLoader({
    required this.group,
    required this.levels,
    required this.busyIds,
    required this.onBack,
    required this.onTogglePractice,
    required this.onToggleExam,
    required this.onBulkUnlockLevel,
    this.bulkBusy = false,
  });

  final UnifiedGroupView group;
  final List<CmsLevel> levels;
  final Set<String> busyIds;
  final VoidCallback onBack;
  final Future<void> Function(CmsLevel level, bool unlock) onTogglePractice;
  final Future<void> Function(CmsLesson lesson, bool unlock) onToggleExam;
  final Future<void> Function(CmsLevel level, bool unlock, List<CmsLesson> lessons) onBulkUnlockLevel;
  final bool bulkBusy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsByLevel = <String, List<CmsLesson>>{};
    var stillLoading = false;

    for (final level in levels) {
      final async = ref.watch(cmsLessonsProvider(level.id));
      async.when(
        data: (lessons) => lessonsByLevel[level.id] = lessons,
        loading: () => stillLoading = true,
        error: (_, __) {},
      );
    }

    if (stillLoading && lessonsByLevel.length < levels.length) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.md),
        child: LinearProgressIndicator(),
      );
    }

    return SentencesLessonAccessPanel(
      groupName: group.group.groupName,
      groupId: group.group.id,
      levels: levels,
      lessonsByLevel: lessonsByLevel,
      busyIds: busyIds,
      bulkBusy: bulkBusy,
      onTogglePractice: onTogglePractice,
      onToggleExam: onToggleExam,
      onBulkUnlockLevel: (level, unlock) => onBulkUnlockLevel(
            level,
            unlock,
            lessonsByLevel[level.id] ?? const [],
          ),
      onBack: onBack,
      showBackButton: false,
    );
  }
}
