import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/attendance.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/identity_provider.dart';
import '../widgets/daily_feedback_widgets.dart';

class DailyFeedbackScreen extends ConsumerStatefulWidget {
  const DailyFeedbackScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<DailyFeedbackScreen> createState() => _DailyFeedbackScreenState();
}

class _DailyFeedbackScreenState extends ConsumerState<DailyFeedbackScreen> {
  FeedbackClassFilter _filter = FeedbackClassFilter.all;
  String _teacherId = 'all';

  FeedbackClassesQuery get _query => (
        scope: _filter == FeedbackClassFilter.today ? 'today' : 'all',
        teacherId: _teacherId,
      );

  void _refresh() {
    ref.invalidate(feedbackClassesProvider(_query));
    ref.invalidate(teachersProvider(const PageMeta(limit: 100, status: 'active')));
  }

  Future<void> _openFeedback(TodayClassSession session, StudentAttendanceRow student) async {
    final saved = await showAddDailyFeedbackDialog(
      context: context,
      session: session,
      student: student,
      onSubmit: ({
        required homework,
        required behavior,
        required participation,
        required isExamDay,
        examPercentage,
        required feedbackDate,
        notes,
      }) async {
        await ref.read(attendanceApiProvider).submitFeedback(
              studentId: student.id,
              classScheduleId: session.schedule.id,
              homework: homework,
              behavior: behavior,
              participation: participation,
              isExamDay: isExamDay,
              examPercentage: examPercentage,
              date: feedbackApiDate(feedbackDate),
              notes: notes,
            );
      },
    );

    if (saved == true && mounted) {
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback submitted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(feedbackClassesProvider(_query));
    final teachersAsync = ref.watch(teachersProvider(const PageMeta(limit: 100, status: 'active')));
    final selectedIndex = widget.navItems.indexWhere((i) => widget.selectedRoute.startsWith(i.route));

    final teachers = teachersAsync.maybeWhen(
      data: (result) {
        final items = result.items
            .where((t) => t.id.isNotEmpty && (t.role == null || t.role != 'founder'))
            .map((t) => (id: t.id, name: t.name))
            .toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return items;
      },
      orElse: () => <({String id, String name})>[],
    );

    return AdaptiveScaffold(
      title: 'Daily Feedback',
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        FilledButton.icon(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh Classes'),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FeedbackControlBar(
              filter: _filter,
              selectedTeacherId: _teacherId,
              teachers: teachers,
              teachersLoading: teachersAsync.isLoading,
              teachersError: teachersAsync.hasError ? teachersAsync.error.toString() : null,
              onRetryTeachers: () => ref.invalidate(teachersProvider(const PageMeta(limit: 100, status: 'active'))),
              onFilterChanged: (f) => setState(() => _filter = f),
              onTeacherChanged: (id) => setState(() => _teacherId = id),
            ),
            if (teachersAsync.hasValue && teachers.isEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'No active teachers found. Add teachers under People first.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              formatFeedbackLongDate(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: AppSpacing.sm),
            classesAsync.when(
              loading: () => const LoadingState(kind: LoadingSkeletonKind.card),
              error: (e, _) => Text(e.toString()),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return EmptyState(
                    title: 'No classes found',
                    message: _teacherId == 'all'
                        ? 'No classes match the selected filter. Try All Classes or another day.'
                        : 'No classes for this teacher with the selected filter. Try All Classes.',
                    icon: Icons.event_busy_outlined,
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900 ? 2 : 1;
                    final spacing = AppSpacing.sm;
                    final rows = <Widget>[];
                    for (var i = 0; i < sessions.length; i += columns) {
                      final slice = sessions.skip(i).take(columns).toList();
                      rows.add(
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var j = 0; j < slice.length; j++) ...[
                              if (j > 0) SizedBox(width: spacing),
                              Expanded(
                                child: ClassFeedbackPanel(
                                  session: slice[j],
                                  onAddFeedback: (student) => _openFeedback(slice[j], student),
                                ),
                              ),
                            ],
                            // Keep row alignment when last row has fewer cards.
                            for (var j = slice.length; j < columns; j++) ...[
                              SizedBox(width: spacing),
                              const Expanded(child: SizedBox.shrink()),
                            ],
                          ],
                        ),
                      );
                      if (i + columns < sessions.length) {
                        rows.add(SizedBox(height: spacing));
                      }
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: rows,
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
}
