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

enum PeopleListMode { students, teachers }

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
    this.mode = PeopleListMode.students,
  });

  final List<NavItem> navItems;
  final String selectedRoute;
  final PeopleListMode mode;

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  final _searchController = TextEditingController();
  PageMeta _meta = const PageMeta();

  String get _prefix => widget.selectedRoute.startsWith('/founder') ? '/founder' : '/admin';
  bool get _isTeachers => widget.mode == PeopleListMode.teachers;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (_isTeachers) {
      ref.invalidate(teachersProvider);
    } else {
      ref.invalidate(studentsProvider);
    }
  }

  void _openAdd() {
    context.go(_isTeachers ? '$_prefix/people/add-teacher' : '$_prefix/people/add-student');
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
    final meta = _meta.branchId == branchId
        ? _meta
        : (branchId == null
            ? _meta.copyWith(clearBranchId: true)
            : _meta.copyWith(branchId: branchId));
    if (meta != _meta) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _meta = meta);
      });
    }
    final canManage = _canManageStudents(ref);
    final listQuery = meta.copyWith(page: 1);
    final queryCacheKey =
        '${widget.mode}|${listQuery.limit}|${listQuery.search ?? ''}|${listQuery.status ?? ''}|${listQuery.branchId ?? ''}';

    final statsQuery = listQuery.copyWith(clearStatus: true);
    final allAsync = _isTeachers
        ? ref.watch(teachersProvider(statsQuery))
        : ref.watch(studentsProvider(statsQuery));
    final activeAsync = _isTeachers
        ? ref.watch(teachersProvider(statsQuery.copyWith(status: 'active')))
        : ref.watch(studentsProvider(statsQuery.copyWith(status: 'active')));
    final inactiveAsync = _isTeachers
        ? ref.watch(teachersProvider(statsQuery.copyWith(status: 'inactive')))
        : ref.watch(studentsProvider(statsQuery.copyWith(status: 'inactive')));
    final graduatedAsync =
        _isTeachers ? null : ref.watch(studentsProvider(statsQuery.copyWith(status: 'graduated')));

    final total = allAsync.valueOrNull?.total ?? 0;
    final active = activeAsync.valueOrNull?.total ?? 0;
    final inactive = inactiveAsync.valueOrNull?.total ?? 0;
    final graduated = graduatedAsync?.valueOrNull?.total ?? 0;

    return AdaptiveScaffold(
      title: _isTeachers ? 'Teachers' : 'Students',
      selectedIndex: selectedIndex < 0 ? 1 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, AppSpacing.md, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    if (canManage)
                      FilledButton.icon(
                        onPressed: _openAdd,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.tonalIcon(
                      onPressed: _refresh,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                PeopleFilterCard(
                  title: 'Search & Filter',
                  child: PeopleFormRow(
                    left: TextField(
                      controller: _searchController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        labelText: 'Search',
                        hintText: _isTeachers ? 'Name or email…' : 'Name, ID, phone…',
                        prefixIcon: const Icon(Icons.search, size: 18),
                      ),
                      onSubmitted: (v) => setState(() => _meta = _meta.copyWith(search: v, page: 1)),
                    ),
                    right: DropdownButtonFormField<String?>(
                      value: _meta.status,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        labelText: 'Status',
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Status')),
                        const DropdownMenuItem(value: 'active', child: Text('Active')),
                        const DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                        if (!_isTeachers)
                          const DropdownMenuItem(value: 'graduated', child: Text('Graduated')),
                        if (_isTeachers)
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
                const SizedBox(height: AppSpacing.sm),
                PeopleStatStrip(
                  items: [
                    ('Total', '$total', AppColors.primary),
                    ('Active', '$active', context.semantic.success),
                    ('Inactive', '$inactive', context.semantic.warning),
                    if (!_isTeachers)
                      ('Graduated', '$graduated', AppColors.secondary)
                    else
                      (
                        'Roles',
                        '${allAsync.valueOrNull?.items.map((e) => e.role).toSet().length ?? 0}',
                        AppColors.secondary
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
          Expanded(
            child: _isTeachers
                ? _TeacherList(
                    query: listQuery,
                    queryCacheKey: queryCacheKey,
                    onRefresh: _refresh,
                    canManageStatus: canManage,
                    prefix: _prefix,
                    statusColor: _statusColor,
                  )
                : _StudentList(
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
      empty: const EmptyState(
        title: 'No students',
        message: 'Add your first student to get started.',
        icon: Icons.school_outlined,
      ),
      builder: (context, controller, items, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final useTable = constraints.maxWidth >= 760;
            if (!useTable) {
              return ListView.builder(
                controller: controller,
                padding: const EdgeInsets.only(right: AppSpacing.md),
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
              padding: const EdgeInsets.only(right: AppSpacing.md),
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
      empty: const EmptyState(
        title: 'No staff',
        message: 'Add staff to manage your branch.',
        icon: Icons.badge_outlined,
      ),
      builder: (context, controller, items, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final useTable = constraints.maxWidth >= 760;
            if (!useTable) {
              return ListView.builder(
                controller: controller,
                padding: const EdgeInsets.only(right: AppSpacing.md),
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
              padding: const EdgeInsets.only(right: AppSpacing.md),
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
            ? const ['ID', 'Photo', 'Name', 'Subject(s)', 'Status', 'Role', 'Actions']
            : const ['ID', 'Photo', 'Name', 'Subjects', 'Status', 'Actions'],
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
