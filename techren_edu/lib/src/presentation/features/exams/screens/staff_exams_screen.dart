import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/paginated_scroll_body.dart';
import '../../../../domain/entities/finance.dart';
import '../../../providers/finance_provider.dart';
import '../widgets/exams_widgets.dart';

class StaffExamsScreen extends ConsumerStatefulWidget {
  const StaffExamsScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<StaffExamsScreen> createState() => _StaffExamsScreenState();
}

class _StaffExamsScreenState extends ConsumerState<StaffExamsScreen> {
  bool _showArchived = false;

  ExamsQuery get _baseQuery => (page: 1, search: '', archived: _showArchived);

  Future<void> _addExam() async {
    final created = await showCreateExamDialog(context, ref);
    if (created == null || !mounted) return;
    ref.invalidate(examsProvider(_baseQuery));
    showExamDetailSheet(context, ref, created, _baseQuery);
  }

  @override
  Widget build(BuildContext context) {
    final baseQuery = _baseQuery;
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));

    return AdaptiveScaffold(
      title: 'Exams',
      selectedIndex: selectedIndex < 0 ? 3 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
            body: Column(
        children: [
          ExamsPageHeader(
            showArchived: _showArchived,
            onToggleArchived: () => setState(() => _showArchived = !_showArchived),
            onAddExam: _addExam,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: PaginatedScrollBody<ExamEntry, ExamsQuery>(
              provider: examsProvider,
              query: baseQuery,
              withPage: (q, page) => (page: page, search: q.search, archived: q.archived),
              queryCacheKey: '${baseQuery.search}|${baseQuery.archived}',
              onInvalidate: (ref, q) => ref.invalidate(examsProvider(q)),
              itemLabel: 'exams',
              initialLoadingKind: LoadingSkeletonKind.dashboard,
              empty: ExamsEmptyStateCard(
                showArchived: _showArchived,
                onAddExam: _addExam,
              ),
              builder: (context, controller, items, state) => ListView(
                controller: controller,
                padding: EdgeInsets.zero,
                children: [
                  LayoutBuilder(
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
                          for (final exam in items)
                            SizedBox(
                              width: cardWidth,
                              child: ExamManagementCard(
                                exam: exam,
                                onTap: () => showExamDetailSheet(context, ref, exam, baseQuery),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
