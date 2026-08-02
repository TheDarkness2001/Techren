import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/go_back_icon_button.dart';
import '../../../providers/typing_provider.dart';
import '../widgets/typing_widgets.dart';
import 'typing_game_screen.dart';
import 'typing_leaderboard_screen.dart';

class TypingHubScreen extends ConsumerStatefulWidget {
  const TypingHubScreen({
    super.key,
    required this.subjectId,
    this.isStudent = false,
    this.routePrefix = '/founder',
    this.navItems = const [],
    this.selectedRoute,
  });

  final String subjectId;
  final bool isStudent;
  final String routePrefix;
  final List<NavItem> navItems;
  final String? selectedRoute;

  @override
  ConsumerState<TypingHubScreen> createState() => _TypingHubScreenState();
}

class _TypingHubScreenState extends ConsumerState<TypingHubScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  String get _subjectHome => widget.isStudent
      ? '${widget.routePrefix}/learn/${widget.subjectId}'
      : '${widget.routePrefix}/learning/${widget.subjectId}';

  String get _learningSelected =>
      widget.selectedRoute ??
      (widget.isStudent ? '${widget.routePrefix}/learn' : '${widget.routePrefix}/learning');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openPractice({
    String mode = 'programming',
    String difficulty = 'medium',
    int durationSec = 60,
    bool isDaily = false,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TypingGameScreen(
          subjectId: widget.subjectId,
          mode: mode,
          difficulty: difficulty,
          durationSec: durationSec,
          isDaily: isDaily,
          onOpenLeaderboard: () {
            Navigator.of(context).pop();
            _tabs.animateTo(2);
          },
        ),
      ),
    );
    ref.invalidate(typingDashboardProvider(widget.subjectId));
  }

  @override
  Widget build(BuildContext context) {
    final dashAsync = ref.watch(typingDashboardProvider(widget.subjectId));

    final body = Column(
      children: [
        TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Practice'),
            Tab(text: 'Leaderboard'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              dashAsync.when(
                loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
                error: (e, _) => EmptyState(
                  title: 'Could not load typing dashboard',
                  message: e.toString(),
                  icon: Icons.keyboard_outlined,
                  action: FilledButton(
                    onPressed: () => ref.invalidate(typingDashboardProvider(widget.subjectId)),
                    child: const Text('Retry'),
                  ),
                ),
                data: (dash) => ListView(
                  padding: AppSpacing.pagePadding,
                  children: [
                    if (dash.staffView && (dash.message?.isNotEmpty ?? false)) ...[
                      Text(
                        dash.message!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(
                      dash.staffView
                          ? 'Subject overview · ${dash.testsCompleted} student tests · ${dash.leaderboardSize} ranked'
                          : 'Level ${dash.level} · ${dash.xp} XP · ${dash.xpToNextLevel} to next',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TypingStatGrid(dashboard: dash),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _openPractice(),
                          icon: const Icon(Icons.play_arrow),
                          label: Text(dash.staffView ? 'Try practice' : 'Continue practice'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: dash.dailyChallengeCompleted
                              ? null
                              : () => _openPractice(isDaily: true, durationSec: 60, mode: 'programming'),
                          icon: const Icon(Icons.today_outlined),
                          label: Text(dash.dailyChallengeCompleted ? 'Daily done' : 'Daily challenge'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _tabs.animateTo(2),
                          icon: const Icon(Icons.leaderboard_outlined),
                          label: const Text('Leaderboard'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _PracticeSetup(onStart: _openPractice),
              TypingLeaderboardPanel(subjectId: widget.subjectId),
            ],
          ),
        ),
      ],
    );

    if (!widget.isStudent && widget.navItems.isNotEmpty) {
      final selectedIndex = widget.navItems.indexWhere(
        (i) => _learningSelected.startsWith(i.route) || i.route.contains('/learning'),
      );
      return AdaptiveScaffold(
        title: 'Typing Speed Challenge',
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        selectedRoute: _learningSelected,
        items: widget.navItems,
        onDestinationSelected: (i) => context.go(widget.navItems[i].route),
        actions: [GoBackIconButton(fallbackRoute: _subjectHome)],
        body: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Typing Speed Challenge'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(_subjectHome),
        ),
      ),
      body: body,
    );
  }
}

class _PracticeSetup extends StatefulWidget {
  const _PracticeSetup({required this.onStart});

  final Future<void> Function({
    String mode,
    String difficulty,
    int durationSec,
    bool isDaily,
  }) onStart;

  @override
  State<_PracticeSetup> createState() => _PracticeSetupState();
}

class _PracticeSetupState extends State<_PracticeSetup> {
  String _mode = 'programming';
  String _difficulty = 'medium';
  int _duration = 60;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.pagePadding,
      children: [
        Text('Mode', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          children: [
            for (final m in const [
              ('english', 'English words'),
              ('programming', 'Programming words'),
              ('code', 'Code typing'),
            ])
              ChoiceChip(
                label: Text(m.$2),
                selected: _mode == m.$1,
                onSelected: (_) => setState(() => _mode = m.$1),
              ),
          ],
        ),
        if (_mode != 'code') ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Difficulty', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            children: [
              for (final d in const ['easy', 'medium', 'hard', 'expert'])
                ChoiceChip(
                  label: Text(d),
                  selected: _difficulty == d,
                  onSelected: (_) => setState(() => _difficulty = d),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('Timer', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          children: [
            for (final t in const [15, 30, 60, 120, 300, 0])
              ChoiceChip(
                label: Text(t == 0 ? 'Unlimited' : '${t}s'),
                selected: _duration == t,
                onSelected: (_) => setState(() => _duration = t),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: () => widget.onStart(
            mode: _mode,
            difficulty: _difficulty,
            durationSec: _duration,
          ),
          icon: const Icon(Icons.keyboard),
          label: const Text('Start typing'),
        ),
      ],
    );
  }
}
