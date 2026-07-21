import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/notification_icon_button.dart';
import '../../../../core/widgets/staff_permissions.dart';
import '../../../../domain/entities/finance.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/finance_provider.dart';
import '../../../providers/identity_provider.dart';
import '../../../providers/staff_navigation_provider.dart';

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
    final notificationsRoute = isFounder ? '/founder/notifications' : '/admin/notifications';
    final canManagePayments = user != null && canAccessStaffRoute(user, '$prefix/more', rolePerms);

    return AdaptiveScaffold(
      title: 'Payments',
      selectedIndex: selectedIndex < 0 ? 3 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        NotificationIconButton(route: notificationsRoute),
      ],
      body: _PaymentsTab(
        search: _paymentsSearch,
        searchController: _paymentsSearchController,
        canManage: canManagePayments,
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
      messenger.showSnackBar(const SnackBar(content: Text('No students found')));
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
          title: 'Record Payment',
          icon: Icons.payments_outlined,
          content: AppFormColumn(
            children: [
              DropdownButtonFormField(
                value: selected.id,
                decoration: const InputDecoration(labelText: 'Student'),
                items: students.items.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (v) => setState(() => selected = students.items.firstWhere((s) => s.id == v)),
              ),
              TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
              TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: 'Subject')),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: selectedMonth,
                      decoration: const InputDecoration(labelText: 'Month'),
                      items: [
                        for (var i = 1; i <= 12; i++)
                          DropdownMenuItem(value: i, child: Text(_monthLabels[i - 1])),
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
                      decoration: const InputDecoration(labelText: 'Year'),
                      items: [
                        for (var y = DateTime.now().year + 1; y >= DateTime.now().year - 4; y--)
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
              label: 'Save',
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

const _monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _moneyLabel(double amount) {
  final rounded = amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
  return '\$$rounded';
}

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
    required this.onRecordPayment,
  });

  final String search;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchCleared;
  final bool canManage;
  final void Function(int month, int year) onRecordPayment;

  @override
  ConsumerState<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends ConsumerState<_PaymentsTab> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
  }

  PaymentRosterQuery get _query => (month: _month, year: _year, search: widget.search);

  void _resetFilters() {
    final now = DateTime.now();
    widget.searchController.clear();
    widget.onSearchCleared();
    setState(() {
      _month = now.month;
      _year = now.year;
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(paymentRosterProvider(_query));
    await ref.read(paymentRosterProvider(_query).future);
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
          title: 'Accept payment',
          icon: Icons.payments_outlined,
          content: AppFormColumn(
            children: [
              Text(student.name, style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${student.studentCode.isEmpty ? '' : '#${student.studentCode} · '}'
                '${_monthLabels[roster.month - 1]} ${roster.year}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (unpaidCourses.length > 1)
                DropdownButtonFormField<PaymentCourseStatus>(
                  value: selected,
                  decoration: const InputDecoration(labelText: 'Course'),
                  items: unpaidCourses
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text('${c.subjectName} — ${_moneyLabel(c.remaining)} left'),
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
                  decoration: const InputDecoration(labelText: 'Course / subject'),
                  readOnly: selected != null,
                ),
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount received'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              DropdownButtonFormField<String>(
                value: method,
                decoration: const InputDecoration(labelText: 'Method'),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                  DropdownMenuItem(value: 'transfer', child: Text('Bank transfer')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => setDialogState(() => method = v ?? 'cash'),
              ),
            ],
          ),
          actions: [
            AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context)),
            AppDialogActions.confirm(
              context,
              label: 'Record paid',
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
                      SnackBar(content: Text('Could not record payment: $e')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment recorded for ${student.name}')),
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
        FilledButton(onPressed: _resetFilters, child: const Text('Reset')),
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton(onPressed: _refresh, child: const Text('Refresh Data')),
        if (widget.canManage) ...[
          const SizedBox(width: AppSpacing.sm),
          FilledButton(onPressed: () => widget.onRecordPayment(_month, _year), child: const Text('Record')),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(paymentRosterProvider(_query));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 780;
              final searchField = TextField(
                controller: widget.searchController,
                decoration: _filterDecoration(
                  'Search Student',
                  hint: 'Name or ID',
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
                decoration: _filterDecoration('Month'),
                items: [
                  for (var i = 1; i <= 12; i++)
                    DropdownMenuItem(value: i, child: Text(_monthLabels[i - 1])),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _month = v);
                },
              );
              final yearField = DropdownButtonFormField<int>(
                value: _year,
                decoration: _filterDecoration('Year'),
                items: [
                  for (var y = DateTime.now().year + 1; y >= DateTime.now().year - 4; y--)
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
        ),
        Expanded(
          child: rosterAsync.when(
            loading: () => const LoadingState(kind: LoadingSkeletonKind.table),
            error: (e, _) => ListView(
              children: [
                SizedBox(height: AppSpacing.emptyStateTop),
                EmptyState(
                  title: 'Could not load payments',
                  message: '$e',
                  icon: Icons.error_outline,
                  action: TextButton(onPressed: _refresh, child: const Text('Retry')),
                ),
              ],
            ),
            data: (roster) {
              if (roster.items.isEmpty) {
                return ListView(
                  children: const [
                    SizedBox(height: AppSpacing.emptyStateTop),
                    EmptyState(
                      title: 'No students',
                      message: 'No active students match this month’s filters.',
                      icon: Icons.payments_outlined,
                    ),
                  ],
                );
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final useTable = constraints.maxWidth >= 800;
                  if (!useTable) {
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        padding: AppSpacing.listGutter,
                        itemCount: roster.items.length,
                        itemBuilder: (context, index) {
                          final row = roster.items[index];
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
                                        paid: row.isPaid,
                                        onAccept: row.isPaid
                                            ? null
                                            : () => _acceptPayment(
                                                  student: row,
                                                  roster: roster,
                                                ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final course in row.courses)
                                        _CoursePaymentChip(
                                          course: course,
                                          onTap: course.isPaid
                                              ? null
                                              : () => _acceptPayment(
                                                    student: row,
                                                    course: course,
                                                    roster: roster,
                                                  ),
                                        ),
                                      if (row.courses.isEmpty)
                                        Text(
                                          'No enrolled courses',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: AppSpacing.listGutter,
                      children: [
                        AppDataTable(
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
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      if (row.courses.isEmpty)
                                        Text('—', style: theme.textTheme.bodySmall),
                                      for (final course in row.courses)
                                        _CoursePaymentChip(
                                          course: course,
                                          onTap: course.isPaid
                                              ? null
                                              : () => _acceptPayment(
                                                    student: row,
                                                    course: course,
                                                    roster: roster,
                                                  ),
                                        ),
                                    ],
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: _OverallPaidLabel(
                                      paid: row.isPaid,
                                      onAccept: row.isPaid
                                          ? null
                                          : () => _acceptPayment(student: row, roster: roster),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CoursePaymentChip extends StatelessWidget {
  const _CoursePaymentChip({required this.course, this.onTap});

  final PaymentCourseStatus course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final paid = course.isPaid;
    final bg = paid ? AppColors.success.withValues(alpha: 0.15) : AppColors.error.withValues(alpha: 0.15);
    final fg = paid ? AppColors.success : AppColors.error;
    final label =
        '${course.subjectName} — ${_moneyLabel(course.amountPaid)} / ${_moneyLabel(course.amountDue)} (${_courseStatusLabel(course.status)})';

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
      message: 'Tap to accept payment',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: chip,
      ),
    );
  }
}

class _OverallPaidLabel extends StatelessWidget {
  const _OverallPaidLabel({required this.paid, this.onAccept});

  final bool paid;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: paid ? AppColors.success : AppColors.error,
      fontWeight: FontWeight.w700,
      height: 1.2,
    );
    final label = Text(paid ? 'Paid' : 'Unpaid', style: style);

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
