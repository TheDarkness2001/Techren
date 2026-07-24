import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/appearance_controls.dart';
import '../../../../core/widgets/person_avatar.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/words_provider.dart';
import 'dashboard_header.dart';

/// Student home extras: profile + language, leaderboard, latest feedback.
class StudentHomePanels extends ConsumerWidget {
  const StudentHomePanels({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final leaderboardAsync = ref.watch(wordsLeaderboardProvider);
    final feedbackAsync = ref.watch(
      feedbackListProvider((studentId: null, page: 1, search: '')),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (user != null) ...[
          Row(
            children: [
              PersonAvatar(
                name: user.name,
                profileImage: user.profileImage,
                radius: 28,
                isActive: !user.isInactiveStudent,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      user.email ?? 'Student',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const AppearanceControls(),
          const SizedBox(height: AppSpacing.lg),
        ],
        DashboardSection(
          title: 'Leaderboard',
          trailing: TextButton(
            onPressed: () => context.go('/student/words/leaderboard'),
            child: const Text('View all'),
          ),
          child: leaderboardAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text('Could not load leaderboard', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            data: (board) {
              final top = board.leaderboard.take(5).toList();
              if (top.isEmpty) {
                return const Text('No rankings yet — complete a words practice to appear here.');
              }
              return Column(
                children: [
                  for (final entry in top)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: PersonAvatar(
                        name: entry.name,
                        profileImage: entry.profileImage,
                        radius: 18,
                      ),
                      title: Text('${entry.rank}. ${entry.name}'),
                      subtitle: Text('${entry.accuracy}% accuracy'),
                      trailing: Text('${entry.correctAnswers}'),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        DashboardSection(
          title: 'Latest feedback',
          trailing: TextButton(
            onPressed: () => context.go('/student/feedback'),
            child: const Text('View all'),
          ),
          child: feedbackAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text('Could not load feedback', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            data: (page) {
              final items = page.items.take(5).toList();
              if (items.isEmpty) {
                return const Text('No teacher feedback yet.');
              }
              return Column(
                children: [
                  for (final item in items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.rate_review_outlined),
                      title: Text(item.className),
                      subtitle: Text(item.date),
                      trailing: Text(
                        'H${item.homework} B${item.behavior} P${item.participation}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      onTap: () => context.go('/student/feedback'),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
