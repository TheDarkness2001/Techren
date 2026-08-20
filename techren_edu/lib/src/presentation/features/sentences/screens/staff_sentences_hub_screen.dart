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
import '../../../providers/progress_provider.dart';
import '../../../providers/scheduling_provider.dart';
import '../../../providers/sentences_provider.dart';
import '../../../providers/staff_navigation_provider.dart';
import '../../../providers/words_provider.dart';
import '../../learning/widgets/module_content_manager.dart';
import '../widgets/sentences_hub_widgets.dart';
import '../widgets/sentences_practice_view.dart';

String _friendlyProgressError(Object error) {
  final text = error.toString();
  if (text.contains('403') || text.contains('FORBIDDEN') || text.contains('permission')) {
    return 'You do not have access to this group’s progress.';
  }
  if (text.contains('connection') || text.contains('SocketException') || text.contains('CONNECTION')) {
    return 'Cannot reach the server. Check your connection and try again.';
  }
  return 'Could not load progress. Please try again.';
}

class StaffSentencesHubScreen extends ConsumerStatefulWidget {
  const StaffSentencesHubScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<StaffSentencesHubScreen> createState() => _StaffSentencesHubScreenState();
}

class _StaffSentencesHubScreenState extends ConsumerState<StaffSentencesHubScreen> {
  SentencesHubTab _tab = SentencesHubTab.practice;
  SentencesPracticeStep _practiceStep = SentencesPracticeStep.levels;
  String? _languageId;
  String? _levelId;
  String? _lessonId;
  String? _levelName;
  String? _permissionsLanguageId;
  String? _permissionsLanguageName;
  String? _permissionsExpandedGroupId;
  final Set<String> _permissionsBusyIds = {};
  bool _permissionsBulkBusy = false;
  DateTime? _progressDate;

  String get _prefix => widget.selectedRoute.startsWith('/founder') ? '/founder' : '/admin';

  void _goBack() {
    if (_tab == SentencesHubTab.practice) {
      if (_practiceStep == SentencesPracticeStep.practice) {
        setState(() => _practiceStep = SentencesPracticeStep.classes);
        return;
      }
    }
    if (_tab == SentencesHubTab.permissions && _permissionsExpandedGroupId != null) {
      setState(() => _permissionsExpandedGroupId = null);
      return;
    }
    context.go('$_prefix/learning');
  }

  void _resetPractice() {
    setState(() {
      _practiceStep = SentencesPracticeStep.levels;
      _languageId = null;
      _levelId = null;
      _lessonId = null;
      _levelName = null;
    });
  }

  void _resetPermissions() {
    setState(() {
      _permissionsLanguageId = null;
      _permissionsLanguageName = null;
      _permissionsExpandedGroupId = null;
      _permissionsBusyIds.clear();
    });
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
        ref.invalidate(cmsSentencesLevelsProvider(_permissionsLanguageId!));
      }
      // Locking practice also locks every class on the server.
      ref.invalidate(cmsSentencesLessonsProvider(level.id));
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
      ref.invalidate(cmsSentencesLessonsProvider(lesson.levelId));
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
        ref.invalidate(cmsSentencesLevelsProvider(_permissionsLanguageId!));
      }
      ref.invalidate(cmsSentencesLessonsProvider(level.id));
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
    final languagesAsync = ref.watch(cmsSentencesLanguagesProvider);
    final leaderboardAsync = ref.watch(sentencesLeaderboardProvider);
    final groupsAsync = ref.watch(unifiedGroupsProvider((page: 1, search: '')));
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));

    return AdaptiveScaffold(
      title: 'Sentences',
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
          ref.invalidate(cmsSentencesLanguagesProvider);
          ref.invalidate(sentencesLeaderboardProvider);
          ref.invalidate(unifiedGroupsProvider((page: 1, search: '')));
          if (_languageId != null) ref.invalidate(cmsSentencesLevelsProvider(_languageId!));
          if (_levelId != null) ref.invalidate(cmsSentencesLessonsProvider(_levelId!));
          if (_permissionsLanguageId != null) {
            ref.invalidate(cmsSentencesLevelsProvider(_permissionsLanguageId!));
          }
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SentencesHubTabBar(
              selected: _tab,
              onSelected: (tab) => setState(() {
                _tab = tab;
                if (tab != SentencesHubTab.practice) _resetPractice();
                if (tab != SentencesHubTab.permissions) _resetPermissions();
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            switch (_tab) {
              SentencesHubTab.practice => languagesAsync.when(
                  loading: () => const LoadingState(kind: LoadingSkeletonKind.dashboard),
                  error: (e, _) => Text(e.toString()),
                  data: (languages) => _buildPracticeTab(languages),
                ),
              SentencesHubTab.leaderboard => leaderboardAsync.when(
                  loading: () => const LoadingState(kind: LoadingSkeletonKind.table),
                  error: (e, _) => Text(e.toString()),
                  data: (board) => SentencesLeaderboardTable(entries: board.leaderboard),
                ),
              SentencesHubTab.lessons => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: ModuleContentManager(
                    module: ContentManagerModule.sentences,
                    allowDelete: ref.watch(authProvider).user?.canManageHomeworkFor(
                          ref.watch(staffRolePermissionsProvider),
                        ) ??
                        false,
                  ),
                ),
              SentencesHubTab.permissions => groupsAsync.when(
                  loading: () => const LoadingState(kind: LoadingSkeletonKind.dashboard),
                  error: (e, _) => Text(e.toString()),
                  data: (result) => _buildPermissionsTab(result.items, languagesAsync),
                ),
              SentencesHubTab.studentProgress => _buildStudentProgressTab(groupsAsync, languagesAsync),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeTab(
    List<LearningLanguage> languages,
  ) {
    final language = pickEnglishLanguage(languages);
    final effectiveLanguageId = _languageId ?? language?.id;
    if (_languageId == null && effectiveLanguageId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _languageId = effectiveLanguageId);
      });
    }
    final levelsAsync = effectiveLanguageId == null ? null : ref.watch(cmsSentencesLevelsProvider(effectiveLanguageId));
    final lessonsAsync = _levelId == null ? null : ref.watch(cmsSentencesLessonsProvider(_levelId!));

    if (_practiceStep == SentencesPracticeStep.practice && _lessonId != null) {
      return SentencesPracticeView(
        lessonId: _lessonId!,
        lessonName: _levelName ?? 'Lesson',
        onBack: () => setState(() => _practiceStep = SentencesPracticeStep.classes),
        onEnd: _resetPractice,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (language == null)
          const EmptyState(
            title: 'English is not set up',
            message: 'English content is created on the server. Refresh or contact an admin.',
            icon: Icons.translate_outlined,
          ),
        if (levelsAsync != null)
          levelsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
            data: (levels) {
              if (_levelId == null && levels.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _levelId != null) return;
                  final first = levels.first;
                  setState(() {
                    _levelId = first.id;
                    _levelName = first.name;
                    _practiceStep = SentencesPracticeStep.classes;
                  });
                });
              }
              return SentencesLevelGrid(
                levels: levels,
                selectedLevelId: _levelId,
                onLevelTap: (level) => setState(() {
                  _levelId = level.id;
                  _levelName = level.name;
                  _lessonId = null;
                  _practiceStep = SentencesPracticeStep.classes;
                }),
              );
            },
          ),
        if (lessonsAsync != null) ...[
          const SizedBox(height: AppSpacing.lg),
          lessonsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
            data: (lessons) {
              if (_lessonId == null && lessons.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _lessonId != null) return;
                  setState(() => _lessonId = lessons.first.id);
                });
              }
              return SentencesClassGrid(
                levelName: _levelName ?? 'Level',
                lessons: lessons,
                selectedLessonId: _lessonId,
                onLessonSelected: (lesson) => setState(() => _lessonId = lesson.id),
                onLessonTap: (lesson) => setState(() {
                  _lessonId = lesson.id;
                  _practiceStep = SentencesPracticeStep.practice;
                }),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildPermissionsTab(
    List<UnifiedGroupView> items,
    AsyncValue<List<LearningLanguage>> languagesAsync,
  ) {
    return languagesAsync.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
      error: (e, _) => EmptyState(
        title: 'Could not load',
        message: _friendlyProgressError(e),
        icon: Icons.error_outline,
      ),
      data: (languages) {
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
        final levelsAsync = ref.watch(cmsSentencesLevelsProvider(languageId));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                          child: _PermissionsLevelsLoader(
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
                            showBackButton: false,
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
      },
    );
  }

  Widget _buildStudentProgressTab(
    AsyncValue<PaginatedResult<UnifiedGroupView>> groupsAsync,
    AsyncValue<List<LearningLanguage>> languagesAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SentencesProgressFilters(
          selectedDate: _progressDate,
          onDateChanged: (date) => setState(() => _progressDate = date),
        ),
        const SizedBox(height: AppSpacing.md),
        languagesAsync.when(
          loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
          error: (e, _) => EmptyState(
            title: 'Could not load progress',
            message: _friendlyProgressError(e),
            icon: Icons.error_outline,
            action: FilledButton(
              onPressed: () {
                ref.invalidate(cmsSentencesLanguagesProvider);
                ref.invalidate(unifiedGroupsProvider((page: 1, search: '')));
              },
              child: const Text('Retry'),
            ),
          ),
          data: (languages) => groupsAsync.when(
            loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
            error: (e, _) => EmptyState(
              title: 'Could not load groups',
              message: _friendlyProgressError(e),
              icon: Icons.error_outline,
              action: FilledButton(
                onPressed: () => ref.invalidate(unifiedGroupsProvider((page: 1, search: ''))),
                child: const Text('Retry'),
              ),
            ),
            data: (result) {
              final languageNames = languages.map((l) => l.name.trim().toLowerCase()).toSet();
              var groups = result.items;
              if (languageNames.isNotEmpty) {
                final related = groups
                    .where((g) => languageNames.contains((g.group.subjectName ?? '').trim().toLowerCase()))
                    .toList();
                if (related.isNotEmpty) groups = related;
              }

              if (groups.isEmpty) {
                return const EmptyState(
                  title: 'No groups',
                  message: 'Create subject groups to view student progress.',
                  icon: Icons.groups_outlined,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in groups) ...[
                    _GroupProgressSection(
                      groupId: item.group.id,
                      fallbackGroupName: item.group.groupName,
                      subjectName: item.group.subjectName ?? '—',
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Loads lessons for each level so the access panel can show exam toggles.
class _PermissionsLevelsLoader extends ConsumerWidget {
  const _PermissionsLevelsLoader({
    required this.group,
    required this.levels,
    required this.busyIds,
    required this.onBack,
    required this.onTogglePractice,
    required this.onToggleExam,
    this.onBulkUnlockLevel,
    this.bulkBusy = false,
    this.showBackButton = true,
  });

  final UnifiedGroupView group;
  final List<CmsLevel> levels;
  final Set<String> busyIds;
  final VoidCallback onBack;
  final Future<void> Function(CmsLevel level, bool unlock) onTogglePractice;
  final Future<void> Function(CmsLesson lesson, bool unlock) onToggleExam;
  final Future<void> Function(CmsLevel level, bool unlock, List<CmsLesson> lessons)? onBulkUnlockLevel;
  final bool bulkBusy;
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsByLevel = <String, List<CmsLesson>>{};
    var stillLoading = false;
    Object? error;

    for (final level in levels) {
      final async = ref.watch(cmsSentencesLessonsProvider(level.id));
      async.when(
        data: (lessons) => lessonsByLevel[level.id] = lessons,
        loading: () => stillLoading = true,
        error: (e, _) => error ??= e,
      );
    }

    if (error != null) {
      return EmptyState(
        title: 'Could not load lessons',
        message: _friendlyProgressError(error!),
        icon: Icons.error_outline,
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
      onBulkUnlockLevel: onBulkUnlockLevel == null
          ? null
          : (level, unlock) => onBulkUnlockLevel!(
                level,
                unlock,
                lessonsByLevel[level.id] ?? const [],
              ),
      onBack: onBack,
      showBackButton: showBackButton,
    );
  }
}

class _GroupProgressSection extends ConsumerWidget {
  const _GroupProgressSection({
    required this.groupId,
    required this.fallbackGroupName,
    required this.subjectName,
  });

  final String groupId;
  final String fallbackGroupName;
  final String subjectName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(groupProgressProvider(groupId));
    return reportAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: LoadingState(kind: LoadingSkeletonKind.card),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: EmptyState(
          title: fallbackGroupName,
          message: _friendlyProgressError(e),
          icon: Icons.lock_outline,
        ),
      ),
      data: (report) => SentencesProgressTable(
        groupName: report.group['groupName'] as String? ?? fallbackGroupName,
        subjectName: subjectName,
        students: report.students,
      ),
    );
  }
}
