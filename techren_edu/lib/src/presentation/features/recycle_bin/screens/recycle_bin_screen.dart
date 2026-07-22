import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/paginated_scroll_body.dart';
import '../../../../domain/entities/recycle_bin.dart';
import '../../../providers/recycle_bin_provider.dart';

class RecycleBinScreen extends ConsumerStatefulWidget {
  const RecycleBinScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends ConsumerState<RecycleBinScreen> {
  String? _moduleFilter;
  String _search = '';
  final _searchController = TextEditingController();

  RecycleBinQuery get _query => (moduleType: _moduleFilter, page: 1, search: _search);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() => ref.invalidate(recycleBinItemsProvider(_query));

  void _setModuleFilter(String? moduleType) {
    setState(() => _moduleFilter = moduleType);
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));
    final baseQuery = _query;

    return AdaptiveScaffold(
      title: 'Recycle Bin',
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_sweep_outlined),
          tooltip: 'Purge old items',
          onPressed: () => _confirmPurgeAll(context),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: AppSpacing.searchBarPadding,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _moduleFilter == null,
                  onSelected: (_) => _setModuleFilter(null),
                ),
                const SizedBox(width: AppSpacing.xs),
                for (final module in const ['words', 'sentences', 'listening', 'video'])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: FilterChip(
                      label: Text(module),
                      selected: _moduleFilter == module,
                      onSelected: (_) => _setModuleFilter(module),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: AppSpacing.searchBarPadding,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search deleted items by label or type',
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
          ),
          Expanded(
            child: PaginatedScrollBody<RecycleBinEntry, RecycleBinQuery>(
              provider: recycleBinItemsProvider,
              query: baseQuery,
              withPage: (q, page) => (moduleType: q.moduleType, page: page, search: q.search),
              queryCacheKey: '${baseQuery.moduleType ?? ''}|${baseQuery.search}',
              onInvalidate: (ref, q) => ref.invalidate(recycleBinItemsProvider(q)),
              itemLabel: 'items',
              initialLoadingKind: LoadingSkeletonKind.list,
              empty: ListView(
                children: const [
                  SizedBox(height: AppSpacing.emptyStateTop),
                  EmptyState(
                    title: 'Recycle bin is empty',
                    message: 'Deleted content from words, sentences, listening, and video appears here.',
                    icon: Icons.delete_outline,
                  ),
                ],
              ),
              builder: (context, controller, items, state) => LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 800) {
                    return ListView(
                      controller: controller,
                      padding: AppSpacing.listGutter,
                      children: [
                        AppDataTable(
                          columns: const ['Item', 'Module', 'Collection', 'Deleted', 'Status'],
                          onSelectChanged: (index) {
                            showAppDialog<void>(
                              context: context,
                              builder: (_) => _SnapshotPreviewDialog(entryId: items[index].id),
                            );
                          },
                          rows: [
                            for (final entry in items)
                              AppDataRow(
                                cells: [
                                  Text(entry.label.isNotEmpty ? entry.label : entry.collectionName),
                                  Text(entry.moduleType),
                                  Text(entry.collectionName),
                                  Text(
                                    entry.deletedAt != null
                                        ? entry.deletedAt!.toLocal().toString().split('.').first
                                        : '—',
                                  ),
                                  StatusBadge(
                                    label: entry.isImportant ? 'IMPORTANT' : 'STANDARD',
                                    color: entry.isImportant ? AppColors.warning : context.semantic.textMuted,
                                    background: entry.isImportant
                                        ? context.semantic.warningContainer
                                        : context.semantic.surfaceContainer,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    controller: controller,
                    padding: AppSpacing.listGutter,
                    itemCount: items.length,
                    itemBuilder: (_, i) => _RecycleBinTile(
                      entry: items[i],
                      onChanged: _refresh,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPurgeAll(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Purge old items',
      message: 'Permanently delete all non-important items older than 30 days? This cannot be undone.',
      confirmLabel: 'Purge',
      destructive: true,
      icon: Icons.delete_forever_outlined,
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final result = await ref.read(recycleBinApiProvider).purgeAll(
            olderThanDays: 30,
            moduleType: _moduleFilter,
          );
      _refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purged ${result.purgedCount} item(s)')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _RecycleBinTile extends ConsumerWidget {
  const _RecycleBinTile({required this.entry, required this.onChanged});

  final RecycleBinEntry entry;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateText = entry.deletedAt != null ? entry.deletedAt!.toLocal().toString().split('.').first : '';

    return AppAdminRowCard(
      title: entry.label.isNotEmpty ? entry.label : entry.collectionName,
      subtitle: '${entry.moduleType} · ${entry.collectionName}\nDeleted $dateText',
      icon: entry.isImportant ? Icons.star_rounded : Icons.delete_outline,
      accentColor: entry.isImportant ? AppColors.warning : AppColors.secondary,
      onTap: () => _showSnapshotPreview(context, ref),
      menuItems: [
        const PopupMenuItem(value: 'restore', child: Text('Restore')),
        const PopupMenuItem(value: 'important', child: Text('Toggle important')),
        if (!entry.isImportant)
          const PopupMenuItem(value: 'purge', child: Text('Purge permanently')),
      ],
      onMenuSelected: (action) => _handleAction(context, ref, action),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String action) async {
    final api = ref.read(recycleBinApiProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (action == 'restore') {
        final result = await api.restore(entry.id);
        onChanged();
        messenger.showSnackBar(SnackBar(content: Text('Restored ${result.restoredCount} item(s)')));
      } else if (action == 'important') {
        await api.toggleImportant(entry.id);
        onChanged();
      } else if (action == 'purge') {
        final confirmed = await showAppConfirmDialog(
          context: context,
          title: 'Purge permanently',
          message: 'Delete "${entry.label}" forever?',
          confirmLabel: 'Purge',
          destructive: true,
        );
        if (confirmed == true) {
          await api.purge(entry.id);
          onChanged();
        }
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showSnapshotPreview(BuildContext context, WidgetRef ref) async {
    await showAppDialog<void>(
      context: context,
      builder: (_) => _SnapshotPreviewDialog(entryId: entry.id),
    );
  }
}

class _SnapshotPreviewDialog extends ConsumerWidget {
  const _SnapshotPreviewDialog({required this.entryId});

  final String entryId;

  /// Pops the dialog; if the navigator has nothing to pop (orphaned route),
  /// falls back to the splash route so the user is never trapped.
  void _close(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      GoRouter.of(context).go('/splash');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(recycleBinSnapshotsProvider(entryId));

    return AppDialog(
      title: 'Snapshot preview',
      icon: Icons.history_outlined,
      maxWidth: 480,
      content: SizedBox(
        width: 420,
        child: detailAsync.when(
          loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text(e.toString()),
          data: (detail) {
            final latest = detail.snapshots.isNotEmpty ? detail.snapshots.first : null;
            if (latest == null) return const Text('No snapshots available');
            final preview = latest.snapshot.entries
                .where((e) => !e.key.startsWith('_') && e.key != '__v')
                .map((e) => '${e.key}: ${e.value}')
                .join('\n');
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(
                child: Text(preview.isEmpty ? 'Empty snapshot' : preview),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _close(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
