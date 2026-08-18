import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/format_money.dart';

class FinanceSlice {
  const FinanceSlice({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;
}

class FinanceDonutChart extends StatelessWidget {
  const FinanceDonutChart({
    super.key,
    required this.slices,
    required this.centerValue,
    required this.centerLabel,
    this.size = 148,
    this.layout = FinanceDonutLayout.horizontal,
  });

  final List<FinanceSlice> slices;
  final String centerValue;
  final String centerLabel;
  final double size;
  final FinanceDonutLayout layout;

  @override
  Widget build(BuildContext context) {
    final hole = Theme.of(context).colorScheme.surface;
    final donut = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          slices: slices,
          holeColor: hole,
          emptyColor: context.semantic.border,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerValue,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, fontSize: layout == FinanceDonutLayout.vertical ? 12 : null),
                ),
                Text(
                  centerLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.semantic.textMuted, fontSize: layout == FinanceDonutLayout.vertical ? 10 : null),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final legend = Column(
      crossAxisAlignment: layout == FinanceDonutLayout.vertical ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        for (final slice in slices)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SliceLegend(slice: slice, total: slices.fold<double>(0, (sum, item) => sum + item.value), compact: layout == FinanceDonutLayout.vertical),
          ),
      ],
    );

    if (layout == FinanceDonutLayout.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          donut,
          const SizedBox(height: AppSpacing.sm),
          legend,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        donut,
        const SizedBox(width: AppSpacing.md),
        Expanded(child: legend),
      ],
    );
  }
}

enum FinanceDonutLayout { horizontal, vertical }

class FinanceManagedLegendItem {
  const FinanceManagedLegendItem({
    required this.slice,
    this.subtitle,
    this.onEdit,
    this.onDelete,
  });

  final FinanceSlice slice;
  final String? subtitle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
}

class FinanceManagedDonutChart extends StatelessWidget {
  const FinanceManagedDonutChart({
    super.key,
    required this.items,
    required this.centerValue,
    required this.centerLabel,
    this.size = 148,
    this.editTooltip,
    this.deleteTooltip,
  });

  final List<FinanceManagedLegendItem> items;
  final String centerValue;
  final String centerLabel;
  final double size;
  final String? editTooltip;
  final String? deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final slices = [for (final item in items) item.slice];
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);
    final hole = Theme.of(context).colorScheme.surface;

    final donut = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          slices: slices,
          holeColor: hole,
          emptyColor: context.semantic.border,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size * 0.12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerValue,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  centerLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.semantic.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _ManagedSliceLegend(
              slice: item.slice,
              total: total,
              subtitle: item.subtitle,
              onEdit: item.onEdit,
              onDelete: item.onDelete,
              editTooltip: editTooltip,
              deleteTooltip: deleteTooltip,
            ),
          ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        donut,
        const SizedBox(width: AppSpacing.md),
        Expanded(child: legend),
      ],
    );
  }
}

class FinanceDonutPanel extends StatelessWidget {
  const FinanceDonutPanel({
    super.key,
    required this.title,
    required this.slices,
    required this.centerValue,
    required this.centerLabel,
    this.size = 112,
  });

  final String title;
  final List<FinanceSlice> slices;
  final String centerValue;
  final String centerLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: FinanceDonutChart(
              slices: slices,
              centerValue: centerValue,
              centerLabel: centerLabel,
              size: size,
              layout: FinanceDonutLayout.vertical,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliceLegend extends StatelessWidget {
  const _SliceLegend({required this.slice, required this.total, this.compact = false});

  final FinanceSlice slice;
  final double total;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pct = total <= 0 ? 0 : ((slice.value / total) * 100).round();
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '${slice.label} · $pct%',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slice.label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
              Text(
                '${formatUzs(slice.value)} · $pct%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.semantic.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ManagedSliceLegend extends StatelessWidget {
  const _ManagedSliceLegend({
    required this.slice,
    required this.total,
    this.subtitle,
    this.onEdit,
    this.onDelete,
    this.editTooltip,
    this.deleteTooltip,
  });

  final FinanceSlice slice;
  final double total;
  final String? subtitle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? editTooltip;
  final String? deleteTooltip;

  @override
  Widget build(BuildContext context) {
    final pct = total <= 0 ? 0 : ((slice.value / total) * 100).round();
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slice.label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
              Text(
                '${formatUzs(slice.value)} · $pct%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.semantic.textMuted),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.semantic.textMuted),
                ),
            ],
          ),
        ),
        if (onEdit != null)
          IconButton(
            tooltip: editTooltip,
            icon: const Icon(Icons.edit_outlined, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
          ),
        if (onDelete != null)
          IconButton(
            tooltip: deleteTooltip,
            icon: const Icon(Icons.delete_outline, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
          ),
      ],
    );
  }
}

class FinanceGroupedBars extends StatelessWidget {
  const FinanceGroupedBars({
    super.key,
    required this.rows,
    required this.leftLabel,
    required this.rightLabel,
    this.leftColor = AppColors.success,
    this.rightColor = AppColors.error,
  });

  final List<({String label, double left, double right})> rows;
  final String leftLabel;
  final String rightLabel;
  final Color leftColor;
  final Color rightColor;

  @override
  Widget build(BuildContext context) {
    final maxValue = rows.fold<double>(0, (max, row) => math.max(max, math.max(row.left, row.right)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _LegendDot(color: leftColor, label: leftLabel),
            const SizedBox(width: AppSpacing.md),
            _LegendDot(color: rightColor, label: rightLabel),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final row in rows) ...[
          Text(row.label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          _BarRow(value: row.left, maxValue: maxValue, color: leftColor, label: formatUzs(row.left)),
          const SizedBox(height: 4),
          _BarRow(value: row.right, maxValue: maxValue, color: rightColor, label: formatUzs(row.right)),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.value,
    required this.maxValue,
    required this.color,
    required this.label,
  });

  final double value;
  final double maxValue;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  ColoredBox(color: context.semantic.border.withValues(alpha: 0.45), child: const SizedBox.expand()),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: ColoredBox(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 92,
          child: Text(
            label,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.holeColor,
    required this.emptyColor,
  });

  final List<FinanceSlice> slices;
  final Color holeColor;
  final Color emptyColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final total = slices.fold<double>(0, (sum, slice) => sum + math.max(0, slice.value));

    if (total <= 0) {
      canvas.drawCircle(center, radius, Paint()..color = emptyColor);
      canvas.drawCircle(center, radius * 0.58, Paint()..color = holeColor);
      return;
    }

    var start = -math.pi / 2;
    for (final slice in slices) {
      final value = math.max(0, slice.value);
      if (value <= 0) continue;
      final sweep = (value / total) * math.pi * 2;
      canvas.drawArc(rect, start, sweep, true, Paint()..color = slice.color);
      start += sweep;
    }
    canvas.drawCircle(center, radius * 0.58, Paint()..color = holeColor);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.holeColor != holeColor || oldDelegate.emptyColor != emptyColor;
}
