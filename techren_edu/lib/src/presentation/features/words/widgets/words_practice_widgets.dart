import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/words.dart';

class WordsPracticeMode {
  const WordsPracticeMode({required this.id, required this.label});

  final String id;
  final String label;
}

const kWordsPracticeModes = [
  WordsPracticeMode(id: 'classic', label: 'Classic'),
  WordsPracticeMode(id: 'timeAttack', label: 'Time Attack'),
  WordsPracticeMode(id: 'streak', label: 'Streak'),
  WordsPracticeMode(id: 'wordRush', label: 'Word Rush'),
  WordsPracticeMode(id: 'multipleChoice', label: 'Choice'),
  WordsPracticeMode(id: 'trueFalse', label: 'True/False'),
  WordsPracticeMode(id: 'missingLetters', label: 'Missing Letters'),
  WordsPracticeMode(id: 'scramble', label: 'Scramble'),
  WordsPracticeMode(id: 'memory', label: 'Memory Match'),
];

class WordsPracticeModeSelector extends StatelessWidget {
  const WordsPracticeModeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final mode in kWordsPracticeModes)
          ChoiceChip(
            label: Text(mode.label),
            selected: selected == mode.id,
            onSelected: (_) => onSelected(mode.id),
          ),
      ],
    );
  }
}

class WordsPracticeStatsBar extends StatelessWidget {
  const WordsPracticeStatsBar({
    super.key,
    required this.correct,
    required this.attempts,
    required this.streak,
    required this.xp,
    this.remainingSeconds,
  });

  final int correct;
  final int attempts;
  final int streak;
  final int xp;
  final int? remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final accuracy = attempts == 0 ? 0 : ((correct / attempts) * 100).round();
    final items = <String>[
      'Correct: $correct',
      'Attempts: $attempts',
      'Accuracy: $accuracy%',
      '🔥 $streak',
      'XP: $xp',
      if (remainingSeconds != null) '⏱ ${remainingSeconds}s',
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final item in items)
          Text(item, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class WordsPracticeFeedback extends StatelessWidget {
  const WordsPracticeFeedback({super.key, required this.result});

  final PracticeAnswerResult result;

  @override
  Widget build(BuildContext context) {
    final ok = result.isCorrect;
    return Card(
      color: (ok ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.timedOut ? "Time's up for this word" : (ok ? 'Correct!' : 'Incorrect'),
              style: TextStyle(fontWeight: FontWeight.w700, color: ok ? AppColors.success : AppColors.error),
            ),
            if (!ok && result.correctAnswer.isNotEmpty) Text('Answer: ${result.correctAnswer}'),
            if (result.stats.xpAwarded > 0) Text('XP: +${result.stats.xpAwarded}'),
          ],
        ),
      ),
    );
  }
}

class WordsMemoryBoard extends StatelessWidget {
  const WordsMemoryBoard({
    super.key,
    required this.cards,
    required this.flippedIds,
    required this.matchedIds,
    required this.onTap,
  });

  final List<PracticeQuestionCard> cards;
  final Set<String> flippedIds;
  final Set<String> matchedIds;
  final ValueChanged<PracticeQuestionCard> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 720 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.6,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            final open = flippedIds.contains(card.id) || matchedIds.contains(card.id);
            return Material(
              color: matchedIds.contains(card.id)
                  ? AppColors.success.withValues(alpha: 0.16)
                  : open
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: AppRadius.card,
              child: InkWell(
                borderRadius: AppRadius.card,
                onTap: matchedIds.contains(card.id) ? null : () => onTap(card),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Text(
                      open ? card.text : (card.side == 'en' ? 'EN' : 'UZ'),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class VocabChipEditor extends StatelessWidget {
  const VocabChipEditor({
    super.key,
    required this.label,
    required this.values,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
    this.hint,
  });

  final String label;
  final List<String> values;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final value in values)
              InputChip(
                label: Text(value),
                onDeleted: () => onRemove(value),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint ?? 'Add and press +',
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => onAdd(),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton.filled(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              tooltip: 'Add',
            ),
          ],
        ),
      ],
    );
  }
}
