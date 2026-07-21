import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/paginated_scroll_body.dart';
import '../../../../domain/entities/branch.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../providers/identity_provider.dart';
import '../widgets/branch_management_card.dart';

class BranchesScreen extends ConsumerStatefulWidget {
  const BranchesScreen({super.key, required this.navItems, required this.selectedRoute});

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends ConsumerState<BranchesScreen> {
  PageMeta _meta = const PageMeta();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => ref.invalidate(branchesProvider(_meta.copyWith(page: 1)));

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navItems.indexWhere((i) => widget.selectedRoute.startsWith(i.route));
    final query = _meta.copyWith(page: 1);

    return AdaptiveScaffold(
      title: 'Branch Management',
      selectedIndex: selectedIndex < 0 ? 1 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        FilledButton(
          onPressed: () => _showBranchDialog(context),
          child: const Text('Add Branch'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: TextField(
              controller: _searchController,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search branches by name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: (_meta.search ?? '').isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _meta = _meta.copyWith(search: '', page: 1));
                        },
                      )
                    : null,
                isDense: true,
              ),
              onSubmitted: (value) => setState(() => _meta = _meta.copyWith(search: value.trim(), page: 1)),
            ),
          ),
          Expanded(
            child: PaginatedScrollBody<Branch, PageMeta>(
              provider: branchesProvider,
              query: query,
              withPage: (q, page) => q.copyWith(page: page),
              queryCacheKey: '${query.limit}|${query.search ?? ''}|${query.status ?? ''}|${query.branchId ?? ''}',
              onInvalidate: (ref, q) => ref.invalidate(branchesProvider(q)),
              itemLabel: 'branches',
              initialLoadingKind: LoadingSkeletonKind.dashboard,
              empty: ListView(
                children: const [
                  SizedBox(height: AppSpacing.emptyStateTop),
                  EmptyState(
                    title: 'No branches',
                    message: 'Create your first academy branch to get started.',
                    icon: Icons.apartment_outlined,
                  ),
                ],
              ),
              builder: (context, controller, items, state) {
                return GridView.builder(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 260,
                    crossAxisSpacing: AppSpacing.lg,
                    mainAxisSpacing: AppSpacing.lg,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => BranchManagementCard(
                    branch: items[index],
                    onEdit: () => _showBranchDialog(context, branch: items[index]),
                    onToggleStatus: () => _toggleBranchStatus(items[index]),
                    onDelete: () => _confirmDelete(context, items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showBranchDialog(BuildContext context, {Branch? branch}) async {
    final isEdit = branch != null;
    final nameController = TextEditingController(text: branch?.name ?? '');
    final addressController = TextEditingController(text: branch?.address ?? '');
    final phoneController = TextEditingController(text: branch?.phone ?? '');

    final saved = await showAppDialog<bool>(
      context: context,
      builder: (context) => AppDialog(
        title: isEdit ? 'Edit Branch' : 'Add Branch',
        icon: Icons.store_outlined,
        content: AppFormColumn(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context, false)),
          AppDialogActions.confirm(
            context,
            label: isEdit ? 'Save' : 'Create',
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final api = ref.read(identityApiProvider);
              if (isEdit) {
                await api.updateBranch(
                  id: branch.id,
                  name: nameController.text.trim(),
                  address: addressController.text.trim(),
                  phone: phoneController.text.trim(),
                );
              } else {
                await api.createBranch(
                  name: nameController.text.trim(),
                  address: addressController.text.trim(),
                  phone: phoneController.text.trim(),
                );
              }
              if (context.mounted) Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );

    if (saved == true) {
      if (!isEdit) {
        _searchController.clear();
        setState(() => _meta = _meta.copyWith(search: '', page: 1));
      }
      _refresh();
    }
  }

  Future<void> _toggleBranchStatus(Branch branch) async {
    try {
      await ref.read(identityApiProvider).setBranchStatus(branch.id, !branch.isActive);
      _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, Branch branch) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete branch',
      message: 'Permanent branch deletion is not enabled yet. Deactivate "${branch.name}" instead?',
      confirmLabel: 'Deactivate',
      destructive: false,
    );

    if (confirmed == true) {
      await _toggleBranchStatus(branch);
    }
  }
}
