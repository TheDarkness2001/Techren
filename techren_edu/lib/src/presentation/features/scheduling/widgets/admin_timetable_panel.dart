import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../../domain/entities/person.dart';
import '../../../../domain/entities/scheduling.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/identity_provider.dart';
import 'timetable_week_grid.dart';

const _dayOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _dayFullNames = {
  'Mon': 'Monday',
  'Tue': 'Tuesday',
  'Wed': 'Wednesday',
  'Thu': 'Thursday',
  'Fri': 'Friday',
  'Sat': 'Saturday',
  'Sun': 'Sunday',
};

/// Build the filter list from staff + anyone who actually has timetable lessons
/// (founders are excluded from /teachers but may teach classes).
List<Person> teachersForTimetableFilter(TimetableData data, List<Person> staff) {
  final byId = <String, Person>{
    for (final teacher in staff) teacher.id: teacher,
  };

  for (final day in _dayOrder) {
    for (final lesson in data.grid[day] ?? const <TimetableEntry>[]) {
      final id = lesson.teacherId;
      if (id == null || id.isEmpty) continue;
      final existing = byId[id];
      if (existing == null) {
        byId[id] = Person(
          id: id,
          name: (lesson.teacherName?.trim().isNotEmpty == true) ? lesson.teacherName!.trim() : 'Teacher',
          role: 'teacher',
          userType: 'teacher',
        );
      } else if ((existing.name.isEmpty || existing.name == 'Teacher') &&
          lesson.teacherName != null &&
          lesson.teacherName!.trim().isNotEmpty) {
        byId[id] = Person(
          id: existing.id,
          name: lesson.teacherName!.trim(),
          email: existing.email,
          phone: existing.phone,
          status: existing.status,
          role: existing.role,
          displayId: existing.displayId,
          branchId: existing.branchId,
          userType: existing.userType,
          profileImage: existing.profileImage,
          subjects: existing.subjects,
        );
      }
    }
  }

  final list = byId.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return list;
}

/// Admin timetable — teacher filter + one big lesson table (optional week grid).
class AdminTimetablePanel extends ConsumerStatefulWidget {
  const AdminTimetablePanel({super.key, required this.data});

  final TimetableData data;

  @override
  ConsumerState<AdminTimetablePanel> createState() => _AdminTimetablePanelState();
}

class _AdminTimetablePanelState extends ConsumerState<AdminTimetablePanel> {
  String? _selectedTeacherId;
  bool _showWeekGrid = false;

  List<TimetableEntry> _lessonsForTeacher(TimetableData data) {
    final lessons = <TimetableEntry>[];
    for (final day in _dayOrder) {
      lessons.addAll(data.grid[day] ?? []);
    }
    lessons.sort((a, b) {
      final dayCompare = _dayOrder.indexOf(a.day).compareTo(_dayOrder.indexOf(b.day));
      if (dayCompare != 0) return dayCompare;
      return a.startTime.compareTo(b.startTime);
    });
    return lessons;
  }

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(teachersProvider(const PageMeta(limit: 200)));
    final scheme = Theme.of(context).colorScheme;

    return teachersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        title: 'Could not load teachers',
        message: e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
        onRetry: () => ref.invalidate(teachersProvider(const PageMeta(limit: 200))),
      ),
      data: (result) {
        final teachers = teachersForTimetableFilter(widget.data, result.items);
        if (teachers.isEmpty) {
          return const Center(
            child: Text('No teachers with scheduled lessons yet. Create a group schedule from Groups.'),
          );
        }

        final currentUserId = ref.watch(authProvider).user?.id;
        if (_selectedTeacherId == null) {
          final preferred = teachers.where((t) => t.id == currentUserId).firstOrNull;
          _selectedTeacherId = preferred?.id ?? teachers.first.id;
        } else if (!teachers.any((t) => t.id == _selectedTeacherId)) {
          _selectedTeacherId = teachers.first.id;
        }

        final selected = teachers.firstWhere(
          (t) => t.id == _selectedTeacherId,
          orElse: () => teachers.first,
        );
        final filtered = filterTimetableForTeacher(
          widget.data,
          teacherId: selected.id,
          teacherName: selected.name,
        );
        final lessons = _lessonsForTeacher(filtered);

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: [
            _TeacherFilterBar(
              teachers: teachers,
              selectedId: selected.id,
              onChanged: (id) => setState(() => _selectedTeacherId = id),
              showWeekGrid: _showWeekGrid,
              onToggleWeekGrid: (value) => setState(() => _showWeekGrid = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              "${selected.name}'s lessons",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              lessons.isEmpty
                  ? 'No scheduled lessons for this teacher.'
                  : '${lessons.length} lesson${lessons.length == 1 ? '' : 's'} this week',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.semantic.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            _TeacherLessonsTable(lessons: lessons),
            if (_showWeekGrid) ...[
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Weekly grid',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.md),
              TimetableWeekGrid(data: filtered),
            ],
          ],
        );
      },
    );
  }
}

class _TeacherFilterBar extends StatelessWidget {
  const _TeacherFilterBar({
    required this.teachers,
    required this.selectedId,
    required this.onChanged,
    required this.showWeekGrid,
    required this.onToggleWeekGrid,
  });

  final List<Person> teachers;
  final String selectedId;
  final ValueChanged<String?> onChanged;
  final bool showWeekGrid;
  final ValueChanged<bool> onToggleWeekGrid;

  String _teacherLabel(Person teacher) {
    final code = teacher.displayId ?? teacher.id;
    return '$code — ${teacher.name}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: semantic.border),
        boxShadow: AppShadows.card,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 640;
          final filter = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Teacher',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                value: selectedId,
                isExpanded: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
                items: [
                  for (final teacher in teachers)
                    DropdownMenuItem(
                      value: teacher.id,
                      child: Text(_teacherLabel(teacher), overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: onChanged,
              ),
            ],
          );

          final toggle = FilterChip(
            avatar: Icon(
              showWeekGrid ? Icons.grid_on_outlined : Icons.table_rows_outlined,
              size: 18,
              color: showWeekGrid ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
            ),
            label: Text(showWeekGrid ? 'Hide week grid' : 'Show week grid'),
            selected: showWeekGrid,
            onSelected: onToggleWeekGrid,
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                filter,
                const SizedBox(height: AppSpacing.sm),
                toggle,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: filter),
              const SizedBox(width: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: toggle,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TeacherLessonsTable extends StatelessWidget {
  const _TeacherLessonsTable({required this.lessons});

  final List<TimetableEntry> lessons;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;

    if (lessons.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: semantic.border),
        ),
        child: Text(
          'Select another teacher or create a group schedule from Groups.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: semantic.textMuted),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: semantic.border),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - 320),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(semantic.surfaceContainer),
            headingTextStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
            dataTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
            columns: const [
              DataColumn(label: Text('DAY')),
              DataColumn(label: Text('START')),
              DataColumn(label: Text('END')),
              DataColumn(label: Text('CLASS')),
              DataColumn(label: Text('GROUP')),
            ],
            rows: [
              for (final lesson in lessons)
                DataRow(
                  cells: [
                    DataCell(Text(_dayFullNames[lesson.day] ?? lesson.day)),
                    DataCell(Text(lesson.startTime)),
                    DataCell(Text(lesson.endTime)),
                    DataCell(Text(lesson.className, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(lesson.groupName?.isNotEmpty == true ? lesson.groupName! : '—')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple titled timetable for teacher/student views.
class TimetablePanel extends StatelessWidget {
  const TimetablePanel({
    super.key,
    required this.data,
    required this.title,
  });

  final TimetableData data;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.pagePaddingWide,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.lg),
        TimetableWeekGrid(data: data),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
