import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_semantic_colors.dart';
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
import '../widgets/person_create_dialog.dart';
import '../widgets/person_detail_sheet.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
    this.showTeachers = true,
  });

  final List<NavItem> navItems;
  final String selectedRoute;
  final bool showTeachers;

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  PageMeta _meta = const PageMeta();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.showTeachers ? 2 : 1, vsync: this);
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
    final canManageStatus = _canManageStudents(ref);

    final listQuery = meta.copyWith(page: 1);
    final queryCacheKey = '${listQuery.limit}|${listQuery.search ?? ''}|${listQuery.status ?? ''}|${listQuery.branchId ?? ''}';

    return AdaptiveScaffold(
      title: 'People',
      selectedIndex: selectedIndex < 0 ? 1 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        IconButton(icon: const Icon(Icons.person_add_outlined), onPressed: () => _showCreateDialog(context)),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _meta = _meta.copyWith(search: ''));
                  },
                ),
              ),
              onSubmitted: (v) => setState(() => _meta = _meta.copyWith(search: v)),
            ),
          ),
          if (widget.showTeachers)
            TabBar(
              controller: _tabController,
              tabs: const [Tab(text: 'Students'), Tab(text: 'Teachers')],
            ),
          Expanded(
            child: widget.showTeachers
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _StudentList(
                        query: listQuery,
                        queryCacheKey: queryCacheKey,
                        onRefresh: _refresh,
                        canManageStatus: canManageStatus,
                      ),
                      _TeacherList(
                        query: listQuery,
                        queryCacheKey: queryCacheKey,
                        onRefresh: _refresh,
                        canManageStatus: canManageStatus,
                      ),
                    ],
                  )
                : _StudentList(
                    query: listQuery,
                    queryCacheKey: queryCacheKey,
                    onRefresh: _refresh,
                    canManageStatus: canManageStatus,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final isTeacherTab = widget.showTeachers && _tabController.index == 1;
    final created = await showPersonCreateDialog(context: context, ref: ref, isTeacher: isTeacherTab);
    if (created == true) _refresh();
  }

  bool _canManageStudents(WidgetRef ref) {
    final user = ref.read(authProvider).user;
    final rolePerms = ref.read(platformSettingsProvider).valueOrNull?.rolePermissions[user?.role?.name] ?? {};
    return user?.hasPermission('canManageStudents', rolePerms) ?? false;
  }
}

class _StudentList extends ConsumerWidget {
  const _StudentList({
    required this.query,
    required this.queryCacheKey,
    required this.onRefresh,
    required this.canManageStatus,
  });

  final PageMeta query;
  final Object queryCacheKey;
  final VoidCallback onRefresh;
  final bool canManageStatus;

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
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                itemBuilder: (context, index) => _PersonActions(
                  person: items[index],
                  onChanged: onRefresh,
                  canManageStatus: canManageStatus,
                ),
              );
            }
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _PeopleDataTable(
                  people: items,
                  onChanged: onRefresh,
                  canManageStatus: canManageStatus,
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
  });

  final PageMeta query;
  final Object queryCacheKey;
  final VoidCallback onRefresh;
  final bool canManageStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PaginatedScrollBody<Person, PageMeta>(
      provider: teachersProvider,
      query: query,
      withPage: (q, page) => q.copyWith(page: page),
      queryCacheKey: queryCacheKey,
      onInvalidate: (ref, q) => ref.invalidate(teachersProvider(q)),
      itemLabel: 'teachers',
      initialLoadingKind: LoadingSkeletonKind.table,
      empty: ListView(
        children: const [
          SizedBox(height: AppSpacing.emptyStateTop),
          EmptyState(title: 'No teachers', message: 'Add teachers to manage your branch.'),
        ],
      ),
      builder: (context, controller, items, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final useTable = constraints.maxWidth >= 760;
            if (!useTable) {
              return ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: items.length,
                itemBuilder: (context, index) => _PersonActions(
                  person: items[index],
                  onChanged: onRefresh,
                  canManageStatus: canManageStatus,
                ),
              );
            }
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _PeopleDataTable(
                  people: items,
                  onChanged: onRefresh,
                  canManageStatus: canManageStatus,
                  isTeacher: true,
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
    this.isTeacher = false,
  });

  final List<Person> people;
  final VoidCallback onChanged;
  final bool canManageStatus;
  final bool isTeacher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semantic = context.semantic;

    return AppDataTable(
      columns: const ['Name', 'Email', 'ID', 'Status', ''],
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
              Row(
                children: [
                  PersonAvatar(
                    name: person.name,
                    profileImage: person.profileImage,
                    isActive: person.isActive,
                    isStudent: person.isStudent,
                    radius: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(person.name, overflow: TextOverflow.ellipsis)),
                ],
              ),
              Text(person.email ?? '—', overflow: TextOverflow.ellipsis),
              Text(person.displayId ?? '—'),
              StatusBadge(
                label: person.isActive ? 'Active' : 'Inactive',
                color: person.isActive ? semantic.success : semantic.danger,
              ),
              _PersonRowMenu(person: person, onChanged: onChanged, canManageStatus: canManageStatus),
            ],
          ),
      ],
    );
  }
}

class _PersonRowMenu extends ConsumerWidget {
  const _PersonRowMenu({
    required this.person,
    required this.onChanged,
    required this.canManageStatus,
  });

  final Person person;
  final VoidCallback onChanged;
  final bool canManageStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'toggle' && canManageStatus) {
          final api = ref.read(identityApiProvider);
          final status = person.isActive ? 'inactive' : 'active';
          if (person.isStudent) {
            await api.setStudentStatus(person.id, status);
          } else {
            await api.setTeacherStatus(person.id, status);
          }
          onChanged();
        }
      },
      itemBuilder: (context) => [
        if (canManageStatus)
          PopupMenuItem(
            value: 'toggle',
            child: Text(person.isActive ? 'Deactivate' : 'Activate'),
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
  });

  final Person person;
  final VoidCallback onChanged;
  final bool canManageStatus;

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
      trailing: PopupMenuButton<String>(
        onSelected: (value) async {
          if (value == 'toggle' && canManageStatus) {
            final api = ref.read(identityApiProvider);
            final status = person.isActive ? 'inactive' : 'active';
            if (person.isStudent) {
              await api.setStudentStatus(person.id, status);
            } else {
              await api.setTeacherStatus(person.id, status);
            }
            onChanged();
          }
        },
        itemBuilder: (context) => [
          if (canManageStatus)
            PopupMenuItem(
              value: 'toggle',
              child: Text(person.isActive ? 'Deactivate' : 'Activate'),
            ),
        ],
      ),
    );
  }
}
