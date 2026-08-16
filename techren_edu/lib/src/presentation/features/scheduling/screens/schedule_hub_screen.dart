import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/paginated_scroll_body.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../../domain/entities/person.dart';
import '../../../../domain/entities/scheduling.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/identity_provider.dart';
import '../../../providers/scheduling_provider.dart';
import '../widgets/admin_timetable_panel.dart';
import '../widgets/scheduling_widgets.dart';

/// Active students available for a group:
/// - exclude inactive students (unless already in [editingGroupId])
/// - exclude students already assigned to another group
List<Person> studentsAvailableForGroup({
  required List<Person> students,
  required List<ExamGroup> groups,
  String? editingGroupId,
  List<ExamGroupMember> currentMembers = const [],
}) {
  final takenElsewhere = <String>{};
  for (final group in groups) {
    if (editingGroupId != null && group.id == editingGroupId) continue;
    for (final member in group.students) {
      takenElsewhere.add(member.id);
    }
  }

  final currentIds = {for (final member in currentMembers) member.id};
  final byId = <String, Person>{
    for (final student in students.where((s) => s.isActive)) student.id: student,
  };

  for (final member in currentMembers) {
    byId.putIfAbsent(
      member.id,
      () => Person(
        id: member.id,
        name: member.name,
        displayId: member.studentCode,
        profileImage: member.profileImage,
        status: 'active',
        userType: 'student',
      ),
    );
  }

  return byId.values
      .where((student) => currentIds.contains(student.id) || !takenElsewhere.contains(student.id))
      .toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

/// Groups management (sidebar "Groups") — create/list class groups.
class GroupsHubScreen extends ConsumerStatefulWidget {
  const GroupsHubScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<GroupsHubScreen> createState() => _GroupsHubScreenState();
}

class _GroupsHubScreenState extends ConsumerState<GroupsHubScreen> {
  String _groupsSearch = '';
  final _groupsSearchController = TextEditingController();

  @override
  void dispose() {
    _groupsSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));
    final baseQuery = (page: 1, search: _groupsSearch);

    return AdaptiveScaffold(
      title: l10n.navGroups,
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        IconButton(icon: const Icon(Icons.add), tooltip: l10n.createGroup, onPressed: () => _showCreateUnified(context)),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: TextField(
              controller: _groupsSearchController,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: l10n.searchGroupsHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _groupsSearch.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _groupsSearchController.clear();
                          setState(() => _groupsSearch = '');
                        },
                      )
                    : null,
                isDense: true,
              ),
              onSubmitted: (value) => setState(() => _groupsSearch = value.trim()),
            ),
          ),
          Expanded(
            child: PaginatedScrollBody<UnifiedGroupView, GroupsQuery>(
              provider: unifiedGroupsProvider,
              query: baseQuery,
              withPage: (q, page) => (page: page, search: q.search),
              queryCacheKey: _groupsSearch,
              onInvalidate: (ref, q) => ref.invalidate(unifiedGroupsProvider(q)),
              itemLabel: l10n.itemsGroups,
              initialLoadingKind: LoadingSkeletonKind.list,
              empty: ListView(
                children: [
                  const SizedBox(height: AppSpacing.emptyStateTop),
                  EmptyState(title: l10n.noGroups, message: l10n.noGroupsMessage),
                ],
              ),
              builder: (context, controller, items, state) => ListView.builder(
                controller: controller,
                padding: AppSpacing.listGutter,
                itemCount: items.length,
                itemBuilder: (_, i) => GroupCard(
                  view: items[i],
                  onEdit: () => _showEditGroup(context, items[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateUnified(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    List<Person> teachers;
    List<Person> students;
    try {
      final teachersResult = await ref.read(teachersProvider(const PageMeta(limit: 100, status: 'active')).future);
      final studentsResult = await ref.read(studentsProvider(const PageMeta(limit: 300, status: 'active')).future);
      final groups = await ref.read(examGroupsProvider.future);
      teachers = teachersResult.items.where((t) => t.isActive).toList();
      students = studentsAvailableForGroup(
        students: studentsResult.items,
        groups: groups,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotLoadPeople('$e'))));
      return;
    }

    if (!context.mounted) return;
    if (teachers.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(context.l10n.createTeacherFirst)));
      return;
    }

    final subjectController = TextEditingController();
    final groupController = TextEditingController();
    final priceController = TextEditingController();
    String? teacherId = teachers.first.id;
    final startController = TextEditingController(text: '10:00');
    final endController = TextEditingController(text: '11:30');
    final selectedDays = <String>{'Mon', 'Wed', 'Fri'};
    final selectedStudentIds = <String>{};

    final created = await showAppDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialog(
          title: context.l10n.createGroup,
          maxWidth: 560,
          content: AppFormColumn(
              children: [
                TextField(controller: subjectController, decoration: InputDecoration(labelText: context.l10n.subjectName)),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: context.l10n.coursePriceMonthlyRequired,
                    hintText: context.l10n.coursePriceHint,
                  ),
                ),
                TextField(controller: groupController, decoration: InputDecoration(labelText: context.l10n.groupName)),
                DropdownButtonFormField<String>(
                  value: teacherId,
                  decoration: InputDecoration(labelText: context.l10n.teacher),
                  items: teachers
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => teacherId = v),
                ),
                TextField(controller: startController, decoration: InputDecoration(labelText: context.l10n.startTime)),
                TextField(controller: endController, decoration: InputDecoration(labelText: context.l10n.endTime)),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: TimetableData.days.map((day) {
                    final selected = selectedDays.contains(day);
                    return FilterChip(
                      label: Text(day),
                      selected: selected,
                      onSelected: (v) => setDialogState(() {
                        if (v) {
                          selectedDays.add(day);
                        } else {
                          selectedDays.remove(day);
                        }
                      }),
                    );
                  }).toList(),
                ),
                Text(context.l10n.navStudents, style: Theme.of(context).textTheme.titleSmall),
                if (students.isEmpty)
                  Text(
                    context.l10n.noAvailableStudents,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                for (final s in students)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: selectedStudentIds.contains(s.id),
                    title: Text(s.name),
                    onChanged: (v) => setDialogState(() {
                      if (v == true) {
                        selectedStudentIds.add(s.id);
                      } else {
                        selectedStudentIds.remove(s.id);
                      }
                    }),
                  ),
              ],
            ),
          actions: [
            AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context, false)),
            AppDialogActions.confirm(
              context,
              label: l10n.create,
              onPressed: () async {
                if (subjectController.text.isEmpty || groupController.text.isEmpty || teacherId == null) return;
                if (selectedDays.isEmpty) return;
                final price = num.tryParse(priceController.text.trim());
                if (price == null || price <= 0) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.enterPriceGreaterThanZero)),
                  );
                  return;
                }
                try {
                  await ref.read(schedulingApiProvider).createUnified(
                        subjectName: subjectController.text.trim(),
                        groupName: groupController.text.trim(),
                        teacherId: teacherId!,
                        scheduledDays: selectedDays.toList(),
                        startTime: startController.text.trim(),
                        endTime: endController.text.trim(),
                        studentIds: selectedStudentIds.toList(),
                        pricePerClass: price,
                      );
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotCreateGroup('$e'))));
                }
              },
            ),
          ],
        ),
      ),
    );

    if (created == true) {
      setState(() {
        _groupsSearch = '';
        _groupsSearchController.clear();
      });
      ref.invalidate(unifiedGroupsProvider);
      ref.invalidate(schedulesProvider);
      ref.invalidate(timetableProvider('admin'));
    }
  }

  Future<void> _showEditGroup(BuildContext context, UnifiedGroupView view) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    List<Person> teachers;
    List<Person> students;
    try {
      final teachersResult = await ref.read(teachersProvider(const PageMeta(limit: 100, status: 'active')).future);
      final studentsResult = await ref.read(studentsProvider(const PageMeta(limit: 300, status: 'active')).future);
      final groups = await ref.read(examGroupsProvider.future);
      teachers = teachersResult.items.where((t) => t.isActive).toList();
      students = studentsAvailableForGroup(
        students: studentsResult.items,
        groups: groups,
        editingGroupId: view.group.id,
        currentMembers: view.group.students,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotLoadPeople('$e'))));
      return;
    }
    if (!context.mounted) return;
    if (teachers.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noTeachersAvailable)));
      return;
    }

    final groupController = TextEditingController(text: view.group.groupName);
    final priceController = TextEditingController(
      text: view.group.pricePerClass > 0 ? '${view.group.pricePerClass}' : '',
    );
    final startController = TextEditingController(text: view.schedule?.startTime ?? '10:00');
    final endController = TextEditingController(text: view.schedule?.endTime ?? '11:30');
    final dayAliases = <String, String>{
      for (final d in TimetableData.days) d: d,
      'Monday': 'Mon',
      'Tuesday': 'Tue',
      'Wednesday': 'Wed',
      'Thursday': 'Thu',
      'Friday': 'Fri',
      'Saturday': 'Sat',
      'Sunday': 'Sun',
    };
    final selectedDays = <String>{
      for (final d in view.schedule?.scheduledDays ?? const <String>[])
        dayAliases[d] ?? (TimetableData.days.contains(d) ? d : d.substring(0, 3)),
    };
    if (selectedDays.isEmpty) selectedDays.addAll(['Mon', 'Wed', 'Fri']);

    String? teacherId = view.schedule?.teacherId ?? teachers.first.id;
    if (!teachers.any((t) => t.id == teacherId)) {
      teacherId = teachers.first.id;
    }
    final selectedStudentIds = <String>{for (final s in view.group.students) s.id};

    final saved = await showAppDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialog(
          title: l10n.editGroup,
          maxWidth: 560,
          content: AppFormColumn(
              children: [
                TextField(controller: groupController, decoration: InputDecoration(labelText: l10n.groupName)),
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.coursePriceMonthly,
                    hintText: l10n.coursePriceHint,
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: teacherId,
                  decoration: InputDecoration(labelText: l10n.teacher),
                  items: teachers
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => teacherId = v),
                ),
                TextField(controller: startController, decoration: InputDecoration(labelText: context.l10n.startTime)),
                TextField(controller: endController, decoration: InputDecoration(labelText: context.l10n.endTime)),
                Wrap(
                  spacing: AppSpacing.xs,
                  children: TimetableData.days.map((day) {
                    final selected = selectedDays.contains(day);
                    return FilterChip(
                      label: Text(day),
                      selected: selected,
                      onSelected: (v) => setDialogState(() {
                        if (v) {
                          selectedDays.add(day);
                        } else {
                          selectedDays.remove(day);
                        }
                      }),
                    );
                  }).toList(),
                ),
                Text(l10n.navStudents, style: Theme.of(context).textTheme.titleSmall),
                if (students.isEmpty)
                  Text(
                    l10n.noAvailableStudents,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                for (final s in students)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: selectedStudentIds.contains(s.id),
                    title: Text(s.name),
                    onChanged: (v) => setDialogState(() {
                      if (v == true) {
                        selectedStudentIds.add(s.id);
                      } else {
                        selectedStudentIds.remove(s.id);
                      }
                    }),
                  ),
              ],
            ),
          actions: [
            AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context, false)),
            AppDialogActions.confirm(
              context,
              label: l10n.save,
              onPressed: () async {
                if (groupController.text.trim().isEmpty || teacherId == null || selectedDays.isEmpty) return;
                final priceText = priceController.text.trim();
                final price = priceText.isEmpty ? null : num.tryParse(priceText);
                if (priceText.isNotEmpty && (price == null || price < 0)) {
                  messenger.showSnackBar(SnackBar(content: Text(l10n.enterValidCoursePrice)));
                  return;
                }
                try {
                  await ref.read(schedulingApiProvider).updateGroup(
                        groupId: view.group.id,
                        groupName: groupController.text.trim(),
                        studentIds: selectedStudentIds.toList(),
                        teacherIds: [teacherId!],
                      );
                  final subjectId = view.group.subjectId;
                  if (subjectId != null && subjectId.isNotEmpty && price != null) {
                    await ref.read(schedulingApiProvider).updateSubject(
                          subjectId: subjectId,
                          pricePerClass: price,
                        );
                  }
                  final scheduleId = view.schedule?.id;
                  if (scheduleId != null && scheduleId.isNotEmpty) {
                    await ref.read(schedulingApiProvider).updateSchedule(
                          scheduleId: scheduleId,
                          teacherId: teacherId,
                          scheduledDays: selectedDays.toList(),
                          startTime: startController.text.trim(),
                          endTime: endController.text.trim(),
                          className: groupController.text.trim(),
                        );
                  }
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotUpdateGroup('$e'))));
                }
              },
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      ref.invalidate(unifiedGroupsProvider);
      ref.invalidate(schedulesProvider);
      ref.invalidate(timetableProvider('admin'));
    }
  }
}

/// Staff timetable — teacher filter + weekly lesson table (no Groups/Schedules tabs).
class ScheduleHubScreen extends ConsumerWidget {
  const ScheduleHubScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedRoute.endsWith('/groups') || selectedRoute.endsWith('/schedules')) {
      return GroupsHubScreen(navItems: navItems, selectedRoute: selectedRoute.contains('/founder') ? '/founder/schedule/groups' : '/admin/schedule/groups');
    }

    final selectedIndex = navItems.indexWhere((r) => selectedRoute.startsWith(r.route) || r.route.contains('/schedule'));
    final timetableIndex = navItems.indexWhere((r) => r.route.endsWith('/timetable'));
    final timetableAsync = ref.watch(timetableProvider('admin'));

    return AdaptiveScaffold(
      title: context.l10n.navTimetable,
      selectedIndex: timetableIndex >= 0 ? timetableIndex : (selectedIndex < 0 ? 0 : selectedIndex),
      selectedRoute: selectedRoute,
      items: navItems,
      onDestinationSelected: (i) => context.go(navItems[i].route),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: context.l10n.refresh,
          onPressed: () => ref.invalidate(timetableProvider('admin')),
        ),
      ],
      body: timetableAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.table),
        error: (e, _) => Center(
          child: Padding(
            padding: AppSpacing.pagePaddingWide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load timetable',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () => ref.invalidate(timetableProvider('admin')),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(timetableProvider('admin')),
          child: AdminTimetablePanel(data: data),
        ),
      ),
    );
  }
}

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({
    super.key,
    required this.type,
    required this.title,
    this.navItems,
    this.selectedRoute,
    this.selectedIndex = 0,
  });

  final String type;
  final String title;
  final List<NavItem>? navItems;
  final String? selectedRoute;
  final int selectedIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetableAsync = ref.watch(timetableProvider(type));
    final userName = ref.watch(authProvider).user?.name;
    final panelTitle = userName != null ? "$userName's Timetable" : title;

    final body = timetableAsync.when(
      loading: () => const LoadingState(message: 'Loading timetable...', kind: LoadingSkeletonKind.table),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (data) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(timetableProvider(type)),
        child: TimetablePanel(data: data, title: panelTitle),
      ),
    );

    if (navItems == null) {
      if (type == 'student') {
        final items = studentNavItemsOf(context);
        return AdaptiveScaffold(
          title: title,
          selectedIndex: selectedIndex,
          selectedRoute: selectedRoute,
          items: items,
          onDestinationSelected: (i) => onStudentNavSelected(context, items, i),
          body: body,
        );
      }
      return Scaffold(appBar: AppBar(title: Text(title)), body: body);
    }

    return AdaptiveScaffold(
      title: title,
      selectedIndex: selectedIndex,
      items: navItems!,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems!, i),
      body: body,
    );
  }
}
