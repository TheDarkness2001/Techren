import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/go_back_icon_button.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/paginated_scroll_body.dart';
import '../../../../domain/entities/student_progress.dart';
import '../../../providers/progress_provider.dart';
import '../../../providers/scheduling_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../widgets/student_progress_hub.dart';

class StudentProgressScreen extends ConsumerWidget {
  const StudentProgressScreen({
    super.key,
    this.navItems,
    required this.selectedRoute,
    this.selectedIndex = 3,
  });

  final List<NavItem>? navItems;
  final String selectedRoute;
  final int selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navItems = this.navItems ?? studentNavItemsOf(context);
    final l10n = context.l10n;
    final overviewAsync = ref.watch(studentProgressOverviewProvider);
    final index = navItems.indexWhere((i) => selectedRoute.startsWith(i.route));

    return AdaptiveScaffold(
      title: l10n.navProgress,
      selectedIndex: index >= 0 ? index : selectedIndex,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      actions: [
        IconButton(
          icon: const Icon(Icons.military_tech_outlined),
          tooltip: l10n.xpAchievements,
          onPressed: () => context.go('/student/gamification'),
        ),
        GoBackIconButton(fallbackRoute: '/student/learn'),
      ],
      body: overviewAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.dashboard),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (overview) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studentProgressOverviewProvider);
            ref.invalidate(practiceRecommendationProvider);
          },
          child: ProgressHubBody(
            overview: overview,
            showRecommendation: true,
            onModuleTap: (module) => openStudentLearningModule(context, module),
          ),
        ),
      ),
    );
  }
}

class AdminProgressScreen extends ConsumerStatefulWidget {
  const AdminProgressScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  String get _staffPrefix => selectedRoute.startsWith('/founder') ? '/founder' : '/admin';

  @override
  ConsumerState<AdminProgressScreen> createState() => _AdminProgressScreenState();
}

class _AdminProgressScreenState extends ConsumerState<AdminProgressScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _search = '';
  String? _selectedGroupId;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));

    return AdaptiveScaffold(
      title: 'Student Progress',
      selectedIndex: selectedIndex < 0 ? 1 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
            body: Column(
        children: [
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'All Students'),
              Tab(text: 'By Group'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _AllStudentsTab(
                  staffPrefix: widget._staffPrefix,
                  searchController: _searchController,
                  search: _search,
                  onSearchChanged: (value) => setState(() => _search = value),
                  onSearchCleared: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
                _GroupProgressTab(
                  staffPrefix: widget._staffPrefix,
                  selectedGroupId: _selectedGroupId,
                  onGroupSelected: (groupId) => setState(() => _selectedGroupId = groupId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllStudentsTab extends ConsumerWidget {
  const _AllStudentsTab({
    required this.staffPrefix,
    required this.searchController,
    required this.search,
    required this.onSearchChanged,
    required this.onSearchCleared,
  });

  final String staffPrefix;
  final TextEditingController searchController;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseQuery = (search: search, page: 1);

    return Column(
      children: [
        Padding(
          padding: AppSpacing.pageHeaderPadding,
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Search students',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onSearchCleared,
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: onSearchChanged,
          ),
        ),
        Expanded(
          child: PaginatedScrollBody<StudentProgressSummary, AdminStudentsProgressQuery>(
            provider: adminStudentsProgressProvider,
            query: baseQuery,
            withPage: (q, page) => (search: q.search, page: page),
            queryCacheKey: search,
            onInvalidate: (ref, q) => ref.invalidate(adminStudentsProgressProvider(q)),
            itemLabel: 'students',
            initialLoadingKind: LoadingSkeletonKind.list,
            empty: const EmptyState(
              title: 'No progress data',
              message: 'Student practice activity will appear here.',
              icon: Icons.insights_outlined,
            ),
            builder: (context, controller, items, state) => ListView.builder(
              controller: controller,
              padding: AppSpacing.listGutter,
              itemCount: items.length,
              itemBuilder: (_, i) => _StudentProgressTile(
                student: items[i],
                onTap: () => context.go('$staffPrefix/progress/student/${items[i].studentId}'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupProgressTab extends ConsumerWidget {
  const _GroupProgressTab({
    required this.staffPrefix,
    required this.selectedGroupId,
    required this.onGroupSelected,
  });

  final String staffPrefix;
  final String? selectedGroupId;
  final ValueChanged<String> onGroupSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(examGroupsProvider);

    return groupsAsync.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (groups) {
        if (groups.isEmpty) {
          return const EmptyState(
            title: 'No exam groups',
            message: 'Create exam groups in scheduling to view group progress.',
            icon: Icons.groups_outlined,
          );
        }

        final effectiveGroupId = selectedGroupId ?? groups.first.id;

        return Column(
          children: [
            Padding(
              padding: AppSpacing.pageHeaderPadding,
              child: DropdownButtonFormField<String>(
                value: effectiveGroupId,
                decoration: const InputDecoration(
                  labelText: 'Exam group',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                items: groups
                    .map(
                      (g) => DropdownMenuItem(
                        value: g.id,
                        child: Text('${g.groupName} (${g.studentCount} students)'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onGroupSelected(value);
                },
              ),
            ),
            Expanded(child: _GroupProgressBody(groupId: effectiveGroupId, staffPrefix: staffPrefix)),
          ],
        );
      },
    );
  }
}

class _GroupProgressBody extends ConsumerWidget {
  const _GroupProgressBody({required this.groupId, required this.staffPrefix});

  final String groupId;
  final String staffPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(groupProgressProvider(groupId));

    return reportAsync.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.dashboard),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (report) {
        final aggregate = report.aggregate;
        final groupName = report.group['groupName'] as String? ?? 'Group';

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(groupProgressProvider(groupId)),
          child: ListView(
            padding: AppSpacing.listGutter,
            children: [
              Text(groupName, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AggregateChip(
                    label: 'Students',
                    value: '${aggregate['studentCount'] ?? report.students.length}',
                  ),
                  _AggregateChip(
                    label: 'Avg Words',
                    value: '${aggregate['avgWordsAccuracy'] ?? 0}%',
                  ),
                  _AggregateChip(
                    label: 'Avg Sentences',
                    value: '${aggregate['avgSentencesAccuracy'] ?? 0}%',
                  ),
                  _AggregateChip(
                    label: 'Lessons Passed',
                    value: '${aggregate['totalLessonsPassed'] ?? 0}',
                  ),
                  _AggregateChip(
                    label: 'Total XP',
                    value: '${aggregate['totalXp'] ?? 0}',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Students in group', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              if (report.students.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No students enrolled in this group yet.'),
                )
              else
                ...report.students.map(
                  (s) => _StudentProgressTile(
                    student: s,
                    onTap: () => context.go('$staffPrefix/progress/student/${s.studentId}'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AggregateChip extends StatelessWidget {
  const _AggregateChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      label: Text(label),
    );
  }
}

class _StudentProgressTile extends StatelessWidget {
  const _StudentProgressTile({required this.student, this.onTap});

  final StudentProgressSummary student;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;

    return AppAdminRowCard(
      title: student.name,
      subtitle:
          'Words ${student.wordsAccuracy}% · Sentences ${student.sentencesAccuracy}% · ${student.lessonsPassed} lessons passed',
      icon: Icons.school_outlined,
      onTap: onTap,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Lv ${student.level}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${student.totalXp} XP', style: TextStyle(color: muted, fontSize: 12)),
          if (onTap != null) Icon(Icons.chevron_right, size: 18, color: muted),
        ],
      ),
    );
  }
}

class StaffStudentProgressScreen extends ConsumerStatefulWidget {
  const StaffStudentProgressScreen({
    super.key,
    required this.studentId,
    required this.navItems,
    required this.selectedRoute,
  });

  final String studentId;
  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<StaffStudentProgressScreen> createState() => _StaffStudentProgressScreenState();
}

class _StaffStudentProgressScreenState extends ConsumerState<StaffStudentProgressScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String get _staffPrefix => widget.selectedRoute.startsWith('/founder') ? '/founder' : '/admin';

  void _refresh() {
    ref.invalidate(staffStudentProgressProvider(widget.studentId));
    ref.invalidate(studentVocabLessonsProvider(widget.studentId));
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(staffStudentProgressProvider(widget.studentId));
    final lessonsAsync = ref.watch(studentVocabLessonsProvider(widget.studentId));
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));

    return AdaptiveScaffold(
      title: overviewAsync.maybeWhen(data: (o) => o.student.name, orElse: () => 'Student Progress'),
      selectedIndex: selectedIndex < 0 ? 1 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to list',
          onPressed: () => context.go('$_staffPrefix/progress'),
        ),
      ],
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Vocab Lessons'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                overviewAsync.when(
                  loading: () => const LoadingState(kind: LoadingSkeletonKind.dashboard),
                  error: (e, _) => Center(child: Text(e.toString())),
                  data: (overview) => RefreshIndicator(
                    onRefresh: () async => _refresh(),
                    child: ProgressHubBody(
                      overview: overview,
                      showStudentHeader: true,
                      profileImage: overview.student.profileImage,
                    ),
                  ),
                ),
                lessonsAsync.when(
                  loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
                  error: (e, _) => Center(child: Text(e.toString())),
                  data: (report) => RefreshIndicator(
                    onRefresh: () async => _refresh(),
                    child: StudentVocabLessonsList(lessons: report.lessons),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
