import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/news.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/news_provider.dart';
import 'news_post_card.dart';

class DashboardNewsFeed extends ConsumerStatefulWidget {
  const DashboardNewsFeed({super.key});

  @override
  ConsumerState<DashboardNewsFeed> createState() => _DashboardNewsFeedState();
}

class _DashboardNewsFeedState extends ConsumerState<DashboardNewsFeed> {
  final List<NewsPost> _extra = [];
  String? _nextCursor;
  bool _loadingMore = false;
  String _category = '';
  String _type = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _emptyTitle {
    final user = ref.read(authProvider).user;
    if (user?.isStudent == true) return 'Latest announcements';
    if (user?.isManager == true || user?.isAdmin == true || user?.isFounder == true) {
      return 'Management announcements';
    }
    return 'Latest news';
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _nextCursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref.read(newsApiProvider).getFeed(
            cursor: _nextCursor,
            category: _category.isEmpty ? null : _category,
            type: _type.isEmpty ? null : _type,
            q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
          );
      setState(() {
        _extra.addAll(page.items);
        _nextCursor = page.nextCursor;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _applyFilters() async {
    setState(() {
      _extra.clear();
      _nextCursor = null;
    });
    ref.invalidate(newsFeedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(newsFeedProvider);
    final categories = ref.watch(newsCategoriesProvider).valueOrNull ?? [];

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: LoadingState(message: 'Loading news…', kind: LoadingSkeletonKind.card),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (page) {
        // When filters active, fetch filtered page separately
        return FutureBuilder<NewsFeedPage>(
          future: (_category.isEmpty && _type.isEmpty && _searchCtrl.text.trim().isEmpty)
              ? Future.value(page)
              : ref.read(newsApiProvider).getFeed(
                    category: _category.isEmpty ? null : _category,
                    type: _type.isEmpty ? null : _type,
                    q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
                  ),
          builder: (context, snap) {
            final feed = snap.data ?? page;
            final pinned = feed.items.where((p) => p.pinned).toList();
            final rest = [...feed.items.where((p) => !p.pinned), ..._extra];
            if (_nextCursor == null && feed.nextCursor != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _nextCursor == null) setState(() => _nextCursor = feed.nextCursor);
              });
            }

            if (feed.items.isEmpty && feed.quoteOfDay == null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: EmptyState(
                  title: _emptyTitle,
                  message: 'No posts yet. Check back soon.',
                  icon: Icons.newspaper_outlined,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Campus News', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search news…',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: _applyFilters,
                    ),
                  ),
                  onSubmitted: (_) => _applyFilters(),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All types'),
                        selected: _type.isEmpty,
                        onSelected: (_) {
                          setState(() => _type = '');
                          _applyFilters();
                        },
                      ),
                      const SizedBox(width: 6),
                      for (final t in ['announcement', 'event', 'poll_embed', 'motivation'])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(t),
                            selected: _type == t,
                            onSelected: (_) {
                              setState(() => _type = t);
                              _applyFilters();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All categories'),
                          selected: _category.isEmpty,
                          onSelected: (_) {
                            setState(() => _category = '');
                            _applyFilters();
                          },
                        ),
                        const SizedBox(width: 6),
                        for (final c in categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(c.name),
                              selected: _category == c.name,
                              onSelected: (_) {
                                setState(() => _category = c.name);
                                _applyFilters();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                if (feed.quoteOfDay != null) _QuoteCard(post: feed.quoteOfDay!),
                if (pinned.isNotEmpty) ...[
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: pinned.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final p = pinned[i];
                        return ActionChip(
                          avatar: const Icon(Icons.push_pin, size: 14),
                          label: Text(p.title, overflow: TextOverflow.ellipsis),
                          onPressed: () {},
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                for (final post in [...pinned, ...rest.where((p) => !pinned.any((x) => x.id == p.id))])
                  NewsPostCard(
                    post: post,
                    compact: true,
                    onUpdated: (_) => ref.invalidate(newsFeedProvider),
                  ),
                if (_nextCursor != null || feed.nextCursor != null)
                  Center(
                    child: TextButton(
                      onPressed: _loadingMore ? null : _loadMore,
                      child: _loadingMore
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Load more'),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
              ],
            );
          },
        );
      },
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.post});

  final NewsPost post;

  @override
  Widget build(BuildContext context) {
    final body = post.body.replaceAll(RegExp(r'<[^>]+>'), '').trim();
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.55),
            context.semantic.surfaceContainer,
          ],
        ),
        border: Border.all(color: context.semantic.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quote of the Day', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(
            body.isEmpty ? post.title : body,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic),
          ),
          if (post.authorName.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('— ${post.authorName}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
