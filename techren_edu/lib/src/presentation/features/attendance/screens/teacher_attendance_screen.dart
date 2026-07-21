import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/attendance.dart';
import '../../../providers/attendance_provider.dart';
import '../widgets/student_attendance_widgets.dart';

class TeacherAttendancePage extends ConsumerStatefulWidget {
  const TeacherAttendancePage({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends ConsumerState<TeacherAttendancePage> {
  AttendanceClassFilter _filter = AttendanceClassFilter.all;
  DateTime _selectedDate = DateTime.now();
  String? _expandedClassId;

  bool get _isTeacherRoute => widget.selectedRoute.startsWith('/teacher');
  bool get _isStaffStudentRoute => widget.selectedRoute.contains('/attendance/students');

  String get _pageTitle => _isStaffStudentRoute ? 'Student Attendance' : 'Attendance';

  String get _dateParam {
    final y = _selectedDate.year.toString().padLeft(4, '0');
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  AttendanceClassesQuery get _classesQuery => (
        scope: _filter == AttendanceClassFilter.today ? 'today' : 'all',
        date: _dateParam,
      );

  @override
  Widget build(BuildContext context) {
    final checkInAsync = ref.watch(teacherCheckInProvider);
    final classesAsync = _isStaffStudentRoute || !_isTeacherRoute
        ? ref.watch(attendanceClassesProvider(_classesQuery))
        : ref.watch(todayClassesProvider);
    final selectedIndex = widget.navItems.indexWhere((i) => widget.selectedRoute.startsWith(i.route));

    return AdaptiveScaffold(
      title: _pageTitle,
      selectedIndex: selectedIndex < 0 ? 2 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
            body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teacherCheckInProvider);
          ref.invalidate(todayClassesProvider);
          ref.invalidate(attendanceClassesProvider(_classesQuery));
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            if (_isStaffStudentRoute)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  'Filter classes and mark student attendance',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            if (_isTeacherRoute) ...[
              _CheckInCard(checkInAsync: checkInAsync, onCheckIn: _checkIn, onCheckOut: _checkOut),
              const SizedBox(height: AppSpacing.lg),
            ],
            AttendanceControlBar(
              filter: _filter,
              selectedDate: _selectedDate,
              onFilterChanged: (f) => setState(() => _filter = f),
              onDateChanged: (d) => setState(() {
                _selectedDate = d;
                _filter = AttendanceClassFilter.today;
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            classesAsync.when(
              loading: () => const LoadingState(kind: LoadingSkeletonKind.dashboard),
              error: (e, _) => Padding(
                padding: AppSpacing.pagePaddingWide,
                child: Column(
                  children: [
                    Text(e.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () {
                        ref.invalidate(todayClassesProvider);
                        ref.invalidate(attendanceClassesProvider(_classesQuery));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return EmptyState(
                    title: 'No classes',
                    message: _filter == AttendanceClassFilter.today
                        ? 'No classes are scheduled for ${_formatDate(_selectedDate)}. Try All Classes or another date.'
                        : 'No class schedules found. Create groups with schedules under Groups first.',
                    icon: Icons.event_busy_outlined,
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900 ? 2 : 1;
                    if (columns == 1) {
                      return Column(
                        children: [
                          for (final session in sessions)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: ClassAttendancePanel(
                                session: session,
                                expanded: _expandedClassId == session.schedule.id,
                                onToggle: () => setState(() {
                                  _expandedClassId =
                                      _expandedClassId == session.schedule.id ? null : session.schedule.id;
                                }),
                                onSaveStudent: (studentId, status, _) =>
                                    _saveStudentAttendance(session.schedule.id, studentId, status),
                                onFeedback: _isTeacherRoute
                                    ? (student) => _showFeedback(context, session, student)
                                    : null,
                              ),
                            ),
                        ],
                      );
                    }
                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        for (final session in sessions)
                          SizedBox(
                            width: (constraints.maxWidth - AppSpacing.md) / 2,
                            child: ClassAttendancePanel(
                              session: session,
                              expanded: _expandedClassId == session.schedule.id,
                              onToggle: () => setState(() {
                                _expandedClassId =
                                    _expandedClassId == session.schedule.id ? null : session.schedule.id;
                              }),
                              onSaveStudent: (studentId, status, _) =>
                                  _saveStudentAttendance(session.schedule.id, studentId, status),
                              onFeedback: _isTeacherRoute
                                  ? (student) => _showFeedback(context, session, student)
                                  : null,
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

  String _formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$m/$d/${date.year}';
  }

  Future<void> _checkIn() async {
    await ref.read(attendanceApiProvider).checkIn();
    ref.invalidate(teacherCheckInProvider);
  }

  Future<void> _checkOut() async {
    await ref.read(attendanceApiProvider).checkOut();
    ref.invalidate(teacherCheckInProvider);
  }

  Future<void> _saveStudentAttendance(String scheduleId, String studentId, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(attendanceApiProvider).markAttendance(
            classScheduleId: scheduleId,
            date: _dateParam,
            records: [
              {'studentId': studentId, 'status': status},
            ],
          );
      ref.invalidate(todayClassesProvider);
      ref.invalidate(attendanceClassesProvider(_classesQuery));
      messenger.showSnackBar(const SnackBar(content: Text('Attendance saved')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showFeedback(BuildContext context, TodayClassSession session, StudentAttendanceRow student) async {
    final messenger = ScaffoldMessenger.of(context);
    int homework = 80;
    int behavior = 80;
    int participation = 80;
    bool isExamDay = false;
    int examScore = 0;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Feedback — ${student.name}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _SliderRow(label: 'Homework', value: homework.toDouble(), onChanged: (v) => setSheetState(() => homework = v.round())),
              _SliderRow(label: 'Behavior', value: behavior.toDouble(), onChanged: (v) => setSheetState(() => behavior = v.round())),
              _SliderRow(label: 'Participation', value: participation.toDouble(), onChanged: (v) => setSheetState(() => participation = v.round())),
              SwitchListTile(
                title: const Text('Exam day'),
                value: isExamDay,
                onChanged: (v) => setSheetState(() => isExamDay = v),
              ),
              if (isExamDay)
                _SliderRow(label: 'Exam %', value: examScore.toDouble(), onChanged: (v) => setSheetState(() => examScore = v.round())),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () async {
                  await ref.read(attendanceApiProvider).submitFeedback(
                        studentId: student.id,
                        classScheduleId: session.schedule.id,
                        homework: homework,
                        behavior: behavior,
                        participation: participation,
                        isExamDay: isExamDay,
                        examPercentage: isExamDay ? examScore : null,
                      );
                  if (context.mounted) Navigator.pop(context, true);
                },
                child: const Text('Submit Feedback'),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true) {
      messenger.showSnackBar(const SnackBar(content: Text('Feedback submitted')));
    }
  }
}

class _CheckInCard extends StatelessWidget {
  const _CheckInCard({
    required this.checkInAsync,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  final AsyncValue<TeacherCheckInStatus> checkInAsync;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: checkInAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text(e.toString()),
          data: (status) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Staff Check-in', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(status.isCheckedIn ? 'Checked in' : 'Not checked in yet'),
              if (status.isCheckedOut) const Text('Checked out for today'),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: status.isCheckedIn ? null : onCheckIn,
                      child: const Text('Check In'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: status.isCheckedIn && !status.isCheckedOut ? onCheckOut : null,
                      child: const Text('Check Out'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 20,
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ),
        Text('${value.round()}'),
      ],
    );
  }
}
