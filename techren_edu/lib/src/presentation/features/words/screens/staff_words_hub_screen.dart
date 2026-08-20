import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
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
  String? _lessonId;
  String? _permissionsLanguageId;
  String? _permissionsLanguageName;
  String? _permissionsExpandedGroupId;
  final Set<String> _permissionsBusyIds = {};
  bool _permissionsBulkBusy = false;

  String get _prefix => widget.selectedRoute.startsWith('/founder') ? '/founder' : '/admin';

  bool get _canDeleteHomework {
    final user = ref.read(authProvider).user;
    final rolePerms = ref.read(staffRolePermissionsProvider);
    return user != null && user.canManageHomeworkFor(rolePerms);
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
    if (_tab == WordsHubTab.permissions && _permissionsExpandedGroupId != null) {
      setState(() => _permissionsExpandedGroupId = null);
      return;
    }
    if (_levelId != null) {
      setState(() {
        _levelId = null;
        _lessonId = null;
      });
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
      final result = await ref.read(homeworkApiProvider).bulkUnlockLevel(
            levelId: level.id,
            groupId: groupId,
            unlock: unlock,
          );
      if (_permissionsLanguageId != null) {
        ref.invalidate(cmsLevelsProvider(_permissionsLanguageId!));
      }
      ref.invalidate(cmsLessonsProvider(level.id));
      if (mounted) {
        final lessonsTotal = result['lessonsTotal'];
        final count = lessonsTotal is int ? lessonsTotal : int.tryParse('$lessonsTotal') ?? lessons.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              unlock
                  ? 'Opened ${level.name} and $count classes'
                  : 'Closed ${level.name} and $count classes',
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
    final groupsAsync = ref.watch(unifiedGroupsProvider((page: 1, search: '')));
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));

    return AdaptiveScaffold(
      title: 'Words',
      selectedIndex: selectedIndex < 0 ? 3 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
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
                  _lessonId = null;
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
                groupsAsync: groupsAsync,
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
    required AsyncValue<PaginatedResult<UnifiedGroupView>> groupsAsync,
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
          showExamStatus: true,
          practicePreview: false,
        );
      case WordsHubTab.practice:
        return _buildLanguageFlow(
          languages: languages,
          showExamStatus: false,
          practicePreview: true,
        );
    }
  }

  Widget _buildPermissionsTab(List<UnifiedGroupView> items, List<LearningLanguage> languages) {
    final language = pickEnglishLanguage(languages);
    if (language == null) {
      return const EmptyState(
        title: 'English is not set up',
        message: 'English content is created on the server. Refresh or contact an admin.',
        icon: Icons.translate_outlined,
      );
    }
    if (_permissionsLanguageId != language.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _permissionsLanguageId = language.id;
          _permissionsLanguageName = language.name;
        });
      });
    }
    final languageId = _permissionsLanguageId ?? language.id;
    final languageName = _permissionsLanguageName ?? language.name;

    final relatedGroups = _groupsForSubject(items, languageName);
    final levelsAsync = ref.watch(cmsLevelsProvider(languageId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Groups',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Teachers unlock only their groups. Manager and founder can unlock any group.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
                fontSize: 11,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
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
                    expanded: _permissionsExpandedGroupId == item.group.id,
                    onManageLessons: () => setState(() {
                      _permissionsExpandedGroupId =
                          _permissionsExpandedGroupId == item.group.id ? null : item.group.id;
                    }),
                    actionLabel: _permissionsExpandedGroupId == item.group.id
                        ? 'Hide lesson locks'
                        : 'Unlock / Lock Lessons',
                  ),
                  if (_permissionsExpandedGroupId == item.group.id) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.sm),
                      child: _WordsPermissionsLevelsLoader(
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
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLanguageFlow({
    required List<LearningLanguage> languages,
    required bool showExamStatus,
    required bool practicePreview,
    void Function(String lessonId, String lessonName)? onLessonTap,
  }) {
    final language = pickEnglishLanguage(languages);
    final effectiveLanguageId = _languageId ?? language?.id;
    if (_languageId == null && effectiveLanguageId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _languageId = effectiveLanguageId);
      });
    }
    final levelsAsync = effectiveLanguageId == null ? null : ref.watch(cmsLevelsProvider(effectiveLanguageId));
    final lessonsAsync = _levelId == null ? null : ref.watch(cmsLessonsProvider(_levelId!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (language == null)
          const EmptyState(
            title: 'English is not set up',
            message: 'English content is created on the server. Refresh or contact an admin.',
            icon: Icons.translate_outlined,
          ),
        if (effectiveLanguageId != null && levelsAsync != null)
          levelsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Text(e.toString()),
            data: (levels) {
              if (_levelId == null && levels.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _levelId != null) return;
                  setState(() => _levelId = levels.first.id);
                });
              }
              return WordsLevelList(
                levels: levels,
                selectedLevelId: _levelId,
                onLevelTap: (id, _) => setState(() {
                  _levelId = id;
                  _lessonId = null;
                }),
              );
            },
          ),
        if (_levelId != null && lessonsAsync != null)
          lessonsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Text(e.toString()),
            data: (lessons) {
              if (_lessonId == null && lessons.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _lessonId != null) return;
                  setState(() => _lessonId = lessons.first.id);
                });
              }
              return Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: WordsLessonList(
                  lessons: lessons,
                  selectedLessonId: _lessonId,
                  showExamStatus: showExamStatus,
                  onLessonSelected: (id, _) => setState(() => _lessonId = id),
                  onLessonTap: (lessonId, lessonName) {
                    if (practicePreview || showExamStatus) {
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
              );
            },
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
