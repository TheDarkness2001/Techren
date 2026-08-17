import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/format_money.dart';
import '../../../../domain/entities/finance.dart';
import '../../../providers/finance_provider.dart';

class BranchCollectionsPanel extends ConsumerWidget {
  const BranchCollectionsPanel({
    super.key,
    required this.month,
    required this.year,
  });

  final int month;
  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(branchCollectionsProvider((month: month, year: year)));
    final l10n = context.l10n;

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text('$e', style: TextStyle(color: context.semantic.danger)),
      ),
      data: (data) => Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.branchCollections, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 640;
                  final cards = [
                    _TotalChip(
                      label: l10n.needToCollect,
                      value: formatUzs(data.totals.expected),
                      color: AppColors.primary,
                    ),
                    _TotalChip(
                      label: l10n.collected,
                      value: formatUzs(data.totals.collected),
                      color: AppColors.success,
                    ),
                    _TotalChip(
                      label: l10n.stillDue,
                      value: formatUzs(data.totals.remaining),
                      color: AppColors.error,
                    ),
                    _TotalChip(
                      label: l10n.costsThisMonth,
                      value: formatUzs(data.totals.expenses),
                      color: AppColors.warning,
                    ),
                    _TotalChip(
                      label: l10n.leftover,
                      value: formatUzs(data.totals.leftover),
                      color: data.totals.leftover >= 0 ? AppColors.success : AppColors.error,
                    ),
                  ];
                  if (wide) {
                    return Row(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.sm),
                          Expanded(child: cards[i]),
                        ],
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.sm),
                        cards[i],
                      ],
                    ],
                  );
                },
              ),
              if (data.items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                for (final row in data.items) _BranchCollectionTile(row: row),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalChip extends StatelessWidget {
  const _TotalChip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _BranchCollectionTile extends StatelessWidget {
  const _BranchCollectionTile({required this.row});

  final BranchCollectionRow row;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(row.branchName, style: Theme.of(context).textTheme.titleSmall),
              ),
              Text(
                '${formatUzs(row.collected)} / ${formatUzs(row.expected)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: row.expected <= 0 ? 0 : row.progress,
              backgroundColor: context.semantic.border,
              color: row.remaining <= 0 ? AppColors.success : AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${context.l10n.stillDue}: ${formatUzs(row.remaining)} · ${context.l10n.costsThisMonth}: ${formatUzs(row.expenses)} · ${context.l10n.leftover}: ${formatUzs(row.leftover)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
