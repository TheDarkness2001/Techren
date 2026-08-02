import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/typing.dart';

class TypingStatGrid extends StatelessWidget {
  const TypingStatGrid({super.key, required this.dashboard});

  final TypingDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = [
      ('Level', '${dashboard.level}'),
      ('XP', '${dashboard.xp}'),
      ('Rank', dashboard.currentRank != null ? '#${dashboard.currentRank}' : '—'),
      ('Best WPM', dashboard.bestWpm.toStringAsFixed(0)),
      ('Avg WPM', dashboard.averageWpm.toStringAsFixed(1)),
      ('Accuracy', '${dashboard.accuracy.toStringAsFixed(1)}%'),
      ('Streak', '${dashboard.currentStreak}d'),
      ('Tests', '${dashboard.testsCompleted}'),
      ('Words', '${dashboard.wordsTyped}'),
      ('Time', _formatTime(dashboard.timePracticedSec)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cross = constraints.maxWidth >= 900
            ? 5
            : constraints.maxWidth >= 600
                ? 3
                : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.55,
          ),
          itemBuilder: (_, i) {
            final item = items[i];
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: AppRadius.card,
                border: Border.all(color: context.semantic.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.$1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.semantic.textMuted,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(int sec) {
    if (sec < 60) return '${sec}s';
    final m = sec ~/ 60;
    if (m < 60) return '${m}m';
    return '${m ~/ 60}h ${m % 60}m';
  }
}

class TypingLiveStatsBar extends StatelessWidget {
  const TypingLiveStatsBar({
    super.key,
    required this.wpm,
    required this.accuracy,
    required this.correctChars,
    required this.incorrectChars,
    required this.mistakes,
    required this.timeLeftLabel,
    required this.progress,
  });

  final double wpm;
  final double accuracy;
  final int correctChars;
  final int incorrectChars;
  final int mistakes;
  final String timeLeftLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget chip(String label, String value) => Expanded(
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.semantic.textMuted)),
            ],
          ),
        );

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: context.semantic.surfaceContainer,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            chip('WPM', wpm.toStringAsFixed(0)),
            chip('Accuracy', '${accuracy.toStringAsFixed(0)}%'),
            chip('Correct', '$correctChars'),
            chip('Wrong', '$incorrectChars'),
            chip('Mistakes', '$mistakes'),
            chip('Time', timeLeftLabel),
          ],
        ),
      ],
    );
  }
}

Future<void> showTypingResultSheet({
  required BuildContext context,
  required TypingResultCard result,
  required VoidCallback onRetry,
  required VoidCallback onLeaderboard,
  required VoidCallback onContinue,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      final improved = result.improvementVsLast;
      return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Test complete', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              improved >= 0
                  ? '+${improved.toStringAsFixed(1)} WPM vs last test'
                  : '${improved.toStringAsFixed(1)} WPM vs last test',
              style: TextStyle(
                color: improved >= 0 ? context.semantic.success : context.semantic.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ResultChip(label: 'WPM', value: result.wpm.toStringAsFixed(0)),
                _ResultChip(label: 'Raw', value: result.rawWpm.toStringAsFixed(0)),
                _ResultChip(label: 'Accuracy', value: '${result.accuracy.toStringAsFixed(1)}%'),
                _ResultChip(label: 'XP', value: '+${result.xpEarned}'),
                _ResultChip(label: 'Level', value: '${result.level}'),
                _ResultChip(label: 'Streak', value: '${result.currentStreak}d'),
                _ResultChip(label: 'Correct words', value: '${result.correctWords}'),
                _ResultChip(label: 'Wrong words', value: '${result.wrongWords}'),
                _ResultChip(label: 'Mistakes', value: '${result.mistakes}'),
              ],
            ),
            if (result.xpReasons.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('XP breakdown', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              ...result.xpReasons.map(
                (r) => Text('• $r', style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
                FilledButton.tonal(onPressed: onLeaderboard, child: const Text('Leaderboard')),
                OutlinedButton(onPressed: onContinue, child: const Text('Continue practice')),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
