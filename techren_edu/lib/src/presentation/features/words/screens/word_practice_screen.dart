import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/task_integrity_scope.dart';
import '../../../../domain/entities/words.dart';
import '../../../providers/words_provider.dart';

class WordPracticeScreen extends ConsumerStatefulWidget {
  const WordPracticeScreen({super.key, required this.lessonId, required this.lessonName});

  final String lessonId;
  final String lessonName;

  @override
  ConsumerState<WordPracticeScreen> createState() => _WordPracticeScreenState();
}

class _WordPracticeScreenState extends ConsumerState<WordPracticeScreen> {
  final _answerCtrl = TextEditingController();
  WordPrompt? _prompt;
  AnswerCheckResult? _lastResult;
  bool _loading = false;
  int _attempts = 0;
  int _correct = 0;
  int _enCorrect = 0;
  int _enTotal = 0;
  int _uzCorrect = 0;
  int _uzTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadWord();
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWord() async {
    setState(() {
      _loading = true;
      _lastResult = null;
      _answerCtrl.clear();
    });
    try {
      final word = await ref.read(homeworkApiProvider).getRandomWord(widget.lessonId);
      if (mounted) setState(() => _prompt = word);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _check() async {
    if (_prompt == null || _answerCtrl.text.trim().isEmpty) return;
    final result = await ref.read(homeworkApiProvider).checkAnswer(
          wordId: _prompt!.id,
          answer: _answerCtrl.text.trim(),
          direction: _prompt!.direction,
        );
    setState(() {
      _lastResult = result;
      _attempts += 1;
      if (result.isCorrect) _correct += 1;
      if (_prompt!.direction == 'en-to-uz') {
        _enTotal += 1;
        if (result.isCorrect) _enCorrect += 1;
      } else {
        _uzTotal += 1;
        if (result.isCorrect) _uzCorrect += 1;
      }
    });
    await ref.read(homeworkApiProvider).updatePracticeStats(widget.lessonId, attempts: 1, correct: result.isCorrect ? 1 : 0);
  }

  Future<void> _finish() async {
    if (_attempts > 0) {
      await ref.read(homeworkApiProvider).submitSession(
            totalAttempts: _attempts,
            correctAnswers: _correct,
            enToUzCorrect: _enCorrect,
            enToUzTotal: _enTotal,
            uzToEnCorrect: _uzCorrect,
            uzToEnTotal: _uzTotal,
          );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return TaskIntegrityScope(
      child: Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonName),
        actions: [
          TextButton(onPressed: _finish, child: const Text('Done')),
        ],
      ),
      body: Padding(
        padding: AppSpacing.pagePaddingWide,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Score: $_correct / $_attempts', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.lg),
                  if (_prompt != null) ...[
                    Text(
                      _prompt!.direction == 'en-to-uz' ? 'English → Uzbek' : 'Uzbek → English',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(_prompt!.promptText, style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _answerCtrl,
                      decoration: const InputDecoration(labelText: 'Your answer', border: OutlineInputBorder()),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _check(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(onPressed: _check, child: const Text('Check')),
                    if (_lastResult != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        color: _lastResult!.isCorrect ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                        child: Padding(
                          padding: AppSpacing.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_lastResult!.isCorrect ? 'Correct!' : 'Incorrect'),
                              if (!_lastResult!.isCorrect) Text('Answer: ${_lastResult!.correctAnswer}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(onPressed: _loadWord, child: const Text('Next word')),
                    ],
                  ],
                ],
              ),
      ),
    ),
    );
  }
}
