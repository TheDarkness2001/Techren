import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_semantic_colors.dart';

import '../../../../core/theme/app_spacing.dart';

import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_hub_card.dart';

import '../../../../core/widgets/common_widgets.dart';

import '../../../../core/widgets/metric_card.dart';

import '../../../../core/widgets/paginated_scroll_body.dart';

import '../../../../domain/entities/parent_portal.dart';

import '../../../providers/parent_provider.dart';



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

              subtitle: 'Status: ${overview.child.status ?? 'active'}',

              accentColor: overview.child.status == 'inactive' ? semantic.textMuted : AppColors.primary,

              icon: Icons.person_outline,

              trailing: const SizedBox.shrink(),

            ),

            const SizedBox(height: AppSpacing.md),

            HubSectionHeader(title: 'Summary'),

            MetricCardGrid(

              children: [

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

  ParentFeedbackQuery get _baseQuery => (studentId: widget.studentId, page: 1, search: _search);



  @override

  void dispose() {

    _searchController.dispose();

    super.dispose();

  }



  void _refresh() => ref.invalidate(parentChildFeedbackProvider(_baseQuery));



  @override

  Widget build(BuildContext context) {

    final baseQuery = _baseQuery;



    return Column(

        children: [

          Padding(

            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),

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

              builder: (context, controller, items, state) => ListView.builder(

                controller: controller,

                padding: const EdgeInsets.all(AppSpacing.md),

                itemCount: items.length,

                itemBuilder: (_, i) => _FeedbackCard(entry: items[i], onSaved: _refresh),

              ),

            ),

          ),

        ],

      );

  }

}



class _FeedbackCard extends ConsumerStatefulWidget {

  const _FeedbackCard({required this.entry, required this.onSaved});



  final ParentFeedbackEntry entry;

  final VoidCallback onSaved;



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

    final subtitle = StringBuffer()

      ..write(f.date)

      ..write('\nHomework ${f.homework}% · Behavior ${f.behavior}% · Participation ${f.participation}%');

    if (f.isExamDay) subtitle.write('\nExam: ${f.examPercentage ?? 0}%');

    if (f.parentComments != null) subtitle.write('\nYour comment: ${f.parentComments}');



    return AppHubCard(

      title: f.className ?? 'Class',

      subtitle: subtitle.toString(),

      accentColor: AppColors.primary,

      icon: Icons.rate_review_outlined,

      trailing: IconButton(

        icon: const Icon(Icons.comment_outlined),

        tooltip: 'Add comment',

        onPressed: _addComment,

      ),

      onTap: _addComment,

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

          return AppHubCard(

            title: a.className ?? 'Class',

            subtitle: a.date,

            accentColor: present ? semantic.success : semantic.warning,

            icon: Icons.event_available_outlined,

            trailing: Chip(

              label: Text(a.status),

              visualDensity: VisualDensity.compact,

              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

            ),

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

