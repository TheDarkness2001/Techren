import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/go_back_icon_button.dart';
import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/paginated_scroll_body.dart';
import '../../../../core/widgets/wallet_feature_gate.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../../domain/entities/person.dart';
import '../../../../domain/entities/wallet.dart';
import '../../../providers/identity_provider.dart';
import '../../../providers/wallet_provider.dart';

class StudentWalletScreen extends ConsumerStatefulWidget {
  const StudentWalletScreen({
    super.key,
    this.navItems,
    required this.selectedRoute,
    this.selectedIndex = 4,
  });

  final List<NavItem>? navItems;
  final String selectedRoute;
  final int selectedIndex;

  @override
  ConsumerState<StudentWalletScreen> createState() => _StudentWalletScreenState();
}

class _StudentWalletScreenState extends ConsumerState<StudentWalletScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  WalletTransactionsQuery get _transactionsQuery => (studentId: null, page: 1, search: _search);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(walletBalanceProvider);
    ref.invalidate(walletTransactionsProvider(_transactionsQuery));
  }

  @override
  Widget build(BuildContext context) {
    final navItems = widget.navItems ?? studentNavItemsOf(context);
    final balanceAsync = ref.watch(walletBalanceProvider);
    final baseQuery = _transactionsQuery;
    final index = navItems.indexWhere((i) => widget.selectedRoute.startsWith(i.route));

    return AdaptiveScaffold(
      title: 'My Wallet',
      selectedIndex: index >= 0 ? index : widget.selectedIndex,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        GoBackIconButton(fallbackRoute: '/student/profile'),
      ],
      body: WalletFeatureGate(
        child: Column(
          children: [
            Padding(
              padding: AppSpacing.pageHeaderPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  balanceAsync.when(
                    loading: () => const Card(child: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: LoadingState(kind: LoadingSkeletonKind.card))),
                    error: (e, _) => Card(
                      child: ErrorState.fromError(e, onRetry: _refresh),
                    ),
                    data: (balance) => Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Available balance', style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              "${balance.balanceSom.toStringAsFixed(0)} so'm",
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (balance.isLocked) ...[
                              const SizedBox(height: AppSpacing.xs),
                              const Chip(
                                avatar: Icon(Icons.lock, size: 16),
                                label: Text('Wallet locked'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Top up', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Self-service top-up is unavailable. Ask academy staff to credit your wallet after payment.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search transactions by type or description',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (value) => setState(() => _search = value.trim()),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Transaction history', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
            ),
            Expanded(
              child: PaginatedScrollBody<WalletTransaction, WalletTransactionsQuery>(
                provider: walletTransactionsProvider,
                query: baseQuery,
                withPage: (q, page) => (studentId: q.studentId, page: page, search: q.search),
                queryCacheKey: _search,
                onInvalidate: (ref, q) => ref.invalidate(walletTransactionsProvider(q)),
                itemLabel: 'transactions',
                initialLoadingKind: LoadingSkeletonKind.list,
                empty: ListView(
                  children: const [
                    SizedBox(height: AppSpacing.emptyStateTop),
                    EmptyState(
                      title: 'No transactions yet',
                      message: 'Your wallet activity will appear here.',
                      icon: Icons.receipt_long_outlined,
                    ),
                  ],
                ),
                builder: (context, controller, items, state) => ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _TransactionTile(transaction: items[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final color = transaction.isCredit ? AppColors.success : AppColors.error;
    final prefix = transaction.isCredit ? '+' : '-';

    return AppAdminRowCard(
      title: transaction.description?.isNotEmpty == true ? transaction.description! : transaction.type,
      subtitle: transaction.createdAt.toLocal().toString().split('.').first,
      icon: transaction.isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
      accentColor: color,
      trailing: Text(
        '$prefix${transaction.amountSom.toStringAsFixed(0)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class AdminWalletScreen extends ConsumerStatefulWidget {
  const AdminWalletScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<AdminWalletScreen> createState() => _AdminWalletScreenState();
}

class _AdminWalletScreenState extends ConsumerState<AdminWalletScreen> {
  String? _selectedStudentId;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  String _deductType = 'deduction';
  bool _submitting = false;
  String _search = '';

  WalletTransactionsQuery _transactionsQuery(String studentId) =>
      (studentId: studentId, page: 1, search: _search);

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _selectStudent(String? id) {
    setState(() {
      _selectedStudentId = id;
      _search = '';
      _searchController.clear();
    });
  }

  Future<void> _deduct() async {
    if (_selectedStudentId == null) return;
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    setState(() => _submitting = true);
    try {
      await ref.read(walletApiProvider).deduct(
            studentId: _selectedStudentId!,
            amountSom: amount,
            type: _deductType,
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          );
      _amountController.clear();
      _descriptionController.clear();
      ref.invalidate(adminWalletBalanceProvider(_selectedStudentId!));
      ref.invalidate(walletTransactionsProvider(_transactionsQuery(_selectedStudentId!)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deduction recorded')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const studentPickerQuery = PageMeta(page: 1, limit: 20);
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));
    final balanceAsync = _selectedStudentId == null
        ? null
        : ref.watch(adminWalletBalanceProvider(_selectedStudentId!));
    final transactionsQuery = _selectedStudentId == null ? null : _transactionsQuery(_selectedStudentId!);

    return AdaptiveScaffold(
      title: 'Student Wallets',
      selectedIndex: selectedIndex < 0 ? 3 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, widget.navItems, i),
      body: WalletFeatureGate(
        child: Column(
          children: [
            SizedBox(
              height: 160,
              child: PaginatedScrollBody<Person, PageMeta>(
                provider: studentsProvider,
                query: studentPickerQuery,
                withPage: (q, page) => q.copyWith(page: page),
                queryCacheKey: 'admin-wallet-students',
                onInvalidate: (ref, q) => ref.invalidate(studentsProvider(q)),
                itemLabel: 'students',
                initialLoadingKind: LoadingSkeletonKind.list,
                builder: (context, controller, items, state) => ListView.builder(
                  controller: controller,
                  padding: AppSpacing.pageHeaderPadding,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final student = items[i];
                    return ListTile(
                      title: Text('${student.name} (${student.displayId ?? student.id})'),
                      selected: _selectedStudentId == student.id,
                      onTap: () => _selectStudent(student.id),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: _selectedStudentId == null
                  ? const Center(child: Text('Select a student'))
                  : Column(
                      children: [
                        SingleChildScrollView(
                          padding: AppSpacing.listGutter,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              balanceAsync!.when(
                                loading: () => const LoadingState(kind: LoadingSkeletonKind.card),
                                error: (e, _) => Text(e.toString()),
                                data: (balance) => Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.account_balance_wallet_outlined),
                                    title: Text("${balance.balanceSom.toStringAsFixed(0)} so'm"),
                                    subtitle: Text(balance.isLocked ? 'Locked' : 'Active'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: AppFormColumn(
                                    children: [
                                      Text('Credit / deduct', style: Theme.of(context).textTheme.titleMedium),
                                      DropdownButtonFormField<String>(
                                        value: _deductType,
                                        decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                                        items: const [
                                          DropdownMenuItem(value: 'topup', child: Text('Credit (top-up)')),
                                          DropdownMenuItem(value: 'refund', child: Text('Refund')),
                                          DropdownMenuItem(value: 'deduction', child: Text('Deduction')),
                                          DropdownMenuItem(value: 'penalty', child: Text('Penalty')),
                                          DropdownMenuItem(value: 'adjustment', child: Text('Adjustment')),
                                        ],
                                        onChanged: (v) => setState(() => _deductType = v ?? 'deduction'),
                                      ),
                                      TextField(
                                        controller: _amountController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                        decoration: const InputDecoration(
                                          labelText: 'Amount (so\'m)',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      TextField(
                                        controller: _descriptionController,
                                        decoration: const InputDecoration(
                                          labelText: 'Description',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      FilledButton(
                                        onPressed: _submitting ? null : _deduct,
                                        child: _submitting
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                            : Text((_deductType == 'topup' || _deductType == 'refund')
                                                ? 'Apply credit'
                                                : 'Apply deduction'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search transactions by type or description',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _search.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _search = '');
                                          },
                                        )
                                      : null,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onSubmitted: (value) => setState(() => _search = value.trim()),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text('Transactions', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: AppSpacing.xs),
                            ],
                          ),
                        ),
                        Expanded(
                          child: PaginatedScrollBody<WalletTransaction, WalletTransactionsQuery>(
                            provider: walletTransactionsProvider,
                            query: transactionsQuery!,
                            withPage: (q, page) => (studentId: q.studentId, page: page, search: q.search),
                            queryCacheKey: '${transactionsQuery.studentId}|$_search',
                            onInvalidate: (ref, q) => ref.invalidate(walletTransactionsProvider(q)),
                            itemLabel: 'transactions',
                            initialLoadingKind: LoadingSkeletonKind.list,
                            empty: const EmptyState(
                              title: 'No transactions yet',
                              message: 'This student has no wallet activity.',
                              icon: Icons.receipt_long_outlined,
                            ),
                            builder: (context, controller, items, state) => ListView.builder(
                              controller: controller,
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              itemCount: items.length,
                              itemBuilder: (_, i) => _TransactionTile(transaction: items[i]),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
