import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/paginated_scroll_body.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../../domain/entities/staff_finance.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/identity_provider.dart';
import '../../../providers/staff_finance_provider.dart';

String formatSom(int amount) {
  final text = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(text[i]);
  }
  return "${buffer.toString()} so'm";
}

class StaffFinanceHubScreen extends ConsumerStatefulWidget {
  const StaffFinanceHubScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
    this.canManage = false,
    this.staffId,
  });

  final List<NavItem> navItems;
  final String selectedRoute;
  final bool canManage;
  final String? staffId;

  @override
  ConsumerState<StaffFinanceHubScreen> createState() => _StaffFinanceHubScreenState();
}

class _StaffFinanceHubScreenState extends ConsumerState<StaffFinanceHubScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String? _selectedStaffId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _selectedStaffId = widget.staffId;
  }

  String? get _effectiveStaffId {
    if (!widget.canManage) {
      return ref.read(authProvider).user?.id;
    }
    return _selectedStaffId;
  }

  void _refresh() {
    final staffId = _effectiveStaffId;
    ref.invalidate(staffAccountProvider(staffId));
    ref.invalidate(staffEarningsProvider);
    ref.invalidate(staffPayoutsProvider);
    if (staffId != null) ref.invalidate(staffApprovedEarningsProvider(staffId));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));
    final staffId = _effectiveStaffId;

    return AdaptiveScaffold(
      title: 'Staff Finance',
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        if (widget.canManage && staffId != null)
          TextButton(
            onPressed: () => _showAddSheet(context),
            child: const Text('Add'),
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.canManage)
            _StaffPicker(
              selectedId: _selectedStaffId,
              onChanged: (id) => setState(() => _selectedStaffId = id),
            ),
          if (staffId == null)
            const Expanded(
              child: EmptyState(
                title: 'Select staff',
                message: 'Choose a staff member to view earnings and payouts.',
                icon: Icons.people_outline,
              ),
            )
          else ...[
            _AccountSummaryCard(
              staffId: staffId,
              canManage: widget.canManage,
              onAddBonus: () => _showBonusDialog(context, staffId),
            ),
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'Earnings'),
                Tab(text: 'Payouts'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _EarningsTab(key: ValueKey('e-$staffId'), staffId: staffId, canManage: widget.canManage, onChanged: _refresh),
                  _PayoutsTab(key: ValueKey('p-$staffId'), staffId: staffId, canManage: widget.canManage, onChanged: _refresh),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final staffId = _effectiveStaffId;
    if (staffId == null) return;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Add bonus'),
              subtitle: const Text('Grant a one-off earning'),
              onTap: () {
                Navigator.pop(ctx);
                _showBonusDialog(context, staffId);
              },
            ),
            ListTile(
              title: const Text('Create payout'),
              subtitle: const Text('Pay out approved earnings'),
              onTap: () {
                Navigator.pop(ctx);
                _showCreatePayoutDialog(context, staffId);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBonusDialog(BuildContext context, String staffId) async {
    final amountCtrl = TextEditingController(text: '10000');
    final reasonCtrl = TextEditingController(text: 'Excellent performance this month');

    final saved = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: 'Add bonus',
        content: AppFormColumn(
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (so\'m)'),
            ),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Reason (min 10 chars)'),
            ),
          ],
        ),
        actions: [
          AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context, false)),
          AppDialogActions.confirm(context, label: 'Save', onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    try {
      await ref.read(staffFinanceApiProvider).addBonus(
            staffId: staffId,
            amount: int.parse(amountCtrl.text),
            reason: reasonCtrl.text,
          );
      _refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bonus added — approve it under Earnings')));
        _tabs.animateTo(0);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _showCreatePayoutDialog(BuildContext context, String staffId) async {
    final approved = await ref.read(staffApprovedEarningsProvider(staffId).future);
    if (!context.mounted) return;
    if (approved.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No approved earnings. Add a bonus and approve it first.')),
      );
      return;
    }

    final selected = <String>{approved.first.id};
    String method = 'cash';

    final created = await showAppDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AppDialog(
          title: 'Create payout',
          maxWidth: 520,
          content: SingleChildScrollView(
            child: AppFormColumn(
              children: [
                Text('Select approved earnings', style: Theme.of(context).textTheme.titleSmall),
                ...approved.map(
                  (e) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: selected.contains(e.id),
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        selected.add(e.id);
                      } else {
                        selected.remove(e.id);
                      }
                    }),
                    title: Text(formatSom(e.amount)),
                    subtitle: Text(e.description ?? e.earningType),
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(labelText: 'Method'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'bank-transfer', child: Text('Bank transfer')),
                    DropdownMenuItem(value: 'uzcard', child: Text('Uzcard')),
                    DropdownMenuItem(value: 'humo', child: Text('Humo')),
                  ],
                  onChanged: (v) => setState(() => method = v ?? 'cash'),
                ),
              ],
            ),
          ),
          actions: [
            AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context, false)),
            AppDialogActions.confirm(
              context,
              label: 'Create',
              onPressed: selected.isEmpty ? null : () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    );

    if (created != true || !context.mounted) return;

    try {
      await ref.read(staffFinanceApiProvider).createPayout(
            staffId: staffId,
            earningIds: selected.toList(),
            method: method,
          );
      _refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout created — complete it under Payouts')));
        _tabs.animateTo(1);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _StaffPicker extends ConsumerWidget {
  const _StaffPicker({required this.selectedId, required this.onChanged});

  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersAsync = ref.watch(teachersProvider(const PageMeta(page: 1, limit: 50)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      child: teachersAsync.when(
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error: (e, _) => Text('Could not load staff: $e'),
        data: (result) {
          final items = result.items;
          if (items.isEmpty) {
            return Text('No staff members found', style: Theme.of(context).textTheme.bodyMedium);
          }
          if (selectedId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(items.first.id));
          }
          final value = items.any((t) => t.id == selectedId) ? selectedId : items.first.id;

          return DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Staff member',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: [
              for (final teacher in items)
                DropdownMenuItem(value: teacher.id, child: Text(teacher.name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: onChanged,
          );
        },
      ),
    );
  }
}

class _AccountSummaryCard extends ConsumerWidget {
  const _AccountSummaryCard({
    required this.staffId,
    required this.canManage,
    required this.onAddBonus,
  });

  final String staffId;
  final bool canManage;
  final VoidCallback onAddBonus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(staffAccountProvider(staffId));
    final muted = context.semantic.textMuted;

    return accountAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: EmptyState(
          title: 'Could not load account',
          message: '$e',
          icon: Icons.error_outline,
          action: FilledButton(
            onPressed: () => ref.invalidate(staffAccountProvider(staffId)),
            child: const Text('Retry'),
          ),
        ),
      ),
      data: (account) {
        final empty = account.totalEarned == 0 &&
            account.availableForPayout == 0 &&
            account.pendingEarnings == 0 &&
            account.totalPaidOut == 0;

        return Card(
          margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Account summary', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 560;
                    final stats = [
                      _SummaryStat(label: 'Total earned', value: formatSom(account.totalEarned)),
                      _SummaryStat(
                        label: 'Available',
                        value: formatSom(account.availableForPayout),
                        emphasize: true,
                      ),
                      _SummaryStat(label: 'Pending', value: formatSom(account.pendingEarnings)),
                      _SummaryStat(label: 'Paid out', value: formatSom(account.totalPaidOut)),
                    ];
                    if (wide) {
                      return Row(
                        children: [
                          for (var i = 0; i < stats.length; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpacing.md),
                            Expanded(child: stats[i]),
                          ],
                        ],
                      );
                    }
                    return Wrap(
                      spacing: AppSpacing.lg,
                      runSpacing: AppSpacing.sm,
                      children: stats,
                    );
                  },
                ),
                if (empty && canManage) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'No balance yet. Add a bonus, approve it in Earnings, then create a payout.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(onPressed: onAddBonus, child: const Text('Add bonus')),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    final valueColor = emphasize ? AppColors.primary : Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}

class _EarningsTab extends ConsumerStatefulWidget {
  const _EarningsTab({super.key, required this.staffId, required this.canManage, required this.onChanged});

  final String staffId;
  final bool canManage;
  final VoidCallback onChanged;

  @override
  ConsumerState<_EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends ConsumerState<_EarningsTab> {
  String _search = '';
  final _searchController = TextEditingController();

  StaffEarningsQuery get _baseQuery => (staffId: widget.staffId, page: 1, search: _search);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseQuery = _baseQuery;

    return Column(
      children: [
        Padding(
          padding: AppSpacing.searchBarPadding,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search earnings by type, status, or note',
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            onSubmitted: (value) => setState(() => _search = value.trim()),
          ),
        ),
        Expanded(
          child: PaginatedScrollBody<StaffEarningEntry, StaffEarningsQuery>(
            provider: staffEarningsProvider,
            query: baseQuery,
            withPage: (q, page) => (staffId: q.staffId, page: page, search: q.search),
            queryCacheKey: '${widget.staffId}|$_search',
            onInvalidate: (ref, q) => ref.invalidate(staffEarningsProvider(q)),
            itemLabel: 'earnings',
            initialLoadingKind: LoadingSkeletonKind.list,
            empty: ListView(
              children: const [
                SizedBox(height: AppSpacing.emptyStateTop),
                EmptyState(
                  title: 'No earnings yet',
                  message: 'Add a bonus or wait for salary entries to appear here.',
                  icon: Icons.savings_outlined,
                ),
              ],
            ),
            builder: (context, controller, items, state) => ListView.builder(
              controller: controller,
              padding: AppSpacing.listGutter,
              itemCount: items.length,
              itemBuilder: (_, i) => _EarningTile(
                earning: items[i],
                canManage: widget.canManage,
                onChanged: widget.onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EarningTile extends ConsumerWidget {
  const _EarningTile({required this.earning, required this.canManage, required this.onChanged});

  final StaffEarningEntry earning;
  final bool canManage;
  final VoidCallback onChanged;

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'paid':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(earning.status);
    final note = (earning.description ?? earning.reason ?? '').trim();

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(formatSom(earning.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          [
            earning.earningType.replaceAll('-', ' '),
            if (note.isNotEmpty) note,
          ].join(' · '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              earning.status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
            ),
            if (canManage && earning.status == 'pending') ...[
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: () async {
                  try {
                    await ref.read(staffFinanceApiProvider).approveEarning(earning.id);
                    onChanged();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                child: const Text('Approve'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PayoutsTab extends ConsumerStatefulWidget {
  const _PayoutsTab({super.key, required this.staffId, required this.canManage, required this.onChanged});

  final String staffId;
  final bool canManage;
  final VoidCallback onChanged;

  @override
  ConsumerState<_PayoutsTab> createState() => _PayoutsTabState();
}

class _PayoutsTabState extends ConsumerState<_PayoutsTab> {
  String _search = '';
  final _searchController = TextEditingController();

  StaffPayoutsQuery get _baseQuery => (staffId: widget.staffId, page: 1, search: _search);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseQuery = _baseQuery;

    return Column(
      children: [
        Padding(
          padding: AppSpacing.searchBarPadding,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search payouts by reference, method, or status',
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            onSubmitted: (value) => setState(() => _search = value.trim()),
          ),
        ),
        Expanded(
          child: PaginatedScrollBody<StaffPayoutEntry, StaffPayoutsQuery>(
            provider: staffPayoutsProvider,
            query: baseQuery,
            withPage: (q, page) => (staffId: q.staffId, page: page, search: q.search),
            queryCacheKey: '${widget.staffId}|$_search',
            onInvalidate: (ref, q) => ref.invalidate(staffPayoutsProvider(q)),
            itemLabel: 'payouts',
            initialLoadingKind: LoadingSkeletonKind.list,
            empty: ListView(
              children: const [
                SizedBox(height: AppSpacing.emptyStateTop),
                EmptyState(
                  title: 'No payouts yet',
                  message: 'Create a payout from approved earnings using Add.',
                  icon: Icons.payments_outlined,
                ),
              ],
            ),
            builder: (context, controller, items, state) => ListView.builder(
              controller: controller,
              padding: AppSpacing.listGutter,
              itemCount: items.length,
              itemBuilder: (_, i) => _PayoutTile(
                payout: items[i],
                canManage: widget.canManage,
                onChanged: widget.onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PayoutTile extends ConsumerWidget {
  const _PayoutTile({required this.payout, required this.canManage, required this.onChanged});

  final StaffPayoutEntry payout;
  final bool canManage;
  final VoidCallback onChanged;

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(payout.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(payout.payoutRef, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${payout.method.replaceAll('-', ' ')} · ${formatSom(payout.amount)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              payout.status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
            ),
            if (canManage && payout.status == 'pending') ...[
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: () async {
                  try {
                    await ref.read(staffFinanceApiProvider).completePayout(payout.id);
                    onChanged();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                child: const Text('Complete'),
              ),
              TextButton(
                onPressed: () => _cancelPayout(context, ref),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _cancelPayout(BuildContext context, WidgetRef ref) async {
    final reasonCtrl = TextEditingController(text: 'Cancelled due to incorrect selection');
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: 'Cancel payout',
        iconColor: AppColors.danger,
        content: TextField(
          controller: reasonCtrl,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Reason (min 10 chars)'),
        ),
        actions: [
          AppDialogActions.cancel(context, label: 'Back', onPressed: () => Navigator.pop(context, false)),
          AppDialogActions.confirm(
            context,
            label: 'Cancel payout',
            destructive: true,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(staffFinanceApiProvider).cancelPayout(payout.id, reasonCtrl.text);
      onChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
