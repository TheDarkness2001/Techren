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
    this.compact = false,
  });

  final double wpm;
  final double accuracy;
  final int correctChars;
  final int incorrectChars;
  final int mistakes;
  final String timeLeftLabel;
  final double progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.semantic.textMuted;

    if (compact) {
      TextSpan stat(String value, String label) => TextSpan(
            children: [
              TextSpan(
                text: '$value ',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: scheme.primary,
                ),
              ),
              TextSpan(
                text: label,
                style: TextStyle(fontSize: 13, color: muted, fontWeight: FontWeight.w600),
              ),
            ],
          );

      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: context.semantic.surfaceContainer,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text.rich(
            TextSpan(
              children: [
                stat(wpm.toStringAsFixed(0), 'wpm'),
                const TextSpan(text: '   '),
                stat('${accuracy.toStringAsFixed(0)}%', 'acc'),
                const TextSpan(text: '   '),
                stat(timeLeftLabel, 'time'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    Widget chip(String label, String value) => Expanded(
          child: Column(
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: muted)),
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
  int? correctChars,
  int? incorrectChars,
  int? durationSec,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFF12151C),
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      final improved = result.improvementVsLast;
      final correct = correctChars ?? result.correctChars;
      final incorrect = incorrectChars ?? result.incorrectChars;
      final duration = durationSec;
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
            Text(
              'TEST COMPLETE',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
            ),
            if (result.isPersonalBest || result.dailyComplete) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  if (result.isPersonalBest)
                    _BadgePill(label: 'PERSONAL BEST', color: scheme.primary),
                  if (result.dailyComplete)
                    _BadgePill(label: 'DAILY COMPLETE', color: context.semantic.success),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  result.wpm.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'WPM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.semantic.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${result.accuracy.toStringAsFixed(0)}% ACCURACY',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              improved >= 0
                  ? '+${improved.toStringAsFixed(1)} WPM vs last test'
                  : '${improved.toStringAsFixed(1)} WPM vs last test',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: improved >= 0 ? context.semantic.success : context.semantic.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ResultChip(label: 'Correct', value: '$correct'),
                _ResultChip(label: 'Incorrect', value: '$incorrect'),
                _ResultChip(label: 'Characters', value: '${result.totalChars}'),
                _ResultChip(label: 'Words', value: '${result.correctWords}'),
                if (duration != null) _ResultChip(label: 'Duration', value: '${duration}s'),
                _ResultChip(label: 'XP', value: '+${result.xpEarned}'),
                _ResultChip(label: 'Level', value: '${result.level}'),
                _ResultChip(label: 'Streak', value: '${result.currentStreak}d'),
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
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
                FilledButton.tonal(onPressed: onLeaderboard, child: const Text('Leaderboard')),
                OutlinedButton(onPressed: onContinue, child: const Text('Continue')),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
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
