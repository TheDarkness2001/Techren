import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/sentences.dart';
import '../../../providers/sentences_provider.dart';

class SentencePracticeScreen extends ConsumerStatefulWidget {
  const SentencePracticeScreen({super.key, required this.lessonId, required this.lessonName});

  final String lessonId;
  final String lessonName;

  @override
  ConsumerState<SentencePracticeScreen> createState() => _SentencePracticeScreenState();
}

class _SentencePracticeScreenState extends ConsumerState<SentencePracticeScreen> {
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

  Future<void> _loadSentence() async {
    setState(() {
      _loading = true;
      _result = null;
      _answerCtrl.clear();
    });
    try {
      final prompt = await ref.read(sentencesApiProvider).getRandomSentence(widget.lessonId);
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

  String _categoryLabel(String category) {
    switch (category) {
      case 'missingArticle':
        return 'Missing article';
      case 'wrongArticle':
        return 'Wrong article';
      case 'missingWords':
        return 'Missing words';
      case 'extraWords':
        return 'Extra words';
      case 'wrongWord':
        return 'Wrong word';
      case 'wrongWordOrder':
        return 'Wrong word order';
      case 'missingPunctuation':
        return 'Punctuation';
      case 'missingPeriod':
        return 'Missing period';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lessonName)),
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
                      _prompt!.direction == 'uzToEn' ? 'Uzbek → English' : 'English → Uzbek',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(_prompt!.promptText, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _answerCtrl,
                      decoration: const InputDecoration(labelText: 'Your translation', border: OutlineInputBorder()),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _check(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(onPressed: _check, child: const Text('Check')),
                    if (_result != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        color: _result!.isCorrect
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        child: Padding(
                          padding: AppSpacing.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_result!.isCorrect ? 'Correct!' : 'Needs improvement'),
                              Text('Similarity: ${_result!.similarityScore}%'),
                              if (!_result!.isCorrect) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text('Correct: ${_result!.correctAnswer}'),
                                if (_result!.categories.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Wrap(
                                    spacing: AppSpacing.xs,
                                    children: _result!.categories
                                        .map((c) => Chip(label: Text(_categoryLabel(c))))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton(onPressed: _loadSentence, child: const Text('Next sentence')),
                    ],
                  ],
                ],
              ),
      ),
    );
  }
}
