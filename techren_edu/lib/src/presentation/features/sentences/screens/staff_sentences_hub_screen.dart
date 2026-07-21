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
import '../../../providers/learning_cms_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../../providers/scheduling_provider.dart';
import '../../../providers/sentences_provider.dart';
import '../../../providers/words_provider.dart';
import '../../learning/widgets/module_content_manager.dart';
import '../widgets/sentences_hub_widgets.dart';
import '../widgets/sentences_practice_view.dart';

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
  SentencesPracticeStep _practiceStep = SentencesPracticeStep.languages;
  String? _languageId;
  String? _levelId;
  String? _lessonId;
  String? _levelName;
  DateTime? _progressDate;

  /// Permissions: language first, then all related groups.
  String? _permissionsLanguageId;
  String? _permissionsLanguageName;
  final Set<String> _permissionsBusyIds = {};
  /// Which group’s lesson toggles are expanded (null = show group list only).
  String? _permissionsExpandedGroupId;

  void _resetPractice() {
    setState(() {
      _practiceStep = SentencesPracticeStep.languages;
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

  @override
  Widget build(BuildContext context) {
    final languagesAsync = ref.watch(cmsSentencesLanguagesProvider);
    final levelsAsync = _languageId == null ? null : ref.watch(cmsSentencesLevelsProvider(_languageId!));
    final lessonsAsync = _levelId == null ? null : ref.watch(cmsSentencesLessonsProvider(_levelId!));
    final leaderboardAsync = ref.watch(sentencesLeaderboardProvider);
    final groupsAsync = ref.watch(unifiedGroupsProvider((page: 1, search: '')));
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));

    return AdaptiveScaffold(
      title: '',
      selectedIndex: selectedIndex < 0 ? 3 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
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
            const SentencesHubHeader(),
            const SizedBox(height: AppSpacing.md),
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
                  data: (languages) => _buildPracticeTab(languages, levelsAsync, lessonsAsync),
                ),
              SentencesHubTab.leaderboard => leaderboardAsync.when(
                  loading: () => const LoadingState(kind: LoadingSkeletonKind.table),
                  error: (e, _) => Text(e.toString()),
                  data: (board) => SentencesLeaderboardTable(entries: board.leaderboard),
                ),
              SentencesHubTab.lessons => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: ModuleContentManager(module: ContentManagerModule.sentences),
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
    AsyncValue<List<CmsLevel>>? levelsAsync,
    AsyncValue<List<CmsLesson>>? lessonsAsync,
  ) {
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
        if (_practiceStep == SentencesPracticeStep.levels) ...[
          SentencesBackButton(label: 'Back to Languages', onPressed: _resetPractice),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_practiceStep == SentencesPracticeStep.classes) ...[
          SentencesBackButton(
            label: 'Back to Levels',
            onPressed: () => setState(() {
              _practiceStep = SentencesPracticeStep.levels;
              _levelId = null;
              _lessonId = null;
            }),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_practiceStep == SentencesPracticeStep.languages)
          SentencesLanguageGrid(
            languages: languages,
            onLanguageTap: (language) => setState(() {
              _languageId = language.id;
              _practiceStep = SentencesPracticeStep.levels;
            }),
          ),
        if (_practiceStep == SentencesPracticeStep.levels && levelsAsync != null)
          levelsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
            data: (levels) => SentencesLevelGrid(
              levels: levels,
              onLevelTap: (level) => setState(() {
                _levelId = level.id;
                _levelName = level.name;
                _practiceStep = SentencesPracticeStep.classes;
              }),
            ),
          ),
        if (_practiceStep == SentencesPracticeStep.classes && lessonsAsync != null)
          lessonsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
            data: (lessons) => SentencesClassGrid(
              levelName: _levelName ?? 'Level',
              lessons: lessons,
              onLessonTap: (lesson) => setState(() {
                _lessonId = lesson.id;
                _practiceStep = SentencesPracticeStep.practice;
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildPermissionsTab(
    List<UnifiedGroupView> items,
    AsyncValue<List<LearningLanguage>> languagesAsync,
  ) {
    return languagesAsync.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
      error: (e, _) => Text(e.toString()),
      data: (languages) {
        if (_permissionsLanguageId == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SentencesSubNavBar(label: 'Subject'),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Choose a language / subject',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              SentencesLanguageGrid(
                languages: languages,
                onLanguageTap: (language) => setState(() {
                  _permissionsLanguageId = language.id;
                  _permissionsLanguageName = language.name;
                  _permissionsExpandedGroupId = null;
                }),
              ),
            ],
          );
        }

        final relatedGroups = _groupsForSubject(items, _permissionsLanguageName);
        final levelsAsync = ref.watch(cmsSentencesLevelsProvider(_permissionsLanguageId!));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SentencesBackButton(
              label: 'Back to Languages',
              onPressed: _resetPermissions,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Groups for ${_permissionsLanguageName ?? 'subject'}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Unlock or lock sentence lessons for each group below.',
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
                        _PermissionsLevelsLoader(
                          group: item,
                          levels: levels,
                          busyIds: _permissionsBusyIds,
                          onBack: () => setState(() => _permissionsExpandedGroupId = null),
                          onTogglePractice: (level, unlock) =>
                              _togglePractice(level, unlock, item.group.id),
                          onToggleExam: (lesson, unlock) =>
                              _toggleExam(lesson, unlock, item.group.id),
                          showBackButton: false,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
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
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text(e.toString()),
          data: (languages) => groupsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
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
    this.showBackButton = true,
  });

  final UnifiedGroupView group;
  final List<CmsLevel> levels;
  final Set<String> busyIds;
  final VoidCallback onBack;
  final Future<void> Function(CmsLevel level, bool unlock) onTogglePractice;
  final Future<void> Function(CmsLesson lesson, bool unlock) onToggleExam;
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

    if (error != null) return Text(error.toString());
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
      onTogglePractice: onTogglePractice,
      onToggleExam: onToggleExam,
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
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => Text(e.toString()),
      data: (report) => SentencesProgressTable(
        groupName: report.group['groupName'] as String? ?? fallbackGroupName,
        subjectName: subjectName,
        students: report.students,
      ),
    );
  }
}
