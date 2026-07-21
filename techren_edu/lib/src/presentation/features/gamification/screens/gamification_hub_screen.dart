import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/app_hub_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../providers/gamification_provider.dart';
import '../../gamification/widgets/practice_recommendation_banner.dart';

class GamificationHubScreen extends ConsumerStatefulWidget {
  const GamificationHubScreen({
    super.key,
    this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem>? navItems;
  final String selectedRoute;

  @override
  ConsumerState<GamificationHubScreen> createState() => _GamificationHubScreenState();
}

class _GamificationHubScreenState extends ConsumerState<GamificationHubScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

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

  @override
  Widget build(BuildContext context) {
    final navItems = widget.navItems ?? studentNavItemsOf(context);
    final selectedIndex = navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));

    return AdaptiveScaffold(
      title: 'Progress & XP',
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
            body: Column(
        children: [
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Profile'),
              Tab(text: 'Achievements'),
              Tab(text: 'Leaderboard'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _ProfileTab(),
                _AchievementsTab(),
                _LeaderboardTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(gamificationProfileProvider);
    final recommendationAsync = ref.watch(practiceRecommendationProvider);

    return profileAsync.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.dashboard),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (profile) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gamificationProfileProvider);
          ref.invalidate(practiceRecommendationProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.tertiary.withValues(alpha: 0.2),
                          child: Text('Lv.${profile.level}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile.studentName ?? 'Student', style: Theme.of(context).textTheme.titleLarge),
                              Text(
                                '${profile.totalXp} XP total${profile.rank != null ? ' · Rank #${profile.rank}' : ''}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.semantic.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.xs),
                      child: LinearProgressIndicator(
                        value: profile.levelProgress,
                        minHeight: 10,
                        backgroundColor: context.semantic.surfaceContainer,
                        color: AppColors.tertiary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('${profile.xpInLevel} / ${profile.levelCap} XP to level ${profile.level + 1}'),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, color: AppColors.warning),
                        const SizedBox(width: AppSpacing.xs),
                        Text('${profile.currentStreak} day streak · Best: ${profile.longestStreak}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            HubSectionHeader(title: 'Module XP'),
            _ModuleXpBar(label: 'Words', xp: profile.moduleXp.words, color: AppColors.primary),
            _ModuleXpBar(label: 'Sentences', xp: profile.moduleXp.sentences, color: AppColors.secondary),
            _ModuleXpBar(label: 'Listening', xp: profile.moduleXp.listening, color: const Color(0xFF7C3AED)),
            _ModuleXpBar(label: 'Video', xp: profile.moduleXp.video, color: AppColors.tertiary),
            const SizedBox(height: AppSpacing.md),
            recommendationAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (rec) => PracticeRecommendationCard(
                recommendation: rec,
                onTap: () => openRecommendedModule(context, rec),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleXpBar extends StatelessWidget {
  const _ModuleXpBar({required this.label, required this.xp, required this.color});

  final String label;
  final int xp;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const maxXp = 200;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (xp / maxXp).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: context.semantic.surfaceContainer,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('$xp', style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _AchievementsTab extends ConsumerWidget {
  const _AchievementsTab();

  IconData _iconFor(String iconName) {
    switch (iconName) {
      case 'local_fire_department':
      case 'whatshot':
        return Icons.local_fire_department;
      case 'abc':
        return Icons.abc;
      case 'translate':
        return Icons.translate;
      case 'headphones':
        return Icons.headphones;
      case 'play_circle':
        return Icons.play_circle_outline;
      case 'school':
        return Icons.school_outlined;
      case 'military_tech':
        return Icons.military_tech_outlined;
      default:
        return Icons.emoji_events_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);

    return achievementsAsync.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (items) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(achievementsProvider),
        child: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final a = items[i];
            return AppHubCard(
              title: a.title,
              subtitle: a.description,
              accentColor: a.unlocked ? AppColors.tertiary : context.semantic.textMuted,
              icon: _iconFor(a.icon),
              locked: !a.unlocked,
              trailing: a.unlocked
                  ? Text(
                      '+${a.xpReward} XP',
                      style: TextStyle(color: context.semantic.success, fontWeight: FontWeight.w600),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(xpLeaderboardProvider);

    return leaderboardAsync.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (entries) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(xpLeaderboardProvider),
        child: entries.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: AppSpacing.emptyStateTop),
                  EmptyState(title: 'No rankings yet', message: 'Complete lessons to earn XP and appear here.'),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: entries.length,
                itemBuilder: (_, i) {
                  final e = entries[i];
                  return AppHubCard(
                    title: e.name,
                    subtitle: 'Level ${e.level} · ${e.currentStreak} day streak',
                    accentColor: AppColors.primary,
                    leadingLabel: '${e.rank}',
                    trailing: Text('${e.totalXp} XP', style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                },
              ),
      ),
    );
  }
}
