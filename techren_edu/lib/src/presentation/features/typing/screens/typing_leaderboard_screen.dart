import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/typing.dart';
import '../../../providers/typing_provider.dart';

class TypingLeaderboardPanel extends ConsumerStatefulWidget {
  const TypingLeaderboardPanel({super.key, required this.subjectId});

  final String subjectId;

  @override
  ConsumerState<TypingLeaderboardPanel> createState() => _TypingLeaderboardPanelState();
}

class _TypingLeaderboardPanelState extends ConsumerState<TypingLeaderboardPanel>
    with AutomaticKeepAliveClientMixin {
  String _period = 'all';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final args = (subjectId: widget.subjectId, period: _period);
    final async = ref.watch(typingLeaderboardProvider(args));

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: async.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(typingLeaderboardProvider(args)),
        ),
        data: (items) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All time'),
                      selected: _period == 'all',
                      onSelected: (_) {
                        if (_period == 'all') return;
                        setState(() => _period = 'all');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Weekly'),
                      selected: _period == 'weekly',
                      onSelected: (_) {
                        if (_period == 'weekly') return;
                        setState(() => _period = 'weekly');
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: 'No scores yet',
                  message: 'Complete a typing test to appear on the leaderboard.',
                  icon: Icons.leaderboard_outlined,
                ),
              )
            else
              SliverPadding(
                padding: AppSpacing.listGutter,
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => _Row(entry: items[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry});

  final TypingLeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text('${entry.rank}'),
      ),
      title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('Level ${entry.level} · ${entry.tests} tests'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('${entry.wpm.toStringAsFixed(0)} WPM', style: const TextStyle(fontWeight: FontWeight.w800)),
          Text('${entry.accuracy.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }
}
