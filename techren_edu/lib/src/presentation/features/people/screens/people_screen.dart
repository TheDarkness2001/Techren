import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dialogs.dart';
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
  /// Bumped on Refresh / status changes so [PaginatedScrollBody] clears its
  /// accumulated pages and reloads from page 1 (otherwise page N refresh is a no-op).
  int _listEpoch = 0;

  String get _prefix => widget.selectedRoute.startsWith('/founder') ? '/founder' : '/admin';
  bool get _isTeachers => widget.mode == PeopleListMode.teachers;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() => _listEpoch++);
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

  ButtonStyle get _headerButtonStyle => FilledButton.styleFrom(
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        visualDensity: VisualDensity.standard,
      );

  InputDecoration _compactFieldDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 32),
    );
  }

  int _countOf(AsyncValue<PaginatedResult<Person>> async) {
    return async.asData?.value.total ?? async.valueOrNull?.total ?? 0;
  }

  PageMeta _countQuery(PageMeta listQuery, {String? status, bool clearStatus = false}) {
    return PageMeta(
      page: 1,
      limit: 1,
      search: listQuery.search,
      status: clearStatus ? null : (status ?? listQuery.status),
      branchId: listQuery.branchId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
        '${widget.mode}|${listQuery.limit}|${listQuery.search ?? ''}|${listQuery.status ?? ''}|${listQuery.branchId ?? ''}|$_listEpoch';

    final totalQuery = _countQuery(listQuery, clearStatus: true);
    final activeQuery = _countQuery(listQuery, status: 'active');
    final inactiveQuery = _countQuery(listQuery, status: 'inactive');
    final fourthQuery = _isTeachers
        ? _countQuery(listQuery, status: 'on-leave')
        : _countQuery(listQuery, status: 'graduated');

    final totalAsync =
        _isTeachers ? ref.watch(teachersProvider(totalQuery)) : ref.watch(studentsProvider(totalQuery));
    final activeAsync =
        _isTeachers ? ref.watch(teachersProvider(activeQuery)) : ref.watch(studentsProvider(activeQuery));
    final inactiveAsync = _isTeachers
        ? ref.watch(teachersProvider(inactiveQuery))
        : ref.watch(studentsProvider(inactiveQuery));
    final fourthAsync =
        _isTeachers ? ref.watch(teachersProvider(fourthQuery)) : ref.watch(studentsProvider(fourthQuery));

    final total = _countOf(totalAsync);
    final active = _countOf(activeAsync);
    final inactive = _countOf(inactiveAsync);
    final fourth = _countOf(fourthAsync);

    final filterHeader = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeopleFilterCard(
          title: l10n.searchAndFilter,
          child: PeopleFormRow(
            left: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 12, height: 1.2),
              decoration: _compactFieldDecoration(
                label: l10n.search,
                hint: _isTeachers ? l10n.searchNameEmail : l10n.searchNameIdPhone,
                prefixIcon: const Icon(Icons.search, size: 16),
              ),
              onSubmitted: (v) => setState(() => _meta = _meta.copyWith(search: v, page: 1)),
            ),
            right: DropdownButtonFormField<String?>(
              value: _meta.status,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.2),
              decoration: _compactFieldDecoration(label: l10n.status),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.allStatus)),
                DropdownMenuItem(value: 'active', child: Text(l10n.statusActiveLabel)),
                DropdownMenuItem(value: 'inactive', child: Text(l10n.statusInactiveLabel)),
                if (!_isTeachers)
                  DropdownMenuItem(value: 'graduated', child: Text(l10n.statusGraduated)),
                if (_isTeachers)
                  DropdownMenuItem(value: 'on-leave', child: Text(l10n.statusOnLeave)),
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
            (l10n.total, '$total', AppColors.primary),
            (l10n.statusActiveLabel, '$active', context.semantic.success),
            (l10n.statusInactiveLabel, '$inactive', context.semantic.warning),
            if (_isTeachers)
              (l10n.statusOnLeave, '$fourth', AppColors.secondary)
            else
              (l10n.statusGraduated, '$fourth', AppColors.secondary),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );

    return AdaptiveScaffold(
      title: _isTeachers ? l10n.navTeachers : l10n.navStudents,
      selectedIndex: selectedIndex < 0 ? 1 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        if (canManage) ...[
          if (Responsive.isCompact(context))
            IconButton(
              tooltip: l10n.add,
              onPressed: _openAdd,
              icon: const Icon(Icons.add),
            )
          else ...[
            FilledButton.icon(
              onPressed: _openAdd,
              style: _headerButtonStyle,
              icon: const Icon(Icons.add, size: 20),
              label: Text(l10n.add),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
        if (Responsive.isCompact(context))
          IconButton(
            tooltip: l10n.refresh,
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          )
        else
          FilledButton.tonalIcon(
            onPressed: _refresh,
            style: _headerButtonStyle,
            icon: const Icon(Icons.refresh, size: 20),
            label: Text(l10n.refresh),
          ),
      ],
      body: _isTeachers
          ? _TeacherList(
              query: listQuery,
              queryCacheKey: queryCacheKey,
              header: filterHeader,
              onRefresh: _refresh,
              canManageStatus: canManage,
              prefix: _prefix,
              statusColor: _statusColor,
            )
          : _StudentList(
              query: listQuery,
              queryCacheKey: queryCacheKey,
              header: filterHeader,
              onRefresh: _refresh,
              canManageStatus: canManage,
              prefix: _prefix,
              statusColor: _statusColor,
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
    required this.header,
    required this.onRefresh,
    required this.canManageStatus,
    required this.prefix,
    required this.statusColor,
  });

  final PageMeta query;
  final Object queryCacheKey;
  final Widget header;
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
      header: header,
      onInvalidate: (ref, q) => ref.invalidate(studentsProvider(q)),
      itemLabel: context.l10n.itemsStudents,
      initialLoadingKind: LoadingSkeletonKind.table,
      empty: EmptyState(
        title: context.l10n.noStudents,
        message: context.l10n.noStudentsMessage,
        icon: Icons.school_outlined,
      ),
      builder: (context, controller, items, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final useTable = constraints.maxWidth >= 760;
            if (!useTable) {
              return Column(
                children: [
                  for (final person in items)
                    _PersonActions(
                      person: person,
                      onChanged: onRefresh,
                      canManageStatus: canManageStatus,
                      prefix: prefix,
                    ),
                ],
              );
            }
            return _PeopleDataTable(
              people: items,
              onChanged: onRefresh,
              canManageStatus: canManageStatus,
              prefix: prefix,
              statusColor: statusColor,
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
    required this.header,
    required this.onRefresh,
    required this.canManageStatus,
    required this.prefix,
    required this.statusColor,
  });

  final PageMeta query;
  final Object queryCacheKey;
  final Widget header;
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
      header: header,
      onInvalidate: (ref, q) => ref.invalidate(teachersProvider(q)),
      itemLabel: context.l10n.itemsStaff,
      initialLoadingKind: LoadingSkeletonKind.table,
      empty: EmptyState(
        title: context.l10n.noStaff,
        message: context.l10n.noStaffMessage,
        icon: Icons.badge_outlined,
      ),
      builder: (context, controller, items, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final useTable = constraints.maxWidth >= 760;
            if (!useTable) {
              return Column(
                children: [
                  for (final person in items)
                    _PersonActions(
                      person: person,
                      onChanged: onRefresh,
                      canManageStatus: canManageStatus,
                      prefix: prefix,
                    ),
                ],
              );
            }
            return _PeopleDataTable(
              people: items,
              onChanged: onRefresh,
              canManageStatus: canManageStatus,
              isTeacher: true,
              prefix: prefix,
              statusColor: statusColor,
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
    final l10n = context.l10n;
    final semantic = context.semantic;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
        PeopleActionIconButton(
          tooltip: l10n.view,
          icon: Icons.visibility_outlined,
          color: Theme.of(context).colorScheme.primary,
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
            tooltip: l10n.edit,
            icon: Icons.edit_outlined,
            color: Theme.of(context).colorScheme.onSurface,
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
            tooltip: l10n.pay,
            icon: Icons.payments_outlined,
            color: semantic.success,
            onPressed: () => context.go('$prefix/more'),
          ),
        if (canManageStatus)
          PeopleActionIconButton(
            tooltip: person.isActive ? 'Deactivate' : 'Activate',
            icon: person.isActive ? Icons.person_off_outlined : Icons.restart_alt,
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
        if (ref.watch(authProvider).user?.isFounder == true && person.role != 'founder')
          PeopleActionIconButton(
            tooltip: l10n.deletePerson,
            icon: Icons.delete_forever_outlined,
            color: semantic.danger,
            onPressed: () async {
              final ok = await showAppConfirmDialog(
                context: context,
                title: l10n.deletePerson,
                message: person.isStudent
                    ? l10n.deleteStudentConfirm(person.name)
                    : l10n.deleteStaffConfirm(person.name),
                confirmLabel: l10n.deletePerson,
                destructive: true,
              );
              if (!ok) return;
              try {
                final api = ref.read(identityApiProvider);
                if (person.isStudent) {
                  await api.deleteStudent(person.id);
                } else {
                  await api.deleteTeacher(person.id);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.personDeleted(person.name))),
                  );
                }
                onChanged();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
          ),
        ],
      ),
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
      trailing: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _RowActions(
          person: person,
          onChanged: onChanged,
          canManageStatus: canManageStatus,
          prefix: prefix,
        ),
      ),
    );
  }
}
