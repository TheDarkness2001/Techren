import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/error_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/format_money.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/feedback_list_widgets.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/paginated_scroll_body.dart';
import '../../../../domain/entities/parent_portal.dart';
import '../../../providers/parent_provider.dart';
import '../../scheduling/widgets/admin_timetable_panel.dart';



class ParentOverviewTab extends ConsumerWidget {
  const ParentOverviewTab({super.key, required this.studentId, required this.onRefresh});

  final String studentId;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(parentChildOverviewProvider(studentId));
    final semantic = context.semantic;

    return overviewAsync.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.dashboard),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (overview) => RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppHubCard(
              title: overview.child.name,
              subtitle: [
                if (overview.child.studentCode != null) 'ID ${overview.child.studentCode}',
                'Status: ${overview.child.status ?? 'active'}',
              ].join(' · '),
              accentColor: overview.child.status == 'inactive' ? semantic.textMuted : AppColors.primary,
              icon: Icons.person_outline,
              trailing: const SizedBox.shrink(),
            ),
            if (overview.alerts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              HubSectionHeader(title: 'Alerts'),
              for (final alert in overview.alerts.take(6))
                Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ListTile(
                    leading: Icon(
                      alert.type == 'payment'
                          ? Icons.payments_outlined
                          : alert.type == 'attendance'
                              ? Icons.event_busy_outlined
                              : Icons.rate_review_outlined,
                      color: alert.severity == 'high'
                          ? semantic.danger
                          : alert.severity == 'medium'
                              ? semantic.warning
                              : AppColors.primary,
                    ),
                    title: Text(alert.title),
                    subtitle: Text(alert.body),
                    onTap: () {
                      if (alert.type == 'payment') {
                        context.go('/parent/child/$studentId/payments');
                      } else if (alert.type == 'attendance') {
                        context.go('/parent/child/$studentId/attendance');
                      } else if (alert.type == 'feedback') {
                        context.go('/parent/child/$studentId/feedback');
                      }
                    },
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.md),
            HubSectionHeader(title: 'Summary'),
            MetricCardGrid(
              children: [
                MetricCard(
                  label: 'Remaining',
                  value: (overview.summary.payments?.amountRemaining ?? 0).toStringAsFixed(0),
                  subtitle: overview.summary.payments?.overallStatus ?? 'paid',
                  icon: Icons.payments_outlined,
                  accentColor: (overview.summary.payments?.amountRemaining ?? 0) > 0
                      ? semantic.warning
                      : semantic.success,
                ),
                MetricCard(
                  label: 'Feedback',
                  value: '${overview.summary.feedbackCount}',
                  icon: Icons.rate_review_outlined,
                  accentColor: AppColors.primary,
                ),
                MetricCard(
                  label: 'Present',
                  value: '${overview.summary.attendance.present}',
                  subtitle: '${overview.summary.attendance.absent} absent',
                  icon: Icons.fact_check_outlined,
                  accentColor: semantic.success,
                ),
                MetricCard(
                  label: 'Exams',
                  value: '${overview.summary.examCount}',
                  icon: Icons.quiz_outlined,
                  accentColor: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            HubSectionHeader(title: context.l10n.navMore),
            AppHubCard(
              title: context.l10n.childSchedule,
              subtitle: context.l10n.childScheduleHint,
              accentColor: AppColors.primary,
              icon: Icons.calendar_month_outlined,
              onTap: () => context.go('/parent/child/$studentId/schedule'),
            ),
            AppHubCard(
              title: context.l10n.navHomework,
              subtitle: context.l10n.childHomeworkHint,
              accentColor: AppColors.secondary,
              icon: Icons.menu_book_outlined,
              onTap: () => context.go('/parent/child/$studentId/homework'),
            ),
            AppHubCard(
              title: context.l10n.navMessages,
              subtitle: context.l10n.parentMessagesHint,
              accentColor: AppColors.primary,
              icon: Icons.chat_outlined,
              onTap: () => context.go('/parent/messages'),
            ),
          ],
        ),
      ),
    );
  }
}

class ParentPaymentsTab extends ConsumerWidget {
  const ParentPaymentsTab({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(parentChildPaymentsProvider(studentId));
    final semantic = context.semantic;
    return async.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (page) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(parentChildPaymentsProvider(studentId)),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppHubCard(
              title: page.isPaid ? 'Fees are paid' : 'Payment remaining',
              subtitle: '${page.month}/${page.year} · ${page.overallStatus}',
              accentColor: page.isPaid ? semantic.success : semantic.warning,
              icon: Icons.payments_outlined,
              trailing: Text(
                page.amountRemaining.toStringAsFixed(0),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            HubSectionHeader(title: 'This month'),
            ListTile(
              title: const Text('Amount due'),
              trailing: Text(page.amountDue.toStringAsFixed(0)),
            ),
            ListTile(
              title: const Text('Amount paid'),
              trailing: Text(page.amountPaid.toStringAsFixed(0)),
            ),
            ListTile(
              title: const Text('Remaining'),
              trailing: Text(
                page.amountRemaining.toStringAsFixed(0),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: page.amountRemaining > 0 ? semantic.warning : semantic.success,
                ),
              ),
            ),
            if (page.courses.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              HubSectionHeader(title: 'Courses'),
              for (final c in page.courses)
                ListTile(
                  title: Text(c.subject.isEmpty ? 'Course' : c.subject),
                  subtitle: Text(c.status),
                  trailing: Text('${formatUzs(c.amountPaid)} / ${formatUzs(c.amountDue)}'),
                ),
            ],
            if (page.recentPayments.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              HubSectionHeader(title: 'Recent payments'),
              for (final p in page.recentPayments)
                ListTile(
                  title: Text(p.subject?.isNotEmpty == true ? p.subject! : (p.paymentType ?? 'Payment')),
                  subtitle: Text(p.status),
                  trailing: Text(p.amount.toStringAsFixed(0)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}



class ParentFeedbackTab extends ConsumerStatefulWidget {

  const ParentFeedbackTab({super.key, required this.studentId});



  final String studentId;



  @override

  ConsumerState<ParentFeedbackTab> createState() => _ParentFeedbackTabState();

}



class _ParentFeedbackTabState extends ConsumerState<ParentFeedbackTab> {
  String _search = '';
  final _searchController = TextEditingController();
  final List<FeedbackInsightPoint> _loadedPoints = [];

  ParentFeedbackQuery get _baseQuery => (studentId: widget.studentId, page: 1, search: _search);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => ref.invalidate(parentChildFeedbackProvider(_baseQuery));

  void _openInsights() {
    showFeedbackInsightsSheet(
      context: context,
      title: 'Feedback insights',
      points: List.of(_loadedPoints),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseQuery = _baseQuery;

    return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search feedback by class or date',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                      isDense: true,
                    ),
                    onSubmitted: (value) => setState(() => _search = value.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _loadedPoints.isEmpty ? null : _openInsights,
                  icon: const Icon(Icons.insights_outlined, size: 18),
                  label: const Text('More'),
                ),
              ],
            ),
          ),
          Expanded(
            child: PaginatedScrollBody<ParentFeedbackEntry, ParentFeedbackQuery>(
              provider: parentChildFeedbackProvider,
              query: baseQuery,
              withPage: (q, page) => (studentId: q.studentId, page: page, search: q.search),
              queryCacheKey: '${widget.studentId}|$_search',
              onInvalidate: (ref, q) => ref.invalidate(parentChildFeedbackProvider(q)),
              itemLabel: 'entries',
              initialLoadingKind: LoadingSkeletonKind.list,
              empty: ListView(
                children: const [
                  SizedBox(height: AppSpacing.xxl),
                  EmptyState(
                    title: 'No feedback yet',
                    message: 'Teacher comments will appear here after class sessions.',
                    icon: Icons.rate_review_outlined,
                  ),
                ],
              ),
              builder: (context, controller, items, state) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final next = [
                    for (final f in items)
                      FeedbackInsightPoint(
                        id: f.id,
                        className: f.className ?? 'Class',
                        date: f.date,
                        createdAt: f.createdAt,
                        isEnglish: f.isEnglishMetrics,
                        homework: f.homework,
                        words: f.words,
                        sentence: f.sentence,
                        behavior: f.behavior,
                        participation: f.participation,
                      ),
                  ];
                  final changed = next.length != _loadedPoints.length ||
                      (next.isNotEmpty &&
                          _loadedPoints.isNotEmpty &&
                          next.first.id != _loadedPoints.first.id);
                  if (changed && mounted) {
                    setState(() {
                      _loadedPoints
                        ..clear()
                        ..addAll(next);
                    });
                  }
                });
                return ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _FeedbackCard(
                    entry: items[i],
                    onSaved: _refresh,
                    onMore: _openInsights,
                  ),
                );
              },
            ),
          ),
        ],
      );
  }
}



class _FeedbackCard extends ConsumerStatefulWidget {

  const _FeedbackCard({required this.entry, required this.onSaved, this.onMore});

  final ParentFeedbackEntry entry;

  final VoidCallback onSaved;
  final VoidCallback? onMore;



  @override

  ConsumerState<_FeedbackCard> createState() => _FeedbackCardState();

}



class _FeedbackCardState extends ConsumerState<_FeedbackCard> {

  Future<void> _addComment() async {

    final ctrl = TextEditingController(text: widget.entry.parentComments ?? '');

    final saved = await showAppDialog<bool>(

      context: context,

      builder: (context) => AppDialog(

        title: 'Parent comment',

        icon: Icons.comment_outlined,

        content: TextField(

          controller: ctrl,

          maxLines: 3,

          decoration: const InputDecoration(hintText: 'Write a note for the teacher'),

        ),

        actions: [

          AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context, false)),

          AppDialogActions.confirm(context, label: 'Save', onPressed: () => Navigator.pop(context, true)),

        ],

      ),

    );



    if (saved != true || !mounted) return;



    try {

      await ref.read(parentApiProvider).addParentComment(widget.entry.id, ctrl.text.trim());

      widget.onSaved();

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));

      }

    }

  }



  @override
  Widget build(BuildContext context) {
    final f = widget.entry;
    final summary = f.isEnglishMetrics
        ? FeedbackScoreSummary(
            isEnglish: true,
            primaryLabel: 'Words',
            primaryValue: f.words,
            secondaryLabel: 'Sentence',
            secondaryValue: f.sentence,
            behavior: f.behavior,
            participation: f.participation,
            isExamDay: f.isExamDay,
            examPercentage: f.examPercentage,
          )
        : FeedbackScoreSummary(
            isEnglish: false,
            primaryLabel: 'Homework',
            primaryValue: f.homework,
            behavior: f.behavior,
            participation: f.participation,
            isExamDay: f.isExamDay,
            examPercentage: f.examPercentage,
          );

    return FeedbackListCard(
      title: f.className ?? 'Class',
      classDateLabel: formatFeedbackClassDate(f.date),
      submittedAtLabel: formatFeedbackSubmittedAt(f.createdAt),
      teacherName: f.teacherName,
      summary: summary,
      footer: f.parentComments != null && f.parentComments!.isNotEmpty
          ? 'Your comment: ${f.parentComments}'
          : (f.notes != null && f.notes!.isNotEmpty ? f.notes : null),
      trailing: IconButton(
        tooltip: 'Add comment',
        onPressed: _addComment,
        icon: const Icon(Icons.comment_outlined),
      ),
      onMore: widget.onMore,
    );
  }
}

class ParentAttendanceTab extends ConsumerStatefulWidget {

  const ParentAttendanceTab({super.key, required this.studentId});



  final String studentId;



  @override

  ConsumerState<ParentAttendanceTab> createState() => _ParentAttendanceTabState();

}



class _ParentAttendanceTabState extends ConsumerState<ParentAttendanceTab> {
  ParentAttendanceQuery get _baseQuery => (studentId: widget.studentId, page: 1);

  Future<void> _explainAbsence(ParentAttendanceEntry a) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Explain absence'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Why was the student absent on ${a.date}?',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send to teacher')),
        ],
      ),
    );
    final reason = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || reason.length < 3 || !mounted) return;
    try {
      await ref.read(parentApiProvider).submitAbsenceExcuse(widget.studentId, a.id, reason);
      ref.invalidate(parentChildAttendanceProvider(_baseQuery));
      ref.invalidate(parentChildOverviewProvider(widget.studentId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excuse sent to the teacher')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseQuery = _baseQuery;
    final semantic = context.semantic;

    return PaginatedScrollBody<ParentAttendanceEntry, ParentAttendanceQuery>(
      provider: parentChildAttendanceProvider,
      query: baseQuery,
      withPage: (q, page) => (studentId: q.studentId, page: page),
      queryCacheKey: widget.studentId,
      onInvalidate: (ref, q) => ref.invalidate(parentChildAttendanceProvider(q)),
      itemLabel: 'records',
      initialLoadingKind: LoadingSkeletonKind.list,
      empty: ListView(
        children: const [
          SizedBox(height: AppSpacing.xxl),
          EmptyState(
            title: 'No attendance records',
            message: 'Attendance will appear here once classes are marked.',
            icon: Icons.fact_check_outlined,
          ),
        ],
      ),
      builder: (context, controller, items, state) => ListView.builder(
        controller: controller,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final a = items[i];
          final present = a.status.toLowerCase() == 'present';
          final absent = a.status.toLowerCase() == 'absent';
          return Column(
            children: [
              AppHubCard(
                title: a.className ?? 'Class',
                subtitle: [
                  a.date,
                  if (a.teacherName != null && a.teacherName!.isNotEmpty) a.teacherName!,
                  if (a.excuseSubmittedAt != null) 'Excuse sent',
                ].join(' · '),
                accentColor: present
                    ? semantic.success
                    : absent
                        ? semantic.danger
                        : semantic.warning,
                icon: Icons.event_available_outlined,
                trailing: Chip(
                  label: Text(a.status),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              if (a.canSubmitExcuse)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _explainAbsence(a),
                      icon: const Icon(Icons.mail_outline, size: 18),
                      label: const Text('Explain absence'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}



class ParentExamsTab extends ConsumerStatefulWidget {

  const ParentExamsTab({super.key, required this.studentId});



  final String studentId;



  @override

  ConsumerState<ParentExamsTab> createState() => _ParentExamsTabState();

}



class _ParentExamsTabState extends ConsumerState<ParentExamsTab> {

  ParentExamsQuery get _baseQuery => (studentId: widget.studentId, page: 1);



  @override

  Widget build(BuildContext context) {

    final baseQuery = _baseQuery;

    final semantic = context.semantic;



    return PaginatedScrollBody<ParentExamEntry, ParentExamsQuery>(

      provider: parentChildExamsProvider,

      query: baseQuery,

      withPage: (q, page) => (studentId: q.studentId, page: page),

      queryCacheKey: widget.studentId,

      onInvalidate: (ref, q) => ref.invalidate(parentChildExamsProvider(q)),

      itemLabel: 'exams',

      initialLoadingKind: LoadingSkeletonKind.list,

      empty: ListView(

        children: const [

          SizedBox(height: AppSpacing.xxl),

          EmptyState(

            title: 'No exams yet',

            message: 'Exam results will appear here when they are published.',

            icon: Icons.quiz_outlined,

          ),

        ],

      ),

      builder: (context, controller, items, state) => ListView.builder(

        controller: controller,

        padding: const EdgeInsets.all(AppSpacing.md),

        itemCount: items.length,

        itemBuilder: (_, i) {

          final e = items[i];

          return AppHubCard(

            title: e.examName,

            subtitle: '${e.subject ?? ''} · ${e.status ?? ''}',

            accentColor: e.passed ? semantic.success : AppColors.primary,

            icon: Icons.quiz_outlined,

            trailing: Text(

              e.marksObtained != null ? '${e.marksObtained}' : '—',

              style: Theme.of(context).textTheme.titleSmall?.copyWith(

                    fontWeight: FontWeight.w600,

                    color: e.passed ? semantic.success : null,

                  ),

            ),

          );

        },

      ),

    );

  }

}

class ParentScheduleTab extends ConsumerWidget {
  const ParentScheduleTab({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(parentChildScheduleProvider(studentId));
    return async.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.dashboard),
      error: (e, _) => Center(child: Text(localizedError(e, l10n))),
      data: (data) {
        if (data.total == 0 && data.grid.values.every((day) => day.isEmpty)) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(parentChildScheduleProvider(studentId)),
            child: ListView(
              children: [
                const SizedBox(height: AppSpacing.xxl),
                EmptyState(
                  title: l10n.childSchedule,
                  message: l10n.noLessonsThisWeek,
                  icon: Icons.calendar_month_outlined,
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(parentChildScheduleProvider(studentId)),
          child: TimetablePanel(data: data, title: l10n.childSchedule),
        );
      },
    );
  }
}

class ParentHomeworkTab extends ConsumerWidget {
  const ParentHomeworkTab({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final semantic = context.semantic;
    final async = ref.watch(parentChildHomeworkProvider(studentId));
    return async.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.dashboard),
      error: (e, _) => Center(child: Text(localizedError(e, l10n))),
      data: (progress) {
        if (progress.totalAttempts == 0) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(parentChildHomeworkProvider(studentId)),
            child: ListView(
              children: [
                const SizedBox(height: AppSpacing.xxl),
                EmptyState(
                  title: l10n.navHomework,
                  message: l10n.noHomeworkYet,
                  icon: Icons.menu_book_outlined,
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(parentChildHomeworkProvider(studentId)),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              HubSectionHeader(title: l10n.navHomework),
              MetricCardGrid(
                children: [
                  MetricCard(
                    label: l10n.homeworkAttempts,
                    value: '${progress.totalAttempts}',
                    icon: Icons.replay_outlined,
                    accentColor: AppColors.primary,
                  ),
                  MetricCard(
                    label: l10n.homeworkCorrect,
                    value: '${progress.correctAnswers}',
                    icon: Icons.check_circle_outline,
                    accentColor: semantic.success,
                  ),
                  MetricCard(
                    label: l10n.homeworkAccuracy,
                    value: '${progress.accuracy}%',
                    icon: Icons.insights_outlined,
                    accentColor: AppColors.secondary,
                  ),
                  MetricCard(
                    label: 'EN → UZ',
                    value: '${progress.enToUzAccuracy}%',
                    icon: Icons.translate_outlined,
                    accentColor: AppColors.primary,
                  ),
                  MetricCard(
                    label: 'UZ → EN',
                    value: '${progress.uzToEnAccuracy}%',
                    icon: Icons.translate_outlined,
                    accentColor: AppColors.secondary,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

