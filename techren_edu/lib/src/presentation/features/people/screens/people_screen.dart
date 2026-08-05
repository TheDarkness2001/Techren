import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/paginated_scroll_body.dart';
import '../../../../core/widgets/person_avatar.dart';
import '../../../../core/widgets/person_tile.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../../domain/entities/person.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/identity_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/staff_branch_provider.dart';
import '../widgets/people_form_widgets.dart';
import '../widgets/person_detail_sheet.dart';
import '../widgets/person_edit_dialog.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
    this.showTeachers = true,
    this.initialTab = 0,
  });

  final List<NavItem> navItems;
  final String selectedRoute;
  final bool showTeachers;
  final int initialTab;

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  PageMeta _meta = const PageMeta();

  String get _prefix => widget.selectedRoute.startsWith('/founder') ? '/founder' : '/admin';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.showTeachers ? 2 : 1,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, widget.showTeachers ? 1 : 0),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    final query = _meta.copyWith(page: 1);
    ref.invalidate(studentsProvider(query));
    if (widget.showTeachers) ref.invalidate(teachersProvider(query));
  }

  void _openAdd() {
    final isTeacherTab = widget.showTeachers && _tabController.index == 1;
    context.go(isTeacherTab ? '$_prefix/people/add-teacher' : '$_prefix/people/add-student');
  }

  Color _statusColor(String status, AppSemanticColors semantic) {
    switch (status) {
      case 'active':
        return semantic.success;
      case 'graduated':
        return AppColors.primary;
      case 'on-leave':
        return semantic.warning;
      default:
        return semantic.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navItems.indexWhere((i) => widget.selectedRoute.startsWith(i.route));
    final branchFilter = ref.watch(staffBranchFilterProvider);
    final branchId = branchFilter == 'all' ? null : branchFilter;
    final meta = _meta.branchId == branchId ? _meta : _meta.copyWith(branchId: branchId);
    if (meta != _meta) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _meta = meta);
      });
    }
    final canManage = _canManageStudents(ref);
    final isStudentsTab = !widget.showTeachers || _tabController.index == 0;
    final listQuery = meta.copyWith(page: 1);
    final queryCacheKey =
        '${listQuery.limit}|${listQuery.search ?? ''}|${listQuery.status ?? ''}|${listQuery.branchId ?? ''}';

    final statsQuery = listQuery.copyWith(clearStatus: true);
    final allAsync = isStudentsTab
        ? ref.watch(studentsProvider(statsQuery))
        : ref.watch(teachersProvider(statsQuery));
    final activeAsync = isStudentsTab
        ? ref.watch(studentsProvider(statsQuery.copyWith(status: 'active')))
        : ref.watch(teachersProvider(statsQuery.copyWith(status: 'active')));
    final inactiveAsync = isStudentsTab
        ? ref.watch(studentsProvider(statsQuery.copyWith(status: 'inactive')))
        : ref.watch(teachersProvider(statsQuery.copyWith(status: 'inactive')));
    final graduatedAsync = isStudentsTab
        ? ref.watch(studentsProvider(statsQuery.copyWith(status: 'graduated')))
        : null;

    final total = allAsync.valueOrNull?.total ?? 0;
    final active = activeAsync.valueOrNull?.total ?? 0;
    final inactive = inactiveAsync.valueOrNull?.total ?? 0;
    final graduated = graduatedAsync?.valueOrNull?.total ?? 0;

    return AdaptiveScaffold(
      title: isStudentsTab ? 'Students' : 'Teachers',
      selectedIndex: selectedIndex < 0 ? 1 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.pagePadding.copyWith(bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isStudentsTab ? 'Students' : 'Teachers',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (canManage)
                      FilledButton.icon(
                        onPressed: _openAdd,
                        icon: const Icon(Icons.add),
                        label: Text(isStudentsTab ? 'Add Student' : 'Add Teacher'),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.tonalIcon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                if (widget.showTeachers) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: AppRadius.card,
                      border: Border.all(color: context.semantic.border),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(icon: Icon(Icons.school_outlined), text: 'Students'),
                        Tab(icon: Icon(Icons.badge_outlined), text: 'Teachers'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                PeopleFilterCard(
                  title: 'Search & Filter',
                  child: PeopleFormRow(
                    left: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search',
                        hintText: isStudentsTab
                            ? 'Search students...'
                            : 'Search teachers by name or email...',
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onSubmitted: (v) => setState(() => _meta = _meta.copyWith(search: v, page: 1)),
                    ),
                    right: DropdownButtonFormField<String?>(
                      value: _meta.status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Status')),
                        const DropdownMenuItem(value: 'active', child: Text('Active')),
                        const DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                        if (isStudentsTab)
                          const DropdownMenuItem(value: 'graduated', child: Text('Graduated')),
                        if (!isStudentsTab)
                          const DropdownMenuItem(value: 'on-leave', child: Text('On leave')),
                      ],
                      onChanged: (v) => setState(() {
                        _meta = v == null
                            ? _meta.copyWith(clearStatus: true, page: 1)
                            : _meta.copyWith(status: v, page: 1);
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PeopleStatStrip(
                  items: [
                    ('Total', '$total', AppColors.primary),
                    ('Active', '$active', context.semantic.success),
                    ('Inactive', '$inactive', context.semantic.warning),
                    if (isStudentsTab)
                      ('Graduated', '$graduated', AppColors.secondary)
                    else
                      (
                        'Roles',
                        '${allAsync.valueOrNull?.items.map((e) => e.role).toSet().length ?? 0}',
                        AppColors.secondary
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          Expanded(
            child: isStudentsTab
                ? _StudentList(
                    query: listQuery,
                    queryCacheKey: queryCacheKey,
                    onRefresh: _refresh,
                    canManageStatus: canManage,
                    prefix: _prefix,
                    statusColor: _statusColor,
                  )
                : _TeacherList(
                    query: listQuery,
                    queryCacheKey: queryCacheKey,
                    onRefresh: _refresh,
                    canManageStatus: canManage,
                    prefix: _prefix,
                    statusColor: _statusColor,
                  ),
          ),
        ],
      ),
    );
  }

  bool _canManageStudents(WidgetRef ref) {
    final user = ref.read(authProvider).user;
    final rolePerms =
        ref.read(platformSettingsProvider).valueOrNull?.rolePermissions[user?.role?.name] ?? {};
    return user?.hasPermission('canManageStudents', rolePerms) ?? false;
  }
}

class _StudentList extends ConsumerWidget {
  const _StudentList({
    required this.query,
    required this.queryCacheKey,
    required this.onRefresh,
    required this.canManageStatus,
    required this.prefix,
    required this.statusColor,
  });

  final PageMeta query;
  final Object queryCacheKey;
  final VoidCallback onRefresh;
  final bool canManageStatus;
  final String prefix;
  final Color Function(String, AppSemanticColors) statusColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PaginatedScrollBody<Person, PageMeta>(
      provider: studentsProvider,
      query: query,
      withPage: (q, page) => q.copyWith(page: page),
      queryCacheKey: queryCacheKey,
      onInvalidate: (ref, q) => ref.invalidate(studentsProvider(q)),
      itemLabel: 'students',
      initialLoadingKind: LoadingSkeletonKind.table,
      empty: ListView(
        children: const [
          SizedBox(height: AppSpacing.emptyStateTop),
          EmptyState(title: 'No students', message: 'Add your first student to get started.'),
        ],
      ),
      builder: (context, controller, items, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final useTable = constraints.maxWidth >= 760;
            if (!useTable) {
              return ListView.builder(
                controller: controller,
                padding: EdgeInsets.zero,
                itemCount: items.length,
                itemBuilder: (context, index) => _PersonActions(
                  person: items[index],
                  onChanged: onRefresh,
                  canManageStatus: canManageStatus,
                  prefix: prefix,
                ),
              );
            }
            return ListView(
              controller: controller,
              children: [
                _PeopleDataTable(
                  people: items,
                  onChanged: onRefresh,
                  canManageStatus: canManageStatus,
                  prefix: prefix,
                  statusColor: statusColor,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TeacherList extends ConsumerWidget {
  const _TeacherList({
    required this.query,
    required this.queryCacheKey,
    required this.onRefresh,
    required this.canManageStatus,
    required this.prefix,
    required this.statusColor,
  });

  final PageMeta query;
  final Object queryCacheKey;
  final VoidCallback onRefresh;
  final bool canManageStatus;
  final String prefix;
  final Color Function(String, AppSemanticColors) statusColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PaginatedScrollBody<Person, PageMeta>(
      provider: teachersProvider,
      query: query,
      withPage: (q, page) => q.copyWith(page: page),
      queryCacheKey: queryCacheKey,
      onInvalidate: (ref, q) => ref.invalidate(teachersProvider(q)),
      itemLabel: 'staff',
      initialLoadingKind: LoadingSkeletonKind.table,
      empty: ListView(
        children: const [
          SizedBox(height: AppSpacing.emptyStateTop),
          EmptyState(title: 'No staff', message: 'Add staff to manage your branch.'),
        ],
      ),
      builder: (context, controller, items, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final useTable = constraints.maxWidth >= 760;
            if (!useTable) {
              return ListView.builder(
                controller: controller,
                itemCount: items.length,
                itemBuilder: (context, index) => _PersonActions(
                  person: items[index],
                  onChanged: onRefresh,
                  canManageStatus: canManageStatus,
                  prefix: prefix,
                ),
              );
            }
            return ListView(
              controller: controller,
              children: [
                _PeopleDataTable(
                  people: items,
                  onChanged: onRefresh,
                  canManageStatus: canManageStatus,
                  isTeacher: true,
                  prefix: prefix,
                  statusColor: statusColor,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PeopleDataTable extends ConsumerWidget {
  const _PeopleDataTable({
    required this.people,
    required this.onChanged,
    required this.canManageStatus,
    required this.prefix,
    required this.statusColor,
    this.isTeacher = false,
  });

  final List<Person> people;
  final VoidCallback onChanged;
  final bool canManageStatus;
  final String prefix;
  final Color Function(String, AppSemanticColors) statusColor;
  final bool isTeacher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semantic = context.semantic;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: semantic.border),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: AppDataTable(
        columns: isTeacher
            ? const ['Teacher ID', 'Photo', 'Name', 'Subject(s)', 'Status', 'Role', 'Actions']
            : const ['Student ID', 'Photo', 'Name', 'Subjects', 'Status', 'Actions'],
        onSelectChanged: (index) => showPersonDetailSheet(
          context: context,
          ref: ref,
          person: people[index],
          onChanged: onChanged,
          canManageStatus: canManageStatus,
        ),
        rows: [
          for (final person in people)
            AppDataRow(
              cells: [
                Text(
                  person.displayId ?? '—',
                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                ),
                PersonAvatar(
                  name: person.name,
                  profileImage: person.profileImage,
                  isActive: person.isActive,
                  isStudent: person.isStudent,
                  radius: 18,
                ),
                Text(person.name, overflow: TextOverflow.ellipsis),
                Text(
                  person.subjects.isEmpty ? '—' : person.subjects.join(', '),
                  overflow: TextOverflow.ellipsis,
                ),
                StatusBadge(
                  label: person.status.toUpperCase(),
                  color: statusColor(person.status, semantic),
                ),
                if (isTeacher)
                  StatusBadge(
                    label: (person.role ?? 'teacher').toUpperCase(),
                    color: AppColors.primary,
                  ),
                _RowActions(
                  person: person,
                  onChanged: onChanged,
                  canManageStatus: canManageStatus,
                  prefix: prefix,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RowActions extends ConsumerWidget {
  const _RowActions({
    required this.person,
    required this.onChanged,
    required this.canManageStatus,
    required this.prefix,
  });

  final Person person;
  final VoidCallback onChanged;
  final bool canManageStatus;
  final String prefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semantic = context.semantic;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PeopleActionIconButton(
          tooltip: 'View',
          icon: Icons.visibility_outlined,
          color: AppColors.primary,
          onPressed: () => showPersonDetailSheet(
            context: context,
            ref: ref,
            person: person,
            onChanged: onChanged,
            canManageStatus: canManageStatus,
          ),
        ),
        if (canManageStatus)
          PeopleActionIconButton(
            tooltip: 'Edit',
            icon: Icons.edit_outlined,
            color: semantic.textMuted,
            onPressed: () async {
              final ok = await showPersonEditDialog(
                context: context,
                ref: ref,
                person: person,
              );
              if (ok == true) onChanged();
            },
          ),
        if (person.isStudent)
          PeopleActionIconButton(
            tooltip: 'Pay',
            icon: Icons.payments_outlined,
            color: semantic.success,
            onPressed: () => context.go('$prefix/more'),
          ),
        if (canManageStatus)
          PeopleActionIconButton(
            tooltip: person.isActive ? 'Deactivate' : 'Activate',
            icon: person.isActive ? Icons.delete_outline : Icons.restart_alt,
            color: semantic.danger,
            onPressed: () async {
              final api = ref.read(identityApiProvider);
              final status = person.isActive ? 'inactive' : 'active';
              if (person.isStudent) {
                await api.setStudentStatus(person.id, status);
              } else {
                await api.setTeacherStatus(person.id, status);
              }
              onChanged();
            },
          ),
      ],
    );
  }
}

class _PersonActions extends ConsumerWidget {
  const _PersonActions({
    required this.person,
    required this.onChanged,
    required this.canManageStatus,
    required this.prefix,
  });

  final Person person;
  final VoidCallback onChanged;
  final bool canManageStatus;
  final String prefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PersonTile(
      person: person,
      onTap: () => showPersonDetailSheet(
        context: context,
        ref: ref,
        person: person,
        onChanged: onChanged,
        canManageStatus: canManageStatus,
      ),
      trailing: _RowActions(
        person: person,
        onChanged: onChanged,
        canManageStatus: canManageStatus,
        prefix: prefix,
      ),
    );
  }
}
