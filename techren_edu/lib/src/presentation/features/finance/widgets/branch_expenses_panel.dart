import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/format_money.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../domain/entities/branch.dart';
import '../../../../domain/entities/finance.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/finance_provider.dart';
import '../../../providers/identity_provider.dart';
import 'finance_charts.dart';

const _categories = ['teacher-payment', 'rent', 'electricity', 'repair', 'other'];

String _categoryLabel(AppLocalizations l10n, String category) {
  switch (category) {
    case 'teacher-payment':
      return l10n.teacherPayment;
    case 'rent':
      return l10n.rent;
    case 'electricity':
      return l10n.electricity;
    case 'repair':
      return l10n.repair;
    default:
      return l10n.otherCost;
  }
}

Color _categoryColor(String category) {
  switch (category) {
    case 'teacher-payment':
      return AppColors.chartPurple;
    case 'rent':
      return AppColors.chartRose;
    case 'electricity':
      return AppColors.chartAmber;
    case 'repair':
      return AppColors.chartEmerald;
    default:
      return AppColors.chartCyan;
  }
}

Color _sliceColor(String category, int index) {
  // Prefer unique colors per row so two "Other" costs stay distinguishable.
  if (index < AppColors.chartPalette.length) {
    return AppColors.chartPalette[index];
  }
  return _categoryColor(category);
}

List<FinanceSlice> _costSlicesFromItems(AppLocalizations l10n, List<BranchExpense> items) {
  return [
    for (var i = 0; i < items.length; i++)
      FinanceSlice(
        label: _categoryLabel(l10n, items[i].category),
        value: items[i].amount,
        color: _sliceColor(items[i].category, i),
      ),
  ];
}

String _formatCostWhen(DateTime when) {
  final local = when.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$d.$m.${local.year} $h:$min';
}

String _expenseSubtitle(BranchExpense item) {
  return [
    _formatCostWhen(item.recordedWhen),
    if (item.branchName.isNotEmpty) _displayBranchName(item.branchName),
    if (item.teacherName.isNotEmpty) item.teacherName,
    if (item.notes.isNotEmpty) item.notes,
  ].join(' · ');
}

String _displayBranchName(String name) {
  final normalized = name.trim().toLowerCase();
  if (normalized == 'main branch' || normalized == 'main') return 'REN';
  return name;
}

class BranchExpensesPanel extends ConsumerWidget {
  const BranchExpensesPanel({
    super.key,
    required this.month,
    required this.year,
  });

  final int month;
  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = (month: month, year: year);
    final async = ref.watch(branchExpensesProvider(query));
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _addExpense(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addCost),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            async.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text('$e', style: TextStyle(color: context.semantic.danger)),
              data: (data) {
                if (data.items.isEmpty) {
                  return Text(
                    '${l10n.costsThisMonth}: ${formatUzs(0)}',
                    style: TextStyle(color: context.semantic.textMuted),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${l10n.costsThisMonth}: ${formatUzs(data.totalAmount)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_costSlicesFromItems(l10n, data.items).isNotEmpty) ...[
                      Text(l10n.costsBreakdown, style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: AppSpacing.sm),
                      FinanceManagedDonutChart(
                        centerValue: formatUzs(data.totalAmount),
                        centerLabel: l10n.costsThisMonth,
                        editTooltip: l10n.edit,
                        deleteTooltip: l10n.delete,
                        items: [
                          for (var i = 0; i < data.items.length; i++)
                            FinanceManagedLegendItem(
                              slice: FinanceSlice(
                                label: _categoryLabel(l10n, data.items[i].category),
                                value: data.items[i].amount,
                                color: _sliceColor(data.items[i].category, i),
                              ),
                              subtitle: _expenseSubtitle(data.items[i]),
                              onEdit: () => showEditBranchExpenseDialog(
                                context,
                                ref,
                                expense: data.items[i],
                                month: month,
                                year: year,
                              ),
                              onDelete: () => _deleteExpense(context, ref, data.items[i].id),
                            ),
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addExpense(BuildContext context, WidgetRef ref) async {
    await showAddBranchExpenseDialog(context, ref, month: month, year: year);
  }

  Future<void> _deleteExpense(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(financeApiProvider).deleteBranchExpense(id);
      ref.invalidate(branchExpensesProvider);
      ref.invalidate(branchCollectionsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

Future<bool> showAddBranchExpenseDialog(
  BuildContext context,
  WidgetRef ref, {
  required int month,
  required int year,
}) {
  return showBranchExpenseDialog(context, ref, month: month, year: year);
}

Future<bool> showEditBranchExpenseDialog(
  BuildContext context,
  WidgetRef ref, {
  required BranchExpense expense,
  required int month,
  required int year,
}) {
  return showBranchExpenseDialog(context, ref, month: month, year: year, expense: expense);
}

Future<bool> showBranchExpenseDialog(
  BuildContext context,
  WidgetRef ref, {
  required int month,
  required int year,
  BranchExpense? expense,
}) async {
  final editing = expense != null;
  final l10n = context.l10n;
  final user = ref.read(authProvider).user;
  final amountCtrl = TextEditingController(text: editing ? expense.amount.toString() : '');
  final notesCtrl = TextEditingController(text: editing ? expense.notes : '');
  var category = editing ? expense.category : 'rent';
  String? branchId = editing ? expense.branchId : (user?.isFounder == true ? null : user?.branchId);
  String? teacherId = editing ? expense.teacherId : null;
  var spentAt = editing ? expense.recordedWhen.toLocal() : DateTime.now();

  final branches = user?.isFounder == true
      ? (await ref.read(branchesProvider(const PageMeta(limit: 100)).future)).items
      : <Branch>[];
  final teachers = (await ref.read(teachersProvider(const PageMeta(limit: 100)).future)).items;

  if (!context.mounted) {
    amountCtrl.dispose();
    notesCtrl.dispose();
    return false;
  }

  final saved = await showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        Future<void> pickWhen() async {
          final date = await showDatePicker(
            context: context,
            initialDate: spentAt,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 1)),
          );
          if (date == null || !context.mounted) return;
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(spentAt),
          );
          if (time == null) {
            setDialogState(() {
              spentAt = DateTime(date.year, date.month, date.day, spentAt.hour, spentAt.minute);
            });
            return;
          }
          setDialogState(() {
            spentAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          });
        }

        return AppDialog(
          title: editing ? l10n.edit : l10n.addCost,
          icon: Icons.receipt_long_outlined,
          content: AppFormColumn(
            children: [
              if (user?.isFounder == true && !editing)
                DropdownButtonFormField<String>(
                  value: branchId,
                  decoration: InputDecoration(labelText: l10n.navBranches),
                  items: [
                    for (final branch in branches)
                      DropdownMenuItem(value: branch.id, child: Text(branch.name)),
                  ],
                  onChanged: (v) => setDialogState(() => branchId = v),
                ),
              DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(labelText: l10n.costType),
                items: [
                  for (final key in _categories)
                    DropdownMenuItem(value: key, child: Text(_categoryLabel(l10n, key))),
                ],
                onChanged: (v) => setDialogState(() => category = v ?? 'rent'),
              ),
              if (category == 'teacher-payment')
                DropdownButtonFormField<String>(
                  value: teacherId,
                  decoration: InputDecoration(labelText: l10n.teacher),
                  items: [
                    for (final person in teachers)
                      DropdownMenuItem(value: person.id, child: Text(person.name)),
                  ],
                  onChanged: (v) => setDialogState(() => teacherId = v),
                ),
              TextField(
                controller: amountCtrl,
                decoration: InputDecoration(labelText: l10n.amount),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              InkWell(
                onTap: pickWhen,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.costDateTime,
                    suffixIcon: const Icon(Icons.event_outlined),
                  ),
                  child: Text(_formatCostWhen(spentAt)),
                ),
              ),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: category == 'other' ? '${l10n.otherCost} *' : l10n.notes,
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            AppDialogActions.cancel(dialogContext),
            AppDialogActions.confirm(
              dialogContext,
              label: l10n.save,
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                if (amount <= 0) return;
                if (!editing && user?.isFounder == true && (branchId == null || branchId!.isEmpty)) return;
                if (category == 'other' && notesCtrl.text.trim().isEmpty) return;
                try {
                  final payload = {
                    'category': category,
                    'amount': amount,
                    'notes': notesCtrl.text.trim(),
                    'spentAt': spentAt.toUtc().toIso8601String(),
                    if (category == 'teacher-payment' && teacherId != null) 'teacherId': teacherId,
                  };
                  if (editing) {
                    await ref.read(financeApiProvider).updateBranchExpense(expense.id, payload);
                  } else {
                    await ref.read(financeApiProvider).createBranchExpense({
                      ...payload,
                      'month': month,
                      'year': year,
                      if (branchId != null) 'branchId': branchId,
                    });
                  }
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('$e')));
                  }
                }
              },
            ),
          ],
        );
      },
    ),
  );

  amountCtrl.dispose();
  notesCtrl.dispose();
  if (saved == true) {
    ref.invalidate(branchExpensesProvider);
    ref.invalidate(branchCollectionsProvider);
    return true;
  }
  return false;
}
