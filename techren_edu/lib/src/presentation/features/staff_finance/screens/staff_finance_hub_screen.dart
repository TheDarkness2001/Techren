import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/format_money.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/entity_list_card.dart';
import '../../../../core/widgets/paginated_scroll_body.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../../domain/entities/person.dart';
import '../../../../domain/entities/staff_finance.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/identity_provider.dart';
import '../../../providers/staff_finance_provider.dart';
import '../widgets/staff_finance_widgets.dart';

String formatSom(int amount) => formatUzs(amount);

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
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton.icon(
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: Text(
              'Manage staff earnings and payouts',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.semantic.textMuted,
                  ),
            ),
          ),
          if (widget.canManage)
            _StaffPicker(
              selectedId: _selectedStaffId,
              onChanged: (id) => setState(() => _selectedStaffId = id),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: StaffMemberPickerCard(
                name: ref.watch(authProvider).user?.name ?? 'My account',
                role: 'Your earnings',
                onTap: null,
              ),
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
              onViewPayouts: () => _tabs.animateTo(1),
            ),
            TabBar(
              controller: _tabs,
              labelColor: const Color(0xFFA5B4FC),
              indicatorColor: const Color(0xFF818CF8),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout sent. Staff must confirm they received the money.')));
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

  Future<void> _pick(BuildContext context, List<Person> items) async {
    final chosen = await showAppDialog<String>(
      context: context,
      builder: (context) => AppDialog(
        title: 'Select staff',
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final teacher in items)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    child: Text(
                      staffFinanceInitials(teacher.name),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFA5B4FC)),
                    ),
                  ),
                  title: Text(teacher.name),
                  subtitle: Text((teacher.role ?? 'Teacher').replaceAll('-', ' ')),
                  onTap: () => Navigator.pop(context, teacher.id),
                ),
            ],
          ),
        ),
        actions: [
          AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
    if (chosen != null) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teachersAsync = ref.watch(teachersProvider(const PageMeta(page: 1, limit: 50)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
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
          Person selected = items.first;
          for (final teacher in items) {
            if (teacher.id == selectedId) selected = teacher;
          }

          return StaffMemberPickerCard(
            name: selected.name,
            role: (selected.role ?? 'Teacher').replaceAll('-', ' '),
            onTap: () => _pick(context, items),
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
    this.onViewPayouts,
  });

  final String staffId;
  final bool canManage;
  final VoidCallback onAddBonus;
  final VoidCallback? onViewPayouts;

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

        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StaffFinanceSummaryStrip(account: account, onViewPayouts: onViewPayouts),
              if (empty && canManage) ...[
                const SizedBox(height: AppSpacing.sm),
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
        );
      },
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
              hintText: 'Search by type, status, or note...',
              prefixIcon: const Icon(Icons.search),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = earning.referenceDate ?? earning.createdAt;
    final note = (earning.description ?? earning.reason ?? '').trim();
    final dateText = date == null ? '—' : DateFormat('MMM d, yyyy').format(date.toLocal());

    return EntityListCard(
      title: note.isEmpty ? staffFinanceTypeLabel(earning.earningType) : note,
      subtitle: staffFinanceTypeLabel(earning.earningType),
      icon: Icons.payments_outlined,
      iconColor: AppColors.primarySoft,
      footer: StaffFinanceStatusPill(status: earning.status),
      metas: [
        EntityMeta(icon: Icons.payments_outlined, label: 'Amount', value: formatSom(earning.amount)),
        EntityMeta(icon: Icons.calendar_today_outlined, label: 'Date', value: dateText),
        EntityMeta(icon: Icons.person_outline, label: 'Staff', value: earning.staffName ?? 'Staff'),
      ],
      primaryAction: canManage && earning.status == 'pending'
          ? OutlinedButton(
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
            )
          : null,
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
              hintText: 'Search by type, status, or note...',
              prefixIcon: const Icon(Icons.search),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user?.id;
    final isRecipient = userId != null && userId == payout.staffId;
    final date = payout.createdAt;
    final dateText = date == null ? '—' : DateFormat('MMM d, yyyy').format(date.toLocal());

    return EntityListCard(
      title: payout.payoutRef.isEmpty ? 'Salary payout' : payout.payoutRef,
      subtitle: staffFinanceTypeLabel(payout.method),
      icon: Icons.account_balance_wallet_outlined,
      iconColor: AppColors.primarySoft,
      footer: StaffFinanceStatusPill(status: payout.status, isPayout: true),
      metas: [
        EntityMeta(icon: Icons.payments_outlined, label: 'Amount', value: formatSom(payout.amount)),
        EntityMeta(icon: Icons.calendar_today_outlined, label: 'Date issued', value: dateText),
        EntityMeta(icon: Icons.person_outline, label: 'Staff', value: payout.staffName ?? 'Staff'),
      ],
      primaryAction: isRecipient && payout.status == 'pending'
          ? FilledButton(
              onPressed: () => _confirmReceived(context, ref),
              child: const Text('Confirm receipt'),
            )
          : null,
      menu: canManage && payout.status == 'pending'
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'cancel') _cancelPayout(context, ref);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'cancel', child: Text('Cancel payout')),
              ],
            )
          : null,
    );
  }

  Future<void> _confirmReceived(BuildContext context, WidgetRef ref) async {
    final ok = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: 'Confirm you received this payout?',
        icon: Icons.check_circle_outline,
        content: Text(
          'This records that you received ${formatSom(payout.amount)} '
          '(${staffFinanceTypeLabel(payout.method)}).',
        ),
        actions: [
          AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context, false)),
          AppDialogActions.confirm(
            context,
            label: 'I received it',
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(staffFinanceApiProvider).confirmPayout(payout.id);
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payout confirmed')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
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
