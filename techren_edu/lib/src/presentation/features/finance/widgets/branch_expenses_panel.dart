import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/format_money.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../domain/entities/branch.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/finance_provider.dart';
import '../../../providers/identity_provider.dart';

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
              children: [
                Expanded(
                  child: Text(l10n.branchCosts, style: Theme.of(context).textTheme.titleMedium),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _addExpense(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addCost),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            async.when(
              loading: () => const LinearProgressIndicator(minHeight: 2),
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
                    const SizedBox(height: AppSpacing.sm),
                    for (final item in data.items)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(_categoryLabel(l10n, item.category)),
                        subtitle: Text(
                          [
                            if (item.branchName.isNotEmpty) item.branchName,
                            if (item.teacherName.isNotEmpty) item.teacherName,
                            if (item.notes.isNotEmpty) item.notes,
                          ].join(' · '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatUzs(item.amount)),
                            IconButton(
                              tooltip: l10n.delete,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () async {
                                try {
                                  await ref.read(financeApiProvider).deleteBranchExpense(item.id);
                                  ref.invalidate(branchExpensesProvider);
                                  ref.invalidate(branchCollectionsProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
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
    final l10n = context.l10n;
    final user = ref.read(authProvider).user;
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var category = 'rent';
    String? branchId = user?.isFounder == true ? null : user?.branchId;
    String? teacherId;

    final branches = user?.isFounder == true
        ? (await ref.read(branchesProvider(const PageMeta(limit: 100)).future)).items
        : <Branch>[];
    final teachers = (await ref.read(teachersProvider(const PageMeta(limit: 100)).future)).items;

    if (!context.mounted) return;

    final saved = await showAppDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AppDialog(
            title: l10n.addCost,
            icon: Icons.receipt_long_outlined,
            content: AppFormColumn(
              children: [
                if (user?.isFounder == true)
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
                  decoration: const InputDecoration(labelText: 'Type'),
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
                  decoration: InputDecoration(labelText: l10n.amountReceived),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  if (user?.isFounder == true && (branchId == null || branchId!.isEmpty)) return;
                  if (category == 'other' && notesCtrl.text.trim().isEmpty) return;
                  try {
                    await ref.read(financeApiProvider).createBranchExpense({
                      'category': category,
                      'amount': amount,
                      'month': month,
                      'year': year,
                      'notes': notesCtrl.text.trim(),
                      if (branchId != null) 'branchId': branchId,
                      if (category == 'teacher-payment' && teacherId != null) 'teacherId': teacherId,
                    });
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
    }
  }
}
