import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final ok = result.isCorrect;
    final title = result.timedOut
        ? "Time's up for this word"
        : ok
            ? 'Correct!'
            : result.resolved
                ? 'Incorrect'
                : l10n.incorrectTryAgain;
    return Card(
      color: (ok ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w700, color: ok ? AppColors.success : AppColors.error),
            ),
            if (!ok && !result.resolved && result.triesLeft > 0) Text(l10n.chancesLeft(result.triesLeft)),
            if (!ok && result.resolved && result.correctAnswer.isNotEmpty) Text('Answer: ${result.correctAnswer}'),
            if (result.stats.xpAwarded > 0) Text('XP: +${result.stats.xpAwarded}'),
          ],
        ),
      ),
    );
  }
}

class WordsMemoryHud extends StatelessWidget {
  const WordsMemoryHud({
    super.key,
    required this.found,
    required this.total,
    required this.combo,
    required this.moves,
  });

  final int found;
  final int total;
  final int combo;
  final int moves;

  @override
  Widget build(BuildContext context) {
    final done = total > 0 && found >= total;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        _MemoryChip(
          icon: Icons.grid_view_rounded,
          label: '$found / $total pairs',
          color: done ? AppColors.success : AppColors.primary,
        ),
        _MemoryChip(
          icon: Icons.touch_app_rounded,
          label: '$moves moves',
          color: AppColors.chartAmber,
        ),
        if (combo >= 2)
          _MemoryChip(
            icon: Icons.bolt_rounded,
            label: 'Combo ×$combo',
            color: AppColors.chartPurple,
          ),
        if (done)
          _MemoryChip(
            icon: Icons.celebration_rounded,
            label: 'All matched!',
            color: AppColors.success,
          ),
      ],
    );
  }
}

class _MemoryChip extends StatelessWidget {
  const _MemoryChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
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
    this.mismatchIds = const {},
    required this.onTap,
  });

  final List<PracticeQuestionCard> cards;
  final Set<String> flippedIds;
  final Set<String> matchedIds;
  final Set<String> mismatchIds;
  final ValueChanged<PracticeQuestionCard> onTap;

  Color _pairColor(String wordId) {
    final palette = AppColors.chartPalette;
    return palette[wordId.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 340 ? 3 : 4;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: AppSpacing.xs,
                crossAxisSpacing: AppSpacing.xs,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                final card = cards[index];
                return _MemoryTile(
                  key: ValueKey(card.id),
                  card: card,
                  open: flippedIds.contains(card.id) || matchedIds.contains(card.id),
                  matched: matchedIds.contains(card.id),
                  mismatch: mismatchIds.contains(card.id),
                  pairColor: _pairColor(card.wordId),
                  onTap: matchedIds.contains(card.id) ? null : () => onTap(card),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MemoryTile extends StatefulWidget {
  const _MemoryTile({
    super.key,
    required this.card,
    required this.open,
    required this.matched,
    required this.mismatch,
    required this.pairColor,
    required this.onTap,
  });

  final PracticeQuestionCard card;
  final bool open;
  final bool matched;
  final bool mismatch;
  final Color pairColor;
  final VoidCallback? onTap;

  @override
  State<_MemoryTile> createState() => _MemoryTileState();
}

class _MemoryTileState extends State<_MemoryTile> with TickerProviderStateMixin {
  late final AnimationController _flip;
  late final AnimationController _pop;
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    if (widget.open) _flip.value = 1;
    if (widget.matched) _pop.value = 1;
  }

  @override
  void didUpdateWidget(covariant _MemoryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open) {
      widget.open ? _flip.forward() : _flip.reverse();
    }
    if (widget.matched && !oldWidget.matched) {
      _pop.forward(from: 0);
    }
    if (widget.mismatch && !oldWidget.mismatch) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    _pop.dispose();
    _shake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = widget.card.side == 'en';
    final backColor = isEn ? AppColors.primary : AppColors.secondary;
    final faceColor = widget.matched
        ? widget.pairColor
        : widget.mismatch
            ? AppColors.danger
            : isEn
                ? AppColors.chartIndigo
                : AppColors.chartCyan;

    return AnimatedBuilder(
      animation: Listenable.merge([_flip, _pop, _shake]),
      builder: (context, _) {
        final angle = _flip.value * math.pi;
        final showFront = _flip.value >= 0.5;
        final shakeX = math.sin(_shake.value * math.pi * 6) * 7 * (1 - _shake.value);
        final scale = 1 + (Curves.elasticOut.transform(_pop.value) * 0.08);
        return Transform.translate(
          offset: Offset(shakeX, 0),
          child: Transform.scale(
            scale: scale,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0014)
                ..rotateY(angle),
              child: MouseRegion(
                cursor: widget.onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: showFront
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(math.pi),
                          child: _MemoryFace(
                            text: widget.card.text,
                            matched: widget.matched,
                            color: faceColor,
                            isEn: isEn,
                          ),
                        )
                      : _MemoryBack(color: backColor, isEn: isEn),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MemoryBack extends StatelessWidget {
  const _MemoryBack({required this.color, required this.isEn});

  final Color color;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.22)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: Icon(
              isEn ? Icons.translate_rounded : Icons.language_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                isEn ? 'EN' : 'UZ',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryFace extends StatelessWidget {
  const _MemoryFace({
    required this.text,
    required this.matched,
    required this.color,
    required this.isEn,
  });

  final String text;
  final bool matched;
  final Color color;
  final bool isEn;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onColor = isDark ? Color.lerp(color, Colors.white, 0.78)! : Color.lerp(color, Colors.black, 0.52)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: matched ? 0.22 : 0.16),
        border: Border.all(color: color, width: matched ? 2 : 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    isEn ? 'EN' : 'UZ',
                    style: TextStyle(color: onColor, fontSize: 9, fontWeight: FontWeight.w800),
                  ),
                ),
                const Spacer(),
                if (matched) Icon(Icons.check_circle_rounded, size: 14, color: color),
              ],
            ),
            Expanded(
              child: Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: onColor,
                    fontWeight: FontWeight.w800,
                    fontSize: text.length > 18 ? 11 : 13,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
