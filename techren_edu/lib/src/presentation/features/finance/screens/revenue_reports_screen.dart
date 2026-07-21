import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/finance.dart';
import '../../../providers/finance_provider.dart';

class RevenueReportsScreen extends ConsumerWidget {
  const RevenueReportsScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(revenueDateRangeProvider);
    final summaryAsync = ref.watch(filteredRevenueSummaryProvider);
    final chartAsync = ref.watch(filteredRevenueChartProvider);
    final exportAsync = ref.watch(filteredRevenueExportProvider);
    final selectedIndex = navItems.indexWhere((r) => selectedRoute.startsWith(r.route));

    return AdaptiveScaffold(
      title: 'Revenue Reports',
      selectedIndex: selectedIndex < 0 ? 3 : selectedIndex,
      selectedRoute: selectedRoute,
      items: navItems,
      onDestinationSelected: (i) => context.go(navItems[i].route),
      actions: [
        IconButton(
          icon: const Icon(Icons.copy_outlined),
          tooltip: 'Copy report',
          onPressed: () => _copyReport(context, ref, exportAsync),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(filteredRevenueSummaryProvider);
          ref.invalidate(filteredRevenueChartProvider);
          ref.invalidate(filteredRevenueExportProvider);
        },
        child: ListView(
          padding: AppSpacing.listGutter,
          children: [
            _DateRangeFilter(
              range: range,
              onPreset: (preset) => ref.read(revenueDateRangeProvider.notifier).state = preset,
              onCustom: () => _pickCustomRange(context, ref),
            ),
            const SizedBox(height: AppSpacing.md),
            summaryAsync.when(
              loading: () => const LoadingState(kind: LoadingSkeletonKind.dashboard),
              error: (e, _) => _RevenueError(
                message: e.toString(),
                onRetry: () {
                  ref.invalidate(filteredRevenueSummaryProvider);
                  ref.invalidate(filteredRevenueChartProvider);
                  ref.invalidate(filteredRevenueExportProvider);
                },
              ),
              data: (summary) => Column(
                children: [
                  _SummaryRow(
                    cards: [
                      _SummaryCard(
                        title: 'Total Revenue',
                        value: '${summary.totalRevenue.toStringAsFixed(0)} UZS',
                        icon: Icons.trending_up,
                      ),
                      _SummaryCard(
                        title: 'Transactions',
                        value: '${summary.totalTransactions}',
                        icon: Icons.receipt_long,
                      ),
                      _SummaryCard(
                        title: 'Pending',
                        value: '${summary.totalPending.toStringAsFixed(0)} UZS',
                        subtitle: '${summary.pendingCount} unpaid',
                        icon: Icons.pending_actions,
                      ),
                    ],
                  ),
                  if (summary.revenueBySubject.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _SectionCard(
                      title: 'Revenue by Subject',
                      child: Column(
                        children: summary.revenueBySubject.entries
                            .map(
                              (e) => ListTile(
                                dense: true,
                                title: Text(e.key),
                                trailing: Text('${e.value.toStringAsFixed(0)} UZS'),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            chartAsync.when(
              loading: () => const LoadingState(kind: LoadingSkeletonKind.card),
              error: (e, _) => _RevenueError(
                message: e.toString(),
                onRetry: () => ref.invalidate(filteredRevenueChartProvider),
              ),
              data: (chart) => Column(
                children: [
                  if (chart.byMonth.isNotEmpty)
                    _SectionCard(
                      title: 'Monthly Revenue',
                      child: _ChartBars(points: chart.byMonth),
                    ),
                  if (chart.byType.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _SectionCard(
                      title: 'Revenue by Payment Type',
                      child: _ChartBars(points: chart.byType, vertical: false),
                    ),
                  ],
                  if (chart.byMonth.isEmpty && chart.byType.isEmpty)
                    const EmptyState(
                      title: 'No chart data',
                      message: 'Paid transactions will appear here once recorded.',
                      icon: Icons.bar_chart_outlined,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            exportAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => _RevenueError(
                message: e.toString(),
                onRetry: () => ref.invalidate(filteredRevenueExportProvider),
              ),
              data: (export) => _SectionCard(
                title: 'Export Preview',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Generated ${export.generatedAt.toLocal().toString().split('.').first}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${export.payments.length} payment records included'),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(
                      onPressed: () => _copyReport(context, ref, exportAsync),
                      child: const Text('Copy report to clipboard'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: ref.read(revenueDateRangeProvider).startDate ?? now.subtract(const Duration(days: 29)),
        end: ref.read(revenueDateRangeProvider).endDate ?? now,
      ),
    );
    if (picked == null) return;
    ref.read(revenueDateRangeProvider.notifier).state =
        RevenueDateRange.custom(picked.start, picked.end);
  }

  Future<void> _copyReport(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<RevenueExportData> exportAsync,
  ) async {
    final export = exportAsync.valueOrNull;
    if (export == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report not ready yet')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: export.toReportText()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Revenue report copied to clipboard')),
    );
  }
}

class _RevenueError extends StatelessWidget {
  const _RevenueError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isNetwork = message.contains('connection') || message.contains('XMLHttpRequest');
    return EmptyState(
      title: isNetwork ? 'Could not reach the server' : 'Could not load revenue',
      message: isNetwork
          ? 'Check that the API is running, then try again.'
          : message,
      icon: Icons.cloud_off_outlined,
      action: FilledButton(onPressed: onRetry, child: const Text('Retry')),
    );
  }
}

class _DateRangeFilter extends StatelessWidget {
  const _DateRangeFilter({
    required this.range,
    required this.onPreset,
    required this.onCustom,
  });

  final RevenueDateRange range;
  final ValueChanged<RevenueDateRange> onPreset;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Date range', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(range.label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _PresetChip(
                  label: 'All time',
                  selected: !range.hasFilter && range.label == 'All time',
                  onTap: () => onPreset(RevenueDateRange.allTime()),
                ),
                _PresetChip(
                  label: 'This month',
                  selected: range.label == 'This month',
                  onTap: () => onPreset(RevenueDateRange.thisMonth()),
                ),
                _PresetChip(
                  label: 'Last 30 days',
                  selected: range.label == 'Last 30 days',
                  onTap: () => onPreset(RevenueDateRange.last30Days()),
                ),
                _PresetChip(
                  label: 'This year',
                  selected: range.label == 'This year',
                  onTap: () => onPreset(RevenueDateRange.thisYear()),
                ),
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: const Text('Custom'),
                  onPressed: onCustom,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.cards});

  final List<_SummaryCard> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        if (wide) {
          return Row(
            children: cards
                .map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: AppSpacing.xs), child: c)))
                .toList(),
          );
        }
        return Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.xs), child: c)).toList());
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null) Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChartBars extends StatelessWidget {
  const _ChartBars({required this.points, this.vertical = true});

  final List<RevenueChartPoint> points;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    if (!vertical || points.length > 14) {
      return _HorizontalBarChart(points: points);
    }
    return _VerticalBarChart(points: points);
  }
}

class _VerticalBarChart extends StatelessWidget {
  const _VerticalBarChart({required this.points});

  final List<RevenueChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxAmount = points.map((p) => p.amount).fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = maxAmount <= 0 ? 1.0 : maxAmount;
    final yTicks = _niceTicks(safeMax);

    return SizedBox(
      height: 260,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                for (final tick in yTicks.reversed)
                  Expanded(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Text(
                        _shortMoney(tick),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                      ),
                    ),
                  ),
                const SizedBox(height: 28),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _BarChartGridPainter(
                            tickCount: yTicks.length,
                            color: scheme.outlineVariant.withValues(alpha: 0.45),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (final point in points)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Tooltip(
                                      message: '${point.label}: ${point.amount.toStringAsFixed(0)} UZS',
                                      child: _AnimatedBar(
                                        fraction: point.amount / safeMax,
                                        color: scheme.primary,
                                        valueLabel: _shortMoney(point.amount),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SizedBox(
                  height: 28,
                  child: Row(
                    children: [
                      for (final point in points)
                        Expanded(
                          child: Text(
                            _shortLabel(point.label),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalBarChart extends StatelessWidget {
  const _HorizontalBarChart({required this.points});

  final List<RevenueChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxAmount = points.map((p) => p.amount).fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = maxAmount <= 0 ? 1.0 : maxAmount;

    return Column(
      children: [
        for (final point in points)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        point.label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${point.amount.toStringAsFixed(0)} UZS',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 14,
                    child: Stack(
                      children: [
                        Container(color: scheme.surfaceContainerHighest),
                        FractionallySizedBox(
                          widthFactor: (point.amount / safeMax).clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [scheme.primary, scheme.primary.withValues(alpha: 0.75)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AnimatedBar extends StatelessWidget {
  const _AnimatedBar({
    required this.fraction,
    required this.color,
    required this.valueLabel,
  });

  final double fraction;
  final Color color;
  final String valueLabel;

  @override
  Widget build(BuildContext context) {
    final heightFactor = fraction.clamp(0.02, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final barHeight = constraints.maxHeight * heightFactor;
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: barHeight,
            width: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: -16,
                  child: Text(
                    valueLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [color.withValues(alpha: 0.75), color],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const SizedBox.expand(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BarChartGridPainter extends CustomPainter {
  _BarChartGridPainter({required this.tickCount, required this.color});

  final int tickCount;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (tickCount <= 1) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var i = 0; i < tickCount; i++) {
      final y = size.height * (i / (tickCount - 1));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartGridPainter oldDelegate) =>
      oldDelegate.tickCount != tickCount || oldDelegate.color != color;
}

List<double> _niceTicks(double max) {
  if (max <= 0) return const [0, 1];
  final step = max / 4;
  return [0, step, step * 2, step * 3, max];
}

String _shortMoney(double amount) {
  if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(amount >= 10000 ? 0 : 1)}K';
  return amount.toStringAsFixed(0);
}

String _shortLabel(String label) {
  // "2026-01" → "Jan", "tuition-fee" → keep short
  final monthMatch = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(label);
  if (monthMatch != null) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = int.tryParse(monthMatch.group(2)!) ?? 1;
    return months[(m - 1).clamp(0, 11)];
  }
  if (label.length <= 8) return label;
  return label.split(RegExp(r'[-_]')).first;
}
