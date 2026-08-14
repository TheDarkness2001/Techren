import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/feedback_list_widgets.dart';
import '../../../../core/widgets/paginated_scroll_body.dart';
import '../../../../domain/entities/attendance.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';

class StudentFeedbackScreen extends ConsumerStatefulWidget {
  const StudentFeedbackScreen({
    super.key,
    this.navItems,
    required this.selectedRoute,
    required this.selectedIndex,
  });

  final List<NavItem>? navItems;
  final String selectedRoute;
  final int selectedIndex;

  @override
  ConsumerState<StudentFeedbackScreen> createState() => _StudentFeedbackScreenState();
}

class _StudentFeedbackScreenState extends ConsumerState<StudentFeedbackScreen> {
  String _search = '';
  final _searchController = TextEditingController();
  final List<FeedbackInsightPoint> _loadedPoints = [];

  FeedbackQuery _baseQuery(String? studentId) => (studentId: studentId, page: 1, search: _search);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  FeedbackScoreSummary _summary(FeedbackEntry f) {
    if (f.isEnglishMetrics) {
      return FeedbackScoreSummary(
        isEnglish: true,
        primaryLabel: 'Words',
        primaryValue: f.words,
        secondaryLabel: 'Sentence',
        secondaryValue: f.sentence,
        behavior: f.behavior,
        participation: f.participation,
        isExamDay: f.isExamDay,
        examPercentage: f.examPercentage,
      );
    }
    return FeedbackScoreSummary(
      isEnglish: false,
      primaryLabel: 'Homework',
      primaryValue: f.homework,
      behavior: f.behavior,
      participation: f.participation,
      isExamDay: f.isExamDay,
      examPercentage: f.examPercentage,
    );
  }

  void _openInsights() {
    showFeedbackInsightsSheet(
      context: context,
      title: 'Feedback insights',
      points: List.of(_loadedPoints),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final baseQuery = _baseQuery(user?.id);
    final navItems = widget.navItems ?? studentNavItemsOf(context);

    return AdaptiveScaffold(
      title: 'Feedback',
      selectedIndex: widget.selectedIndex,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      actions: [
        TextButton.icon(
          onPressed: _loadedPoints.isEmpty ? null : _openInsights,
          icon: const Icon(Icons.insights_outlined, size: 18),
          label: const Text('More'),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: AppSpacing.searchBarPadding,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by class or date',
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
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (value) => setState(() => _search = value.trim()),
            ),
          ),
          Expanded(
            child: PaginatedScrollBody<FeedbackEntry, FeedbackQuery>(
              provider: feedbackListProvider,
              query: baseQuery,
              withPage: (q, page) => (studentId: q.studentId, page: page, search: q.search),
              queryCacheKey: '${baseQuery.studentId ?? ''}|$_search',
              onInvalidate: (ref, q) => ref.invalidate(feedbackListProvider(q)),
              itemLabel: 'entries',
              initialLoadingKind: LoadingSkeletonKind.list,
              empty: ListView(
                children: const [
                  SizedBox(height: AppSpacing.emptyStateTop),
                  EmptyState(
                    title: 'No feedback yet',
                    message: 'Your teacher will submit feedback after class.',
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
                        className: f.className,
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
                  padding: AppSpacing.listGutter,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final f = items[i];
                    return FeedbackListCard(
                      title: f.className,
                      classDateLabel: formatFeedbackClassDate(f.date),
                      submittedAtLabel: formatFeedbackSubmittedAt(f.createdAt),
                      teacherName: f.teacherName,
                      summary: _summary(f),
                      footer: f.parentComments != null ? 'Parent: ${f.parentComments}' : null,
                      onMore: _openInsights,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
