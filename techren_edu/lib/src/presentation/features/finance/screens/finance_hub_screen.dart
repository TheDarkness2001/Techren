import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/academy_time.dart';
import '../../../../core/utils/format_money.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/staff_permissions.dart';
import '../../../../domain/entities/finance.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/finance_provider.dart';
import '../../../providers/identity_provider.dart';
import '../../../providers/staff_navigation_provider.dart';
import '../widgets/branch_collections_panel.dart';
import '../widgets/branch_expenses_panel.dart';

class FinanceHubScreen extends ConsumerStatefulWidget {
  const FinanceHubScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<FinanceHubScreen> createState() => _FinanceHubScreenState();
}

class _FinanceHubScreenState extends ConsumerState<FinanceHubScreen> {
  String _paymentsSearch = '';
  final _paymentsSearchController = TextEditingController();

  @override
  void dispose() {
    _paymentsSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));
    final isFounder = widget.selectedRoute.startsWith('/founder');
    final prefix = isFounder ? '/founder' : '/admin';
    final user = ref.watch(authProvider).user;
    final rolePerms = ref.watch(staffRolePermissionsProvider);
    final canManagePayments = user != null && canAccessStaffRoute(user, '$prefix/more', rolePerms);

    return AdaptiveScaffold(
      title: context.l10n.navPaymentsExams,
      selectedIndex: selectedIndex < 0 ? 3 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      body: _PaymentsTab(
        search: _paymentsSearch,
        searchController: _paymentsSearchController,
        canManage: canManagePayments,
        isFounder: isFounder,
        canManageExpenses: user?.isPrivilegedStaff == true,
        onRecordPayment: (month, year) => _showCreatePayment(context, month: month, year: year),
        onSearchSubmitted: (value) => setState(() => _paymentsSearch = value.trim()),
        onSearchCleared: () {
          _paymentsSearchController.clear();
          setState(() => _paymentsSearch = '');
        },
      ),
    );
  }

  Future<void> _showCreatePayment(
    BuildContext context, {
    required int month,
    required int year,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final students = await ref.read(studentsProvider(const PageMeta()).future);
    if (!context.mounted || students.items.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(context.l10n.noStudentsFound)));
      return;
    }

    var selected = students.items.first;
    var selectedMonth = month;
    var selectedYear = year;
    final amountCtrl = TextEditingController(text: '500000');
    final subjectCtrl = TextEditingController(text: 'English');

    final created = await showAppDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AppDialog(
          title: context.l10n.recordPayment,
          icon: Icons.payments_outlined,
          content: AppFormColumn(
            children: [
              DropdownButtonFormField(
                value: selected.id,
                decoration: InputDecoration(labelText: context.l10n.student),
                items: students.items.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (v) => setState(() => selected = students.items.firstWhere((s) => s.id == v)),
              ),
              TextField(controller: amountCtrl, decoration: InputDecoration(labelText: context.l10n.amount), keyboardType: TextInputType.number),
              TextField(controller: subjectCtrl, decoration: InputDecoration(labelText: context.l10n.subject)),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedMonth,
                      decoration: InputDecoration(labelText: context.l10n.month),
                      items: [
                        for (var i = 1; i <= 12; i++)
                          DropdownMenuItem(value: i, child: Text(context.l10n.monthShort(i))),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => selectedMonth = v);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedYear,
                      decoration: InputDecoration(labelText: context.l10n.year),
                      items: [
                        for (var y = AcademyTime.year + 1; y >= AcademyTime.year - 4; y--)
                          DropdownMenuItem(value: y, child: Text('$y')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => selectedYear = v);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context)),
            AppDialogActions.confirm(
              context,
              label: context.l10n.save,
              onPressed: () async {
                final now = DateTime.now();
                await ref.read(financeApiProvider).createPayment({
                  'studentId': selected.id,
                  'amount': double.tryParse(amountCtrl.text) ?? 0,
                  'paymentType': 'tuition-fee',
                  'subject': subjectCtrl.text,
                  'dueDate': now.toIso8601String(),
                  'academicYear': selectedMonth >= 9
                      ? '$selectedYear-${selectedYear + 1}'
                      : '${selectedYear - 1}-$selectedYear',
                  'term': selectedMonth >= 9 && selectedMonth <= 12
                      ? '1st-term'
                      : selectedMonth <= 5
                          ? '2nd-term'
                          : '3rd-term',
                  'month': selectedMonth,
                  'year': selectedYear,
                  'status': 'paid',
                });
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    );

    if (created == true) {
      ref.invalidate(paymentsProvider);
      ref.invalidate(paymentRosterProvider);
      ref.invalidate(revenueSummaryProvider);
      ref.invalidate(pendingPaymentsProvider);
    }
  }
}


String _moneyLabel(double amount) => formatUzs(amount);

String _courseStatusLabel(String status) {
  switch (status) {
    case 'paid':
      return 'Paid';
    case 'partial':
      return 'Partial';
    default:
      return 'Unpaid';
  }
}

class _PaymentsTab extends ConsumerStatefulWidget {
  const _PaymentsTab({
    required this.search,
    required this.searchController,
    required this.onSearchSubmitted,
    required this.onSearchCleared,
    required this.canManage,
    required this.isFounder,
    required this.canManageExpenses,
    required this.onRecordPayment,
  });

  final String search;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchCleared;
  final bool canManage;
  final bool isFounder;
  final bool canManageExpenses;
  final void Function(int month, int year) onRecordPayment;

  @override
  ConsumerState<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends ConsumerState<_PaymentsTab> {
  late int _month;
  late int _year;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _month = AcademyTime.month;
    _year = AcademyTime.year;
  }

  PaymentRosterQuery get _query => (month: _month, year: _year, search: widget.search);

  void _resetFilters() {
    final now = AcademyTime.now();
    widget.searchController.clear();
    widget.onSearchCleared();
    setState(() {
      _month = now.month;
      _year = now.year;
    });
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    final typed = widget.searchController.text.trim();
    if (typed != widget.search) {
      widget.onSearchSubmitted(typed);
    }
    setState(() => _refreshing = true);
    try {
      ref.invalidate(paymentRosterProvider);
      await ref.refresh(paymentRosterProvider((
        month: _month,
        year: _year,
        search: typed,
      )).future);
      if (widget.isFounder) {
        ref.invalidate(branchCollectionsProvider);
        await ref.refresh(branchCollectionsProvider((month: _month, year: _year)).future);
      }
      if (widget.canManageExpenses) {
        ref.invalidate(branchExpensesProvider);
        await ref.refresh(branchExpensesProvider((month: _month, year: _year)).future);
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _acceptPayment({
    required PaymentRosterRow student,
    PaymentCourseStatus? course,
    required PaymentRosterResult roster,
  }) async {
    final unpaidCourses = student.courses.where((c) => !c.isPaid).toList();
    var selected = course ?? (unpaidCourses.isNotEmpty ? unpaidCourses.first : null);
    if (selected == null && unpaidCourses.isEmpty && student.courses.isNotEmpty) {
      return;
    }

    final amountCtrl = TextEditingController(
      text: selected != null
          ? (selected.remaining > 0 ? selected.remaining : selected.amountDue).toStringAsFixed(0)
          : '',
    );
    final subjectCtrl = TextEditingController(text: selected?.subjectName ?? '');
    var method = 'cash';

    final recorded = await showAppDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialog(
          title: context.l10n.acceptPayment,
          icon: Icons.payments_outlined,
          content: AppFormColumn(
            children: [
              Text(student.name, style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${student.studentCode.isEmpty ? '' : '#${student.studentCode} · '}'
                '${context.l10n.monthShort(roster.month)} ${roster.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (unpaidCourses.length > 1)
                DropdownButtonFormField<PaymentCourseStatus>(
                  value: selected,
                  decoration: InputDecoration(labelText: context.l10n.course),
                  items: unpaidCourses
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.subjectName} — ${context.l10n.remainingLeft(_moneyLabel(c.remaining))}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setDialogState(() {
                      selected = v;
                      subjectCtrl.text = v.subjectName;
                      amountCtrl.text =
                          (v.remaining > 0 ? v.remaining : v.amountDue).toStringAsFixed(0);
                    });
                  },
                )
              else
                TextField(
                  controller: subjectCtrl,
                  decoration: InputDecoration(labelText: context.l10n.courseOrSubject),
                  readOnly: selected != null,
                ),
              TextField(
                controller: amountCtrl,
                decoration: InputDecoration(labelText: context.l10n.amountReceived),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              DropdownButtonFormField<String>(
                value: method,
                decoration: InputDecoration(labelText: context.l10n.method),
                items: [
                  DropdownMenuItem(value: 'cash', child: Text(context.l10n.methodCash)),
                  DropdownMenuItem(value: 'card', child: Text(context.l10n.methodCard)),
                  DropdownMenuItem(value: 'transfer', child: Text(context.l10n.methodBankTransfer)),
                  DropdownMenuItem(value: 'other', child: Text(context.l10n.methodOther)),
                ],
                onChanged: (v) => setDialogState(() => method = v ?? 'cash'),
              ),
            ],
          ),
          actions: [
            AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context)),
            AppDialogActions.confirm(
              context,
              label: context.l10n.recordPaid,
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                final subject = (selected?.subjectName ?? subjectCtrl.text).trim();
                if (amount <= 0 || subject.isEmpty) return;
                try {
                  await ref.read(financeApiProvider).createPayment({
                    'studentId': student.id,
                    'amount': amount,
                    'paymentType': 'tuition-fee',
                    'paymentMethod': method,
                    'subject': subject,
                    'dueDate': DateTime.now().toIso8601String(),
                    'academicYear': roster.academicYear,
                    'term': roster.term,
                    'month': roster.month,
                    'year': roster.year,
                    'status': 'paid',
                  });
                  if (context.mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.couldNotRecordPayment('$e'))),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );

    amountCtrl.dispose();
    subjectCtrl.dispose();

    if (recorded == true && mounted) {
      ref.invalidate(paymentRosterProvider);
      ref.invalidate(paymentsProvider);
      ref.invalidate(revenueSummaryProvider);
      ref.invalidate(pendingPaymentsProvider);
      if (widget.isFounder) ref.invalidate(branchCollectionsProvider);
      if (widget.canManageExpenses) ref.invalidate(branchExpensesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.paymentRecordedFor(student.name))),
      );
    }
  }

  InputDecoration _filterDecoration(String label, {String? hint, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      border: const OutlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _filterActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton(onPressed: _resetFilters, child: Text(context.l10n.reset)),
        const SizedBox(width: AppSpacing.sm),
        FilledButton.tonalIcon(
          onPressed: _refreshing ? null : _refresh,
          icon: _refreshing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh, size: 18),
          label: Text(context.l10n.refreshData),
        ),
        if (widget.canManage) ...[
          const SizedBox(width: AppSpacing.sm),
          FilledButton(onPressed: () => widget.onRecordPayment(_month, _year), child: Text(context.l10n.record)),
        ],
      ],
    );
  }

  Widget _filtersBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 780;
          final searchField = TextField(
            controller: widget.searchController,
            decoration: _filterDecoration(
              context.l10n.searchStudent,
              hint: context.l10n.nameOrId,
              suffix: widget.search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: widget.onSearchCleared,
                    )
                  : null,
            ),
            onSubmitted: widget.onSearchSubmitted,
          );
          final monthField = DropdownButtonFormField<int>(
            value: _month,
            decoration: _filterDecoration(context.l10n.month),
            items: [
              for (var i = 1; i <= 12; i++)
                DropdownMenuItem(value: i, child: Text(context.l10n.monthShort(i))),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _month = v);
            },
          );
          final yearField = DropdownButtonFormField<int>(
            value: _year,
            decoration: _filterDecoration(context.l10n.year),
            items: [
              for (var y = AcademyTime.year + 1; y >= AcademyTime.year - 4; y--)
                DropdownMenuItem(value: y, child: Text('$y')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _year = v);
            },
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 3, child: searchField),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(width: 120, child: monthField),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(width: 120, child: yearField),
                const SizedBox(width: AppSpacing.sm),
                _filterActions(),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: monthField),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: yearField),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(alignment: Alignment.centerRight, child: _filterActions()),
            ],
          );
        },
      ),
    );
  }

  Widget _studentCard(PaymentRosterResult roster, PaymentRosterRow row, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${row.studentCode.isEmpty ? '' : '#${row.studentCode}  '}${row.name}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                _OverallPaidLabel(
                  status: row.hasBillableCourses ? row.summaryStatus : 'none',
                  onAccept: row.isPaid || !row.hasBillableCourses
                      ? null
                      : () => _acceptPayment(student: row, roster: roster),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _StudentPaymentSummaryChip(
              row: row,
              onTap: row.isPaid
                  ? null
                  : () => _acceptPayment(student: row, roster: roster),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentTable(PaymentRosterResult roster) {
    return AppDataTable(
      columns: const ['Student ID', 'Name', 'Courses', 'Paid?'],
      rows: [
        for (final row in roster.items)
          AppDataRow(
            cells: [
              Text(
                row.studentCode.isEmpty ? '—' : '#${row.studentCode}',
                overflow: TextOverflow.ellipsis,
              ),
              Text(row.name, overflow: TextOverflow.ellipsis),
              _StudentPaymentSummaryChip(
                row: row,
                onTap: row.isPaid ? null : () => _acceptPayment(student: row, roster: roster),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: _OverallPaidLabel(
                  status: row.hasBillableCourses ? row.summaryStatus : 'none',
                  onAccept: row.isPaid || !row.hasBillableCourses
                      ? null
                      : () => _acceptPayment(student: row, roster: roster),
                ),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(paymentRosterProvider(_query));
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTable = constraints.maxWidth >= 800;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (_refreshing)
                const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2)),
              SliverToBoxAdapter(child: _filtersBar()),
              if (widget.isFounder)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                    child: BranchCollectionsPanel(month: _month, year: _year),
                  ),
                ),
              if (widget.canManageExpenses)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                    child: BranchExpensesPanel(month: _month, year: _year),
                  ),
                ),
              ...rosterAsync.when(
                loading: () => [
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: LoadingState(kind: LoadingSkeletonKind.table),
                  ),
                ],
                error: (e, _) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      title: context.l10n.couldNotLoadPayments,
                      message: '$e',
                      icon: Icons.error_outline,
                      action: TextButton(onPressed: _refresh, child: Text(context.l10n.retry)),
                    ),
                  ),
                ],
                data: (roster) {
                  if (roster.items.isEmpty) {
                    return [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          title: context.l10n.noStudents,
                          message: context.l10n.noStudentsMatchFilters,
                          icon: Icons.payments_outlined,
                        ),
                      ),
                    ];
                  }
                  return [
                    SliverPadding(
                      padding: AppSpacing.listGutter,
                      sliver: useTable
                          ? SliverToBoxAdapter(child: _studentTable(roster))
                          : SliverList.builder(
                              itemCount: roster.items.length,
                              itemBuilder: (context, index) =>
                                  _studentCard(roster, roster.items[index], theme),
                            ),
                    ),
                  ];
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StudentPaymentSummaryChip extends StatelessWidget {
  const _StudentPaymentSummaryChip({required this.row, this.onTap});

  final PaymentRosterRow row;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (!row.hasBillableCourses) {
      return Text('—', style: Theme.of(context).textTheme.bodySmall);
    }

    final status = row.summaryStatus;
    final paid = status == 'paid';
    final partial = status == 'partial';
    final bg = paid
        ? AppColors.success.withValues(alpha: 0.15)
        : partial
            ? AppColors.warning.withValues(alpha: 0.18)
            : AppColors.error.withValues(alpha: 0.15);
    final fg = paid
        ? AppColors.success
        : partial
            ? AppColors.warning
            : AppColors.error;
    // Paid rows lead with the monthly due (not receipts), so a 600 fee never
    // reads as "1 200" when older overpayments exist.
    final money = paid
        ? '${_moneyLabel(row.totalDue)} (${_courseStatusLabel(status)})'
        : '${_moneyLabel(row.totalPaid)} / ${_moneyLabel(row.totalDue)} (${_courseStatusLabel(status)})';
    final label = row.courses.length == 1
        ? '${row.courses.first.subjectName} — $money'
        : row.courses.length == 2
            ? '${row.courses.map((c) => c.subjectName).join(' + ')} — $money'
            : '${row.courses.length} subjects — $money';

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );

    if (onTap == null) return chip;
    return Tooltip(
      message: row.courses.length > 1
          ? 'Tap to accept payment — choose the subject in the dialog'
          : 'Tap to accept payment',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: chip,
      ),
    );
  }
}

class _OverallPaidLabel extends StatelessWidget {
  const _OverallPaidLabel({required this.status, this.onAccept});

  final String status;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    if (status == 'none') {
      return Text('—', style: Theme.of(context).textTheme.bodySmall);
    }
    final paid = status == 'paid';
    final partial = status == 'partial';
    final style = TextStyle(
      color: paid
          ? AppColors.success
          : partial
              ? AppColors.warning
              : AppColors.error,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
    final label = Text(_courseStatusLabel(status), style: style);

    if (paid || onAccept == null) {
      return label;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onAccept,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: label,
        ),
      ),
    );
  }
}
