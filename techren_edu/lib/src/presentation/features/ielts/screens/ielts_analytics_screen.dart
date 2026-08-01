import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../providers/ielts_provider.dart';
import '../../../shells/staff_shell.dart';

/// Staff overview OR student strengths/weaknesses, based on [isStudent].
class IeltsAnalyticsScreen extends ConsumerWidget {
  const IeltsAnalyticsScreen({
    super.key,
    required this.subjectId,
    this.isStudent = true,
    this.routePrefix = '/student',
    this.navItems = const [],
    this.selectedRoute,
  });

  final String subjectId;
  final bool isStudent;
  final String routePrefix;
  final List<NavItem> navItems;
  final String? selectedRoute;

  String get _hub => isStudent ? '$routePrefix/learn/$subjectId/ielts' : '$routePrefix/learning/$subjectId/ielts';
  String get _learningSelected => selectedRoute ?? (isStudent ? '$routePrefix/learn' : '$routePrefix/learning');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isStudent) {
      return _StudentAnalyticsBody(hub: _hub);
    }

    final navItemsResolved =
        navItems.isNotEmpty ? navItems : (routePrefix.startsWith('/founder') ? founderNavItems : adminNavItems);
    final selectedIndex = navItemsResolved.indexWhere(
      (i) => _learningSelected.startsWith(i.route) || i.route.contains('/learning'),
    );

    return AdaptiveScaffold(
      title: 'IELTS Analytics',
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      selectedRoute: _learningSelected,
      items: navItemsResolved,
      onDestinationSelected: (i) => context.go(navItemsResolved[i].route),
      actions: [
        IconButton(
          tooltip: 'Back to IELTS Preparation',
          onPressed: () => context.go(_hub),
          icon: const Icon(Icons.arrow_back),
        ),
      ],
      body: _StaffAnalyticsBody(subjectId: subjectId),
    );
  }
}

class _StaffAnalyticsBody extends ConsumerWidget {
  const _StaffAnalyticsBody({required this.subjectId});
  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ieltsStaffAnalyticsProvider(subjectId));
    final muted = context.semantic.textMuted;

    return async.when(
      loading: () => const LoadingState(message: 'Loading analytics...'),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(ieltsStaffAnalyticsProvider(subjectId))),
      data: (data) {
        final maxTypeTotal = data.questionTypeAccuracy.fold<int>(0, (m, r) => (r['total'] as int? ?? 0) > m ? (r['total'] as int? ?? 0) : m);
        return ListView(
          padding: AppSpacing.pagePaddingWide,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard('Attempts (last ${data.days}d)', '${data.totalAttempts}', Icons.fact_check_outlined),
                _StatCard(
                  'Avg listening band',
                  data.averageListeningBand?.toStringAsFixed(1) ?? '—',
                  Icons.headphones_outlined,
                ),
                _StatCard(
                  'Avg reading band',
                  data.averageReadingBand?.toStringAsFixed(1) ?? '—',
                  Icons.menu_book_outlined,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Band distribution', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (data.bandDistribution.isEmpty)
              Text('No scored attempts yet.', style: TextStyle(color: muted))
            else
              _BandDistributionChart(distribution: data.bandDistribution),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Question type accuracy (hardest first)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (data.questionTypeAccuracy.isEmpty)
              Text('Not enough data yet.', style: TextStyle(color: muted))
            else
              for (final row in data.questionTypeAccuracy)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (row['type']?.toString() ?? '').replaceAll('_', ' '),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${row['accuracy']}% · ${row['correct']}/${row['total']}',
                            style: TextStyle(color: muted, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ((row['accuracy'] as num?)?.toDouble() ?? 0) / 100,
                          minHeight: 8,
                          color: ((row['accuracy'] as num?)?.toDouble() ?? 0) < 50 ? Colors.red : AppColors.primary,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
            if (maxTypeTotal == 0) const SizedBox.shrink(),
          ],
        );
      },
    );
  }
}

class _StudentAnalyticsBody extends ConsumerWidget {
  const _StudentAnalyticsBody({required this.hub});
  final String hub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ieltsStudentAnalyticsProvider);
    final muted = context.semantic.textMuted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My IELTS analytics'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go(hub)),
      ),
      body: async.when(
        loading: () => const LoadingState(message: 'Loading your analytics...'),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(ieltsStudentAnalyticsProvider)),
        data: (data) {
          if (data.attemptsCompleted == 0) {
            return const EmptyState(
              title: 'No attempts yet',
              message: 'Complete a mock exam to see your strengths and weaknesses here.',
              icon: Icons.insights_outlined,
            );
          }
          final latest = data.latestBands;
          return ListView(
            padding: AppSpacing.pagePaddingWide,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard('Attempts completed', '${data.attemptsCompleted}', Icons.fact_check_outlined),
                  _StatCard(
                    'Latest overall',
                    latest?['overallBand'] != null ? '${latest!['overallBand']}' : '—',
                    Icons.emoji_events_outlined,
                  ),
                  _StatCard(
                    'Latest listening',
                    latest?['listeningBand'] != null ? '${latest!['listeningBand']}' : '—',
                    Icons.headphones_outlined,
                  ),
                  _StatCard(
                    'Latest reading',
                    latest?['readingBand'] != null ? '${latest!['readingBand']}' : '—',
                    Icons.menu_book_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Band trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (data.bandTrend.isEmpty)
                Text('Not enough history yet.', style: TextStyle(color: muted))
              else
                _BandTrendChart(trend: data.bandTrend),
              const SizedBox(height: AppSpacing.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _AccuracyList(
                      title: 'Strengths',
                      icon: Icons.thumb_up_alt_outlined,
                      color: Colors.green,
                      rows: data.strengths,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AccuracyList(
                      title: 'Focus areas',
                      icon: Icons.warning_amber_outlined,
                      color: Colors.orange,
                      rows: data.weaknesses,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AccuracyList extends StatelessWidget {
  const _AccuracyList({required this.title, required this.icon, required this.color, required this.rows});
  final String title;
  final IconData icon;
  final Color color;
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: AppRadius.card, border: Border.all(color: context.semantic.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty) Text('Not enough data yet.', style: TextStyle(color: muted, fontSize: 12)),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text((r['type']?.toString() ?? '').replaceAll('_', ' '), style: const TextStyle(fontSize: 13))),
                  Text('${r['accuracy']}%', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _BandDistributionChart extends StatelessWidget {
  const _BandDistributionChart({required this.distribution});
  final Map<String, int> distribution;

  @override
  Widget build(BuildContext context) {
    final entries = distribution.entries.toList()
      ..sort((a, b) => (double.tryParse(a.key) ?? 0).compareTo(double.tryParse(b.key) ?? 0));
    final maxCount = entries.fold<int>(1, (m, e) => e.value > m ? e.value : m);
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final e in entries)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${e.value}', style: const TextStyle(fontSize: 11)),
                    const SizedBox(height: 2),
                    Container(
                      height: 90 * (e.value / maxCount).clamp(0.05, 1.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.75),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(e.key, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BandTrendChart extends StatelessWidget {
  const _BandTrendChart({required this.trend});
  final List<Map<String, dynamic>> trend;

  @override
  Widget build(BuildContext context) {
    final recent = trend.length > 12 ? trend.sublist(trend.length - 12) : trend;
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final t in recent)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      t['overallBand'] != null ? '${t['overallBand']}' : '—',
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 90 * (((t['overallBand'] as num?)?.toDouble() ?? 0) / 9).clamp(0.05, 1.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
