import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../providers/attendance_provider.dart';
import '../widgets/teacher_attendance_widgets.dart';

class StaffTeacherAttendanceScreen extends ConsumerStatefulWidget {
  const StaffTeacherAttendanceScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<StaffTeacherAttendanceScreen> createState() => _StaffTeacherAttendanceScreenState();
}

class _StaffTeacherAttendanceScreenState extends ConsumerState<StaffTeacherAttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedRole = 'all';

  TeacherRosterQuery get _query => (
        date: teacherAttendanceApiDate(_selectedDate),
        role: _selectedRole,
      );

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(teacherAttendanceRosterProvider(_query));
    final selectedIndex = widget.navItems.indexWhere((i) => widget.selectedRoute.startsWith(i.route));

    return AdaptiveScaffold(
      title: 'Teacher Attendance',
      selectedIndex: selectedIndex < 0 ? 2 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
            body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(teacherAttendanceRosterProvider(_query)),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Text(
              formatTeacherAttendanceLongDate(_selectedDate),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: AppSpacing.md),
            TeacherAttendanceFilterBar(
              selectedDate: _selectedDate,
              selectedRole: _selectedRole,
              onDateChanged: (d) => setState(() => _selectedDate = d),
              onRoleChanged: (r) => setState(() => _selectedRole = r),
            ),
            const SizedBox(height: AppSpacing.lg),
            rosterAsync.when(
              loading: () => const LoadingState(kind: LoadingSkeletonKind.dashboard),
              error: (e, _) => Text(e.toString()),
              data: (teachers) {
                if (teachers.isEmpty) {
                  return const EmptyState(
                    title: 'No teachers',
                    message: 'No teachers match the selected filters.',
                    icon: Icons.people_outline,
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1100
                        ? 3
                        : constraints.maxWidth >= 720
                            ? 2
                            : 1;
                    final spacing = AppSpacing.md;
                    final cardWidth = columns == 1
                        ? constraints.maxWidth
                        : (constraints.maxWidth - spacing * (columns - 1)) / columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final teacher in teachers)
                          SizedBox(
                            width: cardWidth,
                            child: TeacherAttendanceCard(
                              teacher: teacher,
                              onSave: (status, notes) => _saveTeacher(teacher.id, status, notes),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTeacher(String teacherId, String status, String? notes) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(attendanceApiProvider).markTeacherAttendance(
            teacherId: teacherId,
            date: _query.date,
            dailyStatus: status,
            notes: notes,
          );
      ref.invalidate(teacherAttendanceRosterProvider(_query));
      messenger.showSnackBar(const SnackBar(content: Text('Attendance saved')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
