import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_spacing.dart';
import '../../domain/entities/paginated_result.dart';
import 'common_widgets.dart';

/// Footer for scroll pagination — item count + load spinner (no prev/next buttons).
class PaginatedScrollFooter extends StatelessWidget {
  const PaginatedScrollFooter({
    super.key,
    required this.loadedCount,
    required this.total,
    required this.itemLabel,
    this.loadingMore = false,
    this.hasMore = false,
  });

  final int loadedCount;
  final int total;
  final String itemLabel;
  final bool loadingMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final label = loadedCount >= total
        ? 'All $total $itemLabel loaded'
        : 'Showing $loadedCount of $total $itemLabel';

    return Semantics(
      label: loadingMore ? '$label. Loading more.' : label,
      child: Material(
        elevation: 2,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(child: Text(label, style: theme.textTheme.bodySmall)),
                if (loadingMore)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (hasMore)
                  Icon(Icons.arrow_downward, size: 16, color: theme.colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaginatedScrollState {
  const PaginatedScrollState({
    required this.loadedCount,
    required this.total,
    required this.hasMore,
    required this.loadingMore,
  });

  final int loadedCount;
  final int total;
  final bool hasMore;
  final bool loadingMore;
}

typedef PaginatedScrollBuilder<T> = Widget Function(
  BuildContext context,
  ScrollController scrollController,
  List<T> items,
  PaginatedScrollState state,
);

/// Accumulates paginated API pages as the user scrolls to the bottom.
class PaginatedScrollBody<T, Q> extends ConsumerStatefulWidget {
  const PaginatedScrollBody({
    super.key,
    required this.provider,
    required this.query,
    required this.withPage,
    required this.queryCacheKey,
    required this.builder,
    required this.onInvalidate,
    this.itemLabel = 'items',
    this.initialLoadingKind = LoadingSkeletonKind.list,
    this.empty,
  });

  final AutoDisposeFutureProviderFamily<PaginatedResult<T>, Q> provider;
  final Q query;
  final Q Function(Q query, int page) withPage;
  final Object queryCacheKey;
  final PaginatedScrollBuilder<T> builder;
  final void Function(WidgetRef ref, Q query) onInvalidate;
  final String itemLabel;
  final LoadingSkeletonKind initialLoadingKind;
  final Widget? empty;

  @override
  ConsumerState<PaginatedScrollBody<T, Q>> createState() => _PaginatedScrollBodyState<T, Q>();
}

class _PaginatedScrollBodyState<T, Q> extends ConsumerState<PaginatedScrollBody<T, Q>> {
  final _scrollController = ScrollController();
  final _items = <T>[];
  int _page = 1;
  int _total = 0;
  bool _hasMore = false;
  bool _loadingMore = false;
  int _lastMergedPage = 0;
  Object? _cacheKey;

  @override
  void initState() {
    super.initState();
    _cacheKey = widget.queryCacheKey;
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant PaginatedScrollBody<T, Q> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.queryCacheKey != _cacheKey) {
      _cacheKey = widget.queryCacheKey;
      _reset();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _page = 1;
      _items.clear();
      _total = 0;
      _hasMore = false;
      _loadingMore = false;
      _lastMergedPage = 0;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore || !_hasMore) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_loadingMore || !_hasMore) return;
    setState(() {
      _loadingMore = true;
      _page++;
    });
  }

  void _merge(PaginatedResult<T> result) {
    if (!mounted) return;
    setState(() {
      if (result.page == 1) {
        _items
          ..clear()
          ..addAll(result.items);
        _lastMergedPage = 1;
      } else if (result.page > _lastMergedPage) {
        _items.addAll(result.items);
        _lastMergedPage = result.page;
      }
      _total = result.total;
      _hasMore = result.hasMore;
      _loadingMore = false;
    });
  }

  Future<void> _handleRefresh() async {
    _reset();
    widget.onInvalidate(ref, widget.withPage(widget.query, 1));
  }

  PaginatedScrollState get _scrollState => PaginatedScrollState(
        loadedCount: _items.length,
        total: _total,
        hasMore: _hasMore,
        loadingMore: _loadingMore,
      );

  @override
  Widget build(BuildContext context) {
    final activeQuery = widget.withPage(widget.query, _page);
    final provider = widget.provider(activeQuery);

    ref.listen(provider, (_, next) => next.whenData(_merge));
    final async = ref.watch(provider);

    if (_items.isEmpty) {
      if (async.isLoading) {
        return LoadingState(kind: widget.initialLoadingKind);
      }
      if (async.hasError) {
        return Center(child: Text('${async.error}'));
      }
      if (async.hasValue && async.value!.items.isEmpty) {
        return widget.empty ?? const SizedBox.shrink();
      }
    }

    return _buildScaffold();
  }

  Widget _buildScaffold() {
    if (_items.isEmpty && widget.empty != null) {
      return widget.empty!;
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: widget.builder(context, _scrollController, _items, _scrollState),
          ),
        ),
        PaginatedScrollFooter(
          loadedCount: _items.length,
          total: _total,
          itemLabel: widget.itemLabel,
          loadingMore: _loadingMore,
          hasMore: _hasMore,
        ),
      ],
    );
  }
}

/// Scroll-down pagination widgets — replaces prev/next [PaginationBar].