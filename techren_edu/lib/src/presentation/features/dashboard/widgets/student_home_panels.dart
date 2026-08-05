import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/appearance_controls.dart';
import '../../../../core/widgets/person_avatar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/gamification_provider.dart';
import '../../../providers/listening_provider.dart';
import '../../../providers/sentences_provider.dart';
import '../../../providers/words_provider.dart';
import 'dashboard_header.dart';

enum _StudentLeaderboardTab { words, sentences, listening, other }

/// Student home extras: profile, module leaderboards.
class StudentHomePanels extends ConsumerStatefulWidget {
  const StudentHomePanels({super.key});

  @override
  ConsumerState<StudentHomePanels> createState() => _StudentHomePanelsState();
}

class _StudentHomePanelsState extends ConsumerState<StudentHomePanels> {
  _StudentLeaderboardTab _tab = _StudentLeaderboardTab.words;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

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
            onPressed: () => context.go(_viewAllRoute(_tab)),
            child: const Text('View all'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final option in _StudentLeaderboardTab.values) ...[
                      if (option != _StudentLeaderboardTab.values.first) const SizedBox(width: AppSpacing.xs),
                      FilterChip(
                        label: Text(switch (option) {
                          _StudentLeaderboardTab.words => 'Words',
                          _StudentLeaderboardTab.sentences => 'Sentences',
                          _StudentLeaderboardTab.listening => 'Listening',
                          _StudentLeaderboardTab.other => 'Other',
                        }),
                        selected: _tab == option,
                        onSelected: (_) => setState(() => _tab = option),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _LeaderboardPreview(tab: _tab),
            ],
          ),
        ),
      ],
    );
  }

  String _viewAllRoute(_StudentLeaderboardTab tab) => switch (tab) {
        _StudentLeaderboardTab.words => '/student/words/leaderboard',
        _StudentLeaderboardTab.sentences => '/student/sentences/leaderboard',
        _StudentLeaderboardTab.listening => '/student/listening/leaderboard',
        _StudentLeaderboardTab.other => '/student/gamification',
      };
}

class _LeaderboardPreview extends ConsumerWidget {
  const _LeaderboardPreview({required this.tab});

  final _StudentLeaderboardTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (tab) {
      _StudentLeaderboardTab.words => _WordsPreview(ref: ref),
      _StudentLeaderboardTab.sentences => _SentencesPreview(ref: ref),
      _StudentLeaderboardTab.listening => _ListeningPreview(ref: ref),
      _StudentLeaderboardTab.other => _XpPreview(ref: ref),
    };
  }
}

class _WordsPreview extends StatelessWidget {
  const _WordsPreview({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(wordsLeaderboardProvider);
    return async.when(
      loading: () => const _Loading(),
      error: (_, __) => const _ErrorText('Could not load words leaderboard'),
      data: (board) {
        final top = board.leaderboard.take(5).toList();
        if (top.isEmpty) {
          return const Text('No rankings yet — complete a words practice to appear here.');
        }
        return Column(
          children: [
            for (final entry in top)
              _RankTile(
                rank: entry.rank,
                name: entry.name,
                profileImage: entry.profileImage,
                subtitle: '${entry.accuracy}% accuracy',
                trailing: '${entry.correctAnswers}',
              ),
          ],
        );
      },
    );
  }
}

class _SentencesPreview extends StatelessWidget {
  const _SentencesPreview({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sentencesLeaderboardProvider);
    return async.when(
      loading: () => const _Loading(),
      error: (_, __) => const _ErrorText('Could not load sentences leaderboard'),
      data: (board) {
        final top = board.leaderboard.take(5).toList();
        if (top.isEmpty) {
          return const Text('No rankings yet — complete a sentences practice to appear here.');
        }
        return Column(
          children: [
            for (final entry in top)
              _RankTile(
                rank: entry.rank,
                name: entry.name,
                subtitle: '${entry.accuracy}% accuracy',
                trailing: '${entry.totalCorrect}',
              ),
          ],
        );
      },
    );
  }
}

class _ListeningPreview extends StatelessWidget {
  const _ListeningPreview({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(listeningLeaderboardProvider);
    return async.when(
      loading: () => const _Loading(),
      error: (_, __) => const _ErrorText('Could not load listening leaderboard'),
      data: (board) {
        final top = board.leaderboard.take(5).toList();
        if (top.isEmpty) {
          return const Text('No rankings yet — complete a listening practice to appear here.');
        }
        return Column(
          children: [
            for (final entry in top)
              _RankTile(
                rank: entry.rank,
                name: entry.name,
                subtitle: '${entry.avgBestAccuracy}% best accuracy',
                trailing: '${entry.totalAttempts}',
              ),
          ],
        );
      },
    );
  }
}

class _XpPreview extends StatelessWidget {
  const _XpPreview({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(xpLeaderboardProvider);
    return async.when(
      loading: () => const _Loading(),
      error: (_, __) => const _ErrorText('Could not load XP leaderboard'),
      data: (entries) {
        final top = entries.take(5).toList();
        if (top.isEmpty) {
          return const Text('No rankings yet — earn XP by practicing to appear here.');
        }
        return Column(
          children: [
            for (final entry in top)
              _RankTile(
                rank: entry.rank,
                name: entry.name,
                subtitle: 'Level ${entry.level} · ${entry.currentStreak} day streak',
                trailing: '${entry.totalXp} XP',
              ),
          ],
        );
      },
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({
    required this.rank,
    required this.name,
    required this.subtitle,
    required this.trailing,
    this.profileImage,
  });

  final int rank;
  final String name;
  final String subtitle;
  final String trailing;
  final String? profileImage;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: PersonAvatar(
        name: name,
        profileImage: profileImage,
        radius: 18,
      ),
      title: Text('$rank. $name'),
      subtitle: Text(subtitle),
      trailing: Text(trailing),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error));
  }
}
