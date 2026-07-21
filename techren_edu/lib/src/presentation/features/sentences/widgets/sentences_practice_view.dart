import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/sentences.dart';
import '../../../providers/sentences_provider.dart';

class SentencesPracticeView extends ConsumerStatefulWidget {
  const SentencesPracticeView({
    super.key,
    required this.lessonId,
    required this.lessonName,
    required this.onBack,
    required this.onEnd,
  });

  final String lessonId;
  final String lessonName;
  final VoidCallback onBack;
  final VoidCallback onEnd;

  @override
  ConsumerState<SentencesPracticeView> createState() => _SentencesPracticeViewState();
}

class _SentencesPracticeViewState extends ConsumerState<SentencesPracticeView> {
  final _answerCtrl = TextEditingController();
  SentencePrompt? _prompt;
  SentenceCheckResult? _result;
  bool _loading = false;
  int _attempts = 0;
  int _correct = 0;

  @override
  void initState() {
    super.initState();
    _loadSentence();
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  int get _accuracy => _attempts == 0 ? 0 : ((_correct / _attempts) * 100).round();

  Future<void> _loadSentence() async {
    setState(() {
      _loading = true;
      _result = null;
      _answerCtrl.clear();
    });
    try {
      final prompt = await ref.read(sentencesApiProvider).getRandomSentence(widget.lessonId, direction: 'enToUz');
      if (mounted) setState(() => _prompt = prompt);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _check() async {
    if (_prompt == null || _answerCtrl.text.trim().isEmpty) return;
    final result = await ref.read(sentencesApiProvider).checkAnswer(
          sentenceId: _prompt!.id,
          answer: _answerCtrl.text.trim(),
          direction: _prompt!.direction,
        );
    setState(() {
      _result = result;
      _attempts += 1;
      if (result.isCorrect) _correct += 1;
    });
  }

  Future<void> _skip() async {
    setState(() => _attempts += 1);
    await _loadSentence();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            FilledButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to Classes'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5A6268),
                foregroundColor: Colors.white,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.semantic.surfaceContainer,
                borderRadius: AppRadius.card,
              ),
              child: Text('Score: $_correct/$_attempts · Accuracy: $_accuracy%'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CircularProgressIndicator()))
        else if (_prompt != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppRadius.card,
              border: Border.all(color: context.semantic.border),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'TRANSLATE TO UZBEK',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _prompt!.english,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _answerCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Type Uzbek translation...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _check(),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: _skip,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5A6268),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Skip'),
                ),
                if (_result != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    _result!.isCorrect ? 'Correct!' : 'Correct answer: ${_result!.correctAnswer}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _result!.isCorrect ? AppColors.success : AppColors.danger),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(onPressed: _loadSentence, child: const Text('Next sentence')),
                ] else ...[
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(onPressed: _check, child: const Text('Check')),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: FilledButton(
            onPressed: widget.onEnd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            ),
            child: const Text('End Practice'),
          ),
        ),
      ],
    );
  }
}
