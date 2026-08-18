import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/format_money.dart';
import '../../../../domain/entities/finance.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/finance_provider.dart';
import 'branch_expenses_panel.dart';
import 'finance_charts.dart';

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
    final canAddCost = ref.watch(authProvider).user?.isPrivilegedStaff == true;

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.md),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Text('$e', style: TextStyle(color: context.semantic.danger)),
      ),
      data: (data) {
        final totals = data.totals;
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(l10n.branchCollections, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    if (canAddCost)
                      FilledButton.tonalIcon(
                        onPressed: () => showAddBranchExpenseDialog(context, ref, month: month, year: year),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(l10n.addCost),
                      ),
                  ],
                ),
                if (canAddCost) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.addCostHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.semantic.textMuted),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: FinanceDonutPanel(
                        title: l10n.collectionSplit,
                        slices: [
                          FinanceSlice(label: l10n.collected, value: totals.collected, color: AppColors.success),
                          FinanceSlice(label: l10n.stillDue, value: totals.remaining, color: AppColors.error),
                        ],
                        centerValue: formatUzs(totals.collected),
                        centerLabel: l10n.collected,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FinanceDonutPanel(
                        title: l10n.leftoverVsCosts,
                        slices: [
                          FinanceSlice(label: l10n.leftover, value: math.max(0, totals.leftover), color: AppColors.success),
                          FinanceSlice(label: l10n.costsThisMonth, value: totals.expenses, color: AppColors.warning),
                          if (totals.leftover < 0)
                            FinanceSlice(label: l10n.stillDue, value: totals.leftover.abs(), color: AppColors.error),
                        ],
                        centerValue: formatUzs(totals.leftover),
                        centerLabel: l10n.leftover,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _KpiGrid(totals: totals, l10n: l10n),
                if (data.items.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.byBranch, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  for (final row in data.items) _BranchCollectionTile(row: row),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.totals, required this.l10n});

  final BranchCollectionRow totals;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final leftoverColor = totals.leftover >= 0 ? AppColors.success : AppColors.error;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: l10n.needToCollect,
                value: formatUzs(totals.expected),
                color: AppColors.primary,
                icon: Icons.flag_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _KpiTile(
                label: l10n.collected,
                value: formatUzs(totals.collected),
                color: AppColors.success,
                icon: Icons.payments_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _KpiTile(
                label: l10n.stillDue,
                value: formatUzs(totals.remaining),
                color: AppColors.error,
                icon: Icons.hourglass_bottom_outlined,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _KpiTile(
                label: l10n.costsThisMonth,
                value: formatUzs(totals.expenses),
                color: AppColors.warning,
                icon: Icons.receipt_long_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _KpiTile(
          label: l10n.leftover,
          value: formatUzs(totals.leftover),
          color: leftoverColor,
          icon: Icons.account_balance_wallet_outlined,
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
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

String _displayBranchName(String name) {
  final normalized = name.trim().toLowerCase();
  if (normalized == 'main branch' || normalized == 'main') return 'REN';
  return name;
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.maxValue});

  final double value;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: context.semantic.border.withValues(alpha: 0.45)),
            FractionallySizedBox(
              widthFactor: fraction,
              alignment: Alignment.centerLeft,
              child: ColoredBox(
                color: fraction >= 1 ? AppColors.success : AppColors.primary,
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchCollectionTile extends StatelessWidget {
  const _BranchCollectionTile({required this.row});

  final BranchCollectionRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_displayBranchName(row.branchName), style: Theme.of(context).textTheme.titleSmall),
              ),
              Text(
                '${formatUzs(row.collected)} / ${formatUzs(row.expected)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ProgressBar(value: row.collected, maxValue: row.expected),
        ],
      ),
    );
  }
}
