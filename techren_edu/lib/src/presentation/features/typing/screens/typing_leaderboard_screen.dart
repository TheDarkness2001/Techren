import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/typing.dart';
import '../../../providers/auth_provider.dart';
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
  int _durationSec = 60;
  double _minAccuracy = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final args = (
      subjectId: widget.subjectId,
      period: _period,
      durationSec: _durationSec,
      minAccuracy: _minAccuracy,
    );
    final async = ref.watch(typingLeaderboardProvider(args));
    final myId = ref.watch(authProvider).user?.id;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: async.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(typingLeaderboardProvider(args)),
        ),
        data: (page) => CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Timer', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in const [60, 15, 30])
                          ChoiceChip(
                            label: Text('${t}s'),
                            selected: _durationSec == t,
                            onSelected: (_) {
                              if (_durationSec == t) return;
                              setState(() => _durationSec = t);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Min accuracy', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final a in const [0.0, 90.0, 95.0, 98.0])
                          ChoiceChip(
                            label: Text(a == 0 ? 'Any %' : '≥${a.toInt()}%'),
                            selected: _minAccuracy == a,
                            onSelected: (_) {
                              if (_minAccuracy == a) return;
                              setState(() => _minAccuracy = a);
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Period', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Wrap(
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
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Ranked by correct words in ${_durationSec}s · Top 10',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (page.items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: 'No scores yet',
                  message: 'Complete a typing test with this timer to appear on the leaderboard.',
                  icon: Icons.leaderboard_outlined,
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 4),
                  child: Text(
                    'Top 10',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              SliverPadding(
                padding: AppSpacing.listGutter,
                sliver: SliverList.separated(
                  itemCount: page.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final entry = page.items[i];
                    return _Row(
                      entry: entry,
                      isMe: myId != null && entry.studentId == myId,
                      durationSec: page.durationSec,
                    );
                  },
                ),
              ),
              if (page.me != null && !page.meInTop) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, 4),
                    child: Text(
                      'Your rank',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: AppSpacing.listGutter,
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _Row(
                        entry: page.me!,
                        isMe: true,
                        durationSec: page.durationSec,
                      ),
                    ]),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.entry,
    required this.durationSec,
    this.isMe = false,
  });

  final TypingLeaderboardEntry entry;
  final int durationSec;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      tileColor: isMe ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
      leading: CircleAvatar(
        backgroundColor: isMe ? scheme.primary : null,
        foregroundColor: isMe ? scheme.onPrimary : null,
        child: Text('${entry.rank}'),
      ),
      title: Text(
        isMe ? '${entry.name} (you)' : entry.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('Level ${entry.level} · ${entry.tests} tests · ${entry.wpm.toStringAsFixed(0)} WPM'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${entry.correctWords} words',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            '${entry.accuracy.toStringAsFixed(0)}% · ${durationSec}s',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
