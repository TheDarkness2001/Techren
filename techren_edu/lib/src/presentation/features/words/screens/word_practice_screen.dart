import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/task_integrity_scope.dart';
import '../../../../domain/entities/words.dart';
import '../../../providers/words_provider.dart';
import '../widgets/words_practice_widgets.dart';

class WordPracticeScreen extends ConsumerStatefulWidget {
  const WordPracticeScreen({super.key, required this.lessonId, required this.lessonName});

  final String lessonId;
  final String lessonName;

  @override
  ConsumerState<WordPracticeScreen> createState() => _WordPracticeScreenState();
}

class _WordPracticeScreenState extends ConsumerState<WordPracticeScreen> with WidgetsBindingObserver {
  final _answerCtrl = TextEditingController();
  String _mode = 'classic';
  int _timeAttackSeconds = 60;
  PracticeQuestion? _question;
  PracticeAnswerResult? _lastResult;
  bool _loading = false;
  bool _sessionOver = false;
  int _correct = 0;
  int _attempts = 0;
  int _streak = 0;
  int _xp = 0;
  int _rushStep = 0;
  int? _remainingSeconds;
  Timer? _sessionTimer;
  Timer? _rushTimer;
  Set<String> _flipped = {};
  Set<String> _matched = {};
  final List<List<String>> _memoryMatches = [];
  String? _firstFlipId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadQuestion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelTimers();
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_mode == 'timeAttack' && _sessionTimer != null) {
        _endTimeAttack();
      }
    }
  }

  void _cancelTimers() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _rushTimer?.cancel();
    _rushTimer = null;
  }

  Future<void> _loadQuestion() async {
    if (_sessionOver) return;
    setState(() {
      _loading = true;
      _lastResult = null;
      _answerCtrl.clear();
      _flipped = {};
      _matched = {};
      _memoryMatches.clear();
      _firstFlipId = null;
    });
    try {
      final question = await ref.read(homeworkApiProvider).nextPractice(
            lessonId: widget.lessonId,
            mode: _mode,
            rushStep: _rushStep,
          );
      if (!mounted) return;
      setState(() => _question = question);
      _armRushTimer(question);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _armRushTimer(PracticeQuestion question) {
    _rushTimer?.cancel();
    if (_mode != 'wordRush' || question.timeLimitMs == null) return;
    _rushTimer = Timer(Duration(milliseconds: question.timeLimitMs!), () {
      if (!mounted || _lastResult != null) return;
      _submit(answer: '');
    });
  }

  void _startTimeAttackIfNeeded() {
    if (_mode != 'timeAttack' || _sessionTimer != null) return;
    setState(() => _remainingSeconds = _timeAttackSeconds);
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = (_remainingSeconds ?? 1) - 1;
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (left <= 0) {
        _endTimeAttack();
        return;
      }
      setState(() => _remainingSeconds = left);
    });
  }

  void _endTimeAttack() {
    _cancelTimers();
    if (!mounted) return;
    setState(() {
      _sessionOver = true;
      _remainingSeconds = 0;
    });
  }

  Future<void> _changeMode(String mode) async {
    _cancelTimers();
    setState(() {
      _mode = mode;
      _sessionOver = false;
      _correct = 0;
      _attempts = 0;
      _streak = 0;
      _xp = 0;
      _rushStep = 0;
      _remainingSeconds = mode == 'timeAttack' ? _timeAttackSeconds : null;
      _lastResult = null;
      _question = null;
    });
    await _loadQuestion();
  }

  Future<void> _submit({String? answer, List<List<String>>? matches}) async {
    final question = _question;
    if (question == null || _loading) return;
    _rushTimer?.cancel();
    _startTimeAttackIfNeeded();
    setState(() => _loading = true);
    try {
      final result = await ref.read(homeworkApiProvider).submitPracticeAnswer(
            questionId: question.questionId,
            answer: answer ?? _answerCtrl.text.trim(),
            matches: matches,
            streak: _mode == 'streak' ? (_streak + ((answer ?? _answerCtrl.text).isEmpty ? 0 : 1)) : _streak,
            timeAttackScore: _mode == 'timeAttack' ? _correct : null,
            timeAttackDuration: _mode == 'timeAttack' ? _timeAttackSeconds : null,
            wordRushScore: _mode == 'wordRush' ? _correct : null,
          );
      if (!mounted) return;
      setState(() {
        _lastResult = result;
        _attempts += 1;
        if (result.isCorrect) {
          _correct += 1;
          _streak += 1;
          if (_mode == 'wordRush') _rushStep += 1;
        } else {
          _streak = 0;
        }
        _xp += result.stats.xpAwarded;
      });
      if (_mode == 'timeAttack' || _mode == 'wordRush' || _mode == 'streak') {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (mounted && !_sessionOver) await _loadQuestion();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onMemoryTap(PracticeQuestionCard card) {
    if (_matched.contains(card.id) || _flipped.contains(card.id) || _lastResult != null) return;
    setState(() => _flipped = {..._flipped, card.id});
    final firstId = _firstFlipId;
    if (firstId == null) {
      _firstFlipId = card.id;
      return;
    }
    final first = _question!.cards.firstWhere((c) => c.id == firstId);
    if (first.wordId == card.wordId && first.side != card.side) {
      setState(() {
        _matched = {..._matched, first.id, card.id};
        _memoryMatches.add([first.id, card.id]);
        _firstFlipId = null;
      });
      if (_matched.length == _question!.cards.length) {
        _submit(matches: _memoryMatches);
      }
    } else {
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _flipped.remove(first.id);
          _flipped.remove(card.id);
          _firstFlipId = null;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _question;
    return TaskIntegrityScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.lessonName),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
          ],
        ),
        body: ListView(
          padding: AppSpacing.pagePaddingWide,
          children: [
            Text('Vocabulary Practice', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            WordsPracticeModeSelector(selected: _mode, onSelected: _changeMode),
            if (_mode == 'timeAttack') ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final seconds in [30, 60, 90])
                    ChoiceChip(
                      label: Text('${seconds}s'),
                      selected: _timeAttackSeconds == seconds,
                      onSelected: _sessionTimer != null
                          ? null
                          : (_) => setState(() {
                                _timeAttackSeconds = seconds;
                                _remainingSeconds = seconds;
                              }),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            WordsPracticeStatsBar(
              correct: _correct,
              attempts: _attempts,
              streak: _streak,
              xp: _xp,
              remainingSeconds: _remainingSeconds,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_sessionOver)
              _TimeUpCard(correct: _correct, attempts: _attempts, xp: _xp)
            else if (_loading && question == null)
              const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.xl), child: CircularProgressIndicator()))
            else if (question != null) ...[
              if (question.direction == 'en-to-uz' || question.direction == 'uz-to-en')
                Text(
                  question.direction == 'en-to-uz' ? 'English → Uzbek' : 'Uzbek → English',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                question.statement ??
                    question.masked ??
                    question.scrambled ??
                    question.promptText,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (question.hint != null && question.hint!.isNotEmpty && (question.masked != null || question.scrambled != null)) ...[
                const SizedBox(height: AppSpacing.xs),
                Text('Uzbek: ${question.hint}', style: Theme.of(context).textTheme.bodyLarge),
              ],
              const SizedBox(height: AppSpacing.lg),
              ..._buildInteractive(question),
              if (_lastResult != null) ...[
                const SizedBox(height: AppSpacing.md),
                WordsPracticeFeedback(result: _lastResult!),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: _sessionOver ? null : _loadQuestion,
                  child: const Text('Next word'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInteractive(PracticeQuestion question) {
    if (_lastResult != null && question.mode != 'memory') return const [];
    switch (question.mode) {
      case 'multipleChoice':
        return [
          for (final choice in question.choices)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: OutlinedButton(
                onPressed: _loading ? null : () => _submit(answer: choice),
                child: Align(alignment: Alignment.centerLeft, child: Text(choice)),
              ),
            ),
        ];
      case 'trueFalse':
        return [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _loading ? null : () => _submit(answer: 'true'),
                  child: const Text('TRUE'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: _loading ? null : () => _submit(answer: 'false'),
                  child: const Text('FALSE'),
                ),
              ),
            ],
          ),
        ];
      case 'memory':
        return [
          WordsMemoryBoard(
            cards: question.cards,
            flippedIds: _flipped,
            matchedIds: _matched,
            onTap: _onMemoryTap,
          ),
        ];
      default:
        return [
          TextField(
            controller: _answerCtrl,
            enabled: !_loading,
            decoration: const InputDecoration(labelText: 'Your answer', border: OutlineInputBorder()),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: _loading ? null : () => _submit(), child: const Text('Check')),
        ];
    }
  }
}

class _TimeUpCard extends StatelessWidget {
  const _TimeUpCard({required this.correct, required this.attempts, required this.xp});

  final int correct;
  final int attempts;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final incorrect = attempts - correct;
    final accuracy = attempts == 0 ? 0 : ((correct / attempts) * 100).round();
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Time's up!", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text('Correct: $correct'),
            Text('Incorrect: $incorrect'),
            Text('Accuracy: $accuracy%'),
            Text('XP: +$xp'),
          ],
        ),
      ),
    );
  }
}
