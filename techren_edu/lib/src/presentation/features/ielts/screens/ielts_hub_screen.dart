import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/ielts_provider.dart';
import '../../../shells/staff_shell.dart';

class IeltsHubScreen extends ConsumerWidget {
  const IeltsHubScreen({
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

  String get _base => isStudent
      ? '$routePrefix/learn/$subjectId/ielts'
      : '$routePrefix/learning/$subjectId/ielts';

  String get _subjectHome => isStudent
      ? '$routePrefix/learn/$subjectId'
      : '$routePrefix/learning/$subjectId';

  String get _learningSelected => selectedRoute ??
      (isStudent ? '$routePrefix/learn' : '$routePrefix/learning');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final locked = isStudent && user?.ieltsAccess != true;
    final scheme = Theme.of(context).colorScheme;
    final muted = context.semantic.textMuted;

    final body = locked
        ? Center(
            child: Padding(
              padding: AppSpacing.pagePaddingWide,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 56, color: muted),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'IELTS Preparation is locked',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Ask your academy founder to unlock IELTS for your account.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    onPressed: () => context.go(_subjectHome),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to subject'),
                  ),
                ],
              ),
            ),
          )
        : _HubBody(
            base: _base,
            subjectId: subjectId,
            isStudent: isStudent,
            isFounder: user?.isFounder == true,
            scheme: scheme,
            muted: muted,
          );

    final actions = <Widget>[
      IconButton(
        tooltip: 'Back to subject',
        onPressed: () => context.go(_subjectHome),
        icon: const Icon(Icons.arrow_back),
      ),
    ];

    // Staff Learning uses AdaptiveScaffold so IELTS stays inside the academy shell.
    if (!isStudent) {
      final items = navItems.isNotEmpty
          ? navItems
          : (routePrefix.startsWith('/founder') ? founderNavItems : adminNavItems);
      final selectedIndex = items.indexWhere((i) => _learningSelected.startsWith(i.route) || i.route.contains('/learning'));
      return AdaptiveScaffold(
        title: 'IELTS Preparation',
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        selectedRoute: _learningSelected,
        items: items,
        onDestinationSelected: (i) => context.go(items[i].route),
        actions: actions,
        body: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('IELTS Preparation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(_subjectHome),
        ),
      ),
      body: Padding(padding: AppSpacing.pagePaddingWide, child: body),
    );
  }
}

class _HubBody extends ConsumerWidget {
  const _HubBody({
    required this.base,
    required this.subjectId,
    required this.isStudent,
    required this.isFounder,
    required this.scheme,
    required this.muted,
  });

  final String base;
  final String subjectId;
  final bool isStudent;
  final bool isFounder;
  final ColorScheme scheme;
  final Color muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = <_HubTile>[
      _HubTile('Mock Exams', Icons.quiz_outlined, '$base/exams', 'Full & section mocks'),
      _HubTile('Listening', Icons.headphones_outlined, '$base/listening', 'Listening-only tests'),
      _HubTile('Reading', Icons.menu_book_outlined, '$base/reading', 'Reading-only tests'),
      _HubTile('Writing', Icons.edit_note_outlined, '$base/writing', 'Writing tasks'),
      _HubTile('Results & History', Icons.history_edu_outlined, '$base/history', 'Past attempts'),
      if (isStudent)
        _HubTile('My Analytics', Icons.insights_outlined, '$base/analytics', 'Strengths & weaknesses'),
      if (!isStudent) ...[
        _HubTile('Manage Exams', Icons.settings_outlined, '$base/manage', 'Create & publish'),
        _HubTile('Sources', Icons.source_outlined, '$base/sources', 'Books, audio & articles'),
        _HubTile('Question Bank', Icons.storage_outlined, '$base/bank', 'Reusable question library'),
        _HubTile('Analytics', Icons.bar_chart_outlined, '$base/analytics', 'Attempt & item insights'),
        _HubTile('Writing Review', Icons.rate_review_outlined, '$base/writing-review', 'Score submissions'),
        if (isFounder)
          _HubTile('IELTS Access', Icons.lock_open_outlined, '$base/access', 'Founder unlock/lock'),
      ],
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (isStudent) ...[
          _StudentDashboard(
            base: base,
            subjectId: subjectId,
            scheme: scheme,
            muted: muted,
          ),
          const SizedBox(height: AppSpacing.lg),
        ] else
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: AppRadius.card,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  scheme.surface,
                ],
              ),
              border: Border.all(color: context.semantic.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Computer IELTS practice',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Timed mocks for Listening, Reading, and Writing. Instant L/R bands; Writing reviewed by teachers.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted, height: 1.4),
                ),
              ],
            ),
          ),
        if (!isStudent) const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final t in tiles)
              SizedBox(
                width: 280,
                child: _HubCard(tile: t, onTap: () => context.go(t.route)),
              ),
          ],
        ),
      ],
    );
  }
}

/// Student hub dashboard: latest bands, trend, focus areas, recent attempts.
class _StudentDashboard extends ConsumerWidget {
  const _StudentDashboard({
    required this.base,
    required this.subjectId,
    required this.scheme,
    required this.muted,
  });

  final String base;
  final String subjectId;
  final ColorScheme scheme;
  final Color muted;

  String _band(dynamic v) {
    if (v == null) return '—';
    if (v is num) {
      final d = v.toDouble();
      return d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(ieltsStudentAnalyticsProvider);
    final historyAsync = ref.watch(ieltsHistoryProvider(subjectId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.18),
                scheme.surface,
              ],
            ),
            border: Border.all(color: context.semantic.border),
          ),
          child: analyticsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your IELTS progress',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text('Could not load analytics. Pull to refresh from My Analytics.', style: TextStyle(color: muted)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(ieltsStudentAnalyticsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
            data: (data) {
              final latest = data.latestBands;
              final hasAttempts = data.attemptsCompleted > 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Your IELTS progress',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('$base/exams'),
                        child: const Text('Start mock'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasAttempts
                        ? '${data.attemptsCompleted} completed attempt${data.attemptsCompleted == 1 ? '' : 's'} · last ${data.days} days'
                        : 'Complete a mock to see estimated bands and focus areas.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _DashBandChip(label: 'Overall', value: _band(latest?['overallBand']), emphasize: true),
                      _DashBandChip(label: 'Listening', value: _band(latest?['listeningBand'])),
                      _DashBandChip(label: 'Reading', value: _band(latest?['readingBand'])),
                      _DashBandChip(label: 'Writing', value: _band(latest?['writingBand'])),
                    ],
                  ),
                  if (data.bandTrend.length >= 2) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text('Recent overall trend', style: TextStyle(fontWeight: FontWeight.w700, color: muted)),
                    const SizedBox(height: 8),
                    _MiniTrendStrip(trend: data.bandTrend),
                  ],
                  if (data.weaknesses.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text('Focus areas', style: TextStyle(fontWeight: FontWeight.w700, color: muted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final w in data.weaknesses.take(4))
                          Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(Icons.flag_outlined, size: 16),
                            label: Text(
                              '${w['type'] ?? '?'} · ${w['accuracy'] ?? '—'}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ActionChip(
                          label: const Text('Full analytics'),
                          onPressed: () => context.go('$base/analytics'),
                        ),
                      ],
                    ),
                  ] else if (hasAttempts) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: () => context.go('$base/analytics'),
                      icon: const Icon(Icons.insights_outlined, size: 18),
                      label: const Text('Open full analytics'),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        historyAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (page) {
            final recent = page.items.take(4).toList();
            if (recent.isEmpty) {
              return Material(
                color: scheme.surface,
                borderRadius: AppRadius.card,
                child: InkWell(
                  borderRadius: AppRadius.card,
                  onTap: () => context.go('$base/exams'),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.card,
                      border: Border.all(color: context.semantic.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.play_circle_outline, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No attempts yet — take your first mock exam',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Recent attempts', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('$base/history'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                for (final a in recent)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        a.exam?.title.isNotEmpty == true ? a.exam!.title : 'Attempt',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          if (a.scores.overallBand != null) 'Overall ${a.scores.overallBand}',
                          if (a.scores.listeningBand != null) 'L ${a.scores.listeningBand}',
                          if (a.scores.readingBand != null) 'R ${a.scores.readingBand}',
                          if (a.submittedAt != null)
                            '${a.submittedAt!.year}-${a.submittedAt!.month.toString().padLeft(2, '0')}-${a.submittedAt!.day.toString().padLeft(2, '0')}',
                        ].join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('$base/results/${a.id}'),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DashBandChip extends StatelessWidget {
  const _DashBandChip({required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: emphasize ? AppColors.primary.withValues(alpha: 0.14) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.semantic.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.semantic.textMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: emphasize ? AppColors.primary : null,
                ),
          ),
        ],
      ),
    );
  }
}

class _MiniTrendStrip extends StatelessWidget {
  const _MiniTrendStrip({required this.trend});

  final List<Map<String, dynamic>> trend;

  @override
  Widget build(BuildContext context) {
    final points = trend.where((t) => t['overallBand'] != null).toList();
    if (points.isEmpty) return const SizedBox.shrink();
    final last = points.length > 8 ? points.sublist(points.length - 8) : points;
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final p in last) ...[
            Expanded(
              child: Tooltip(
                message: 'Overall ${p['overallBand']}',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: (((p['overallBand'] as num?)?.toDouble() ?? 0) / 9.0 * 36).clamp(6.0, 36.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HubTile {
  const _HubTile(this.title, this.icon, this.route, this.subtitle);
  final String title;
  final IconData icon;
  final String route;
  final String subtitle;
}

class _HubCard extends StatelessWidget {
  const _HubCard({required this.tile, required this.onTap});
  final _HubTile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(color: context.semantic.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tile.icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tile.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(tile.subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class IeltsExamListScreen extends ConsumerWidget {
  const IeltsExamListScreen({
    super.key,
    required this.subjectId,
    this.mode,
    this.isStudent = true,
    this.routePrefix = '/student',
    this.navItems = const [],
    this.selectedRoute,
  });

  final String subjectId;
  final String? mode;
  final bool isStudent;
  final String routePrefix;
  final List<NavItem> navItems;
  final String? selectedRoute;

  String get _hub => isStudent
      ? '$routePrefix/learn/$subjectId/ielts'
      : '$routePrefix/learning/$subjectId/ielts';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ieltsExamsProvider((subjectId: subjectId, mode: mode)));
    final title = switch (mode) {
      'listening' => 'Listening mocks',
      'reading' => 'Reading mocks',
      'writing' => 'Writing mocks',
      _ => 'Mock exams',
    };

    final body = async.when(
      loading: () => const LoadingState(message: 'Loading exams...'),
      error: (e, _) => ErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(ieltsExamsProvider((subjectId: subjectId, mode: mode))),
      ),
      data: (exams) {
        final filtered = mode == null ? exams : exams.where((e) => e.mode == mode || e.mode == 'full').toList();
        if (filtered.isEmpty) {
          return EmptyState(
            title: 'No exams yet',
            message: isStudent
                ? 'Published IELTS mocks will appear here.'
                : 'Create and publish an exam under Manage Exams.',
            icon: Icons.quiz_outlined,
            action: isStudent
                ? null
                : FilledButton.icon(
                    onPressed: () => context.go('$_hub/manage'),
                    icon: const Icon(Icons.add),
                    label: const Text('Manage exams'),
                  ),
          );
        }
        return ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final exam = filtered[i];
            return Card(
              child: ListTile(
                title: Text(exam.title),
                subtitle: Text('${exam.mode} · ${exam.difficulty}${exam.published ? '' : ' · draft'}'),
                trailing: const Icon(Icons.play_arrow),
                onTap: () => context.go('$_hub/play/${exam.id}'),
              ),
            );
          },
        );
      },
    );

    final actions = <Widget>[
      IconButton(
        tooltip: 'Back',
        onPressed: () => context.go(_hub),
        icon: const Icon(Icons.arrow_back),
      ),
    ];

    if (!isStudent) {
      final learningSelected = selectedRoute ?? '$routePrefix/learning';
      final items = navItems.isNotEmpty
          ? navItems
          : (routePrefix.startsWith('/founder') ? founderNavItems : adminNavItems);
      final selectedIndex = items.indexWhere(
        (i) => learningSelected.startsWith(i.route) || i.route.contains('/learning'),
      );
      return AdaptiveScaffold(
        title: title,
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        selectedRoute: learningSelected,
        items: items,
        onDestinationSelected: (i) => context.go(items[i].route),
        actions: actions,
        body: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go(_hub)),
      ),
      body: Padding(padding: AppSpacing.pagePaddingWide, child: body),
    );
  }
}
