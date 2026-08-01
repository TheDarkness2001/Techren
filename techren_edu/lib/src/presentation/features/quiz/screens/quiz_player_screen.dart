import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/learning_quiz.dart';
import '../../../providers/learning_quiz_provider.dart';

class QuizPlayerScreen extends ConsumerStatefulWidget {
  const QuizPlayerScreen({
    super.key,
    required this.subjectId,
    required this.quizId,
    this.isStudent = true,
    this.routePrefix = '/student',
  });

  final String subjectId;
  final String quizId;
  final bool isStudent;
  final String routePrefix;

  @override
  ConsumerState<QuizPlayerScreen> createState() => _QuizPlayerScreenState();
}

class _QuizPlayerScreenState extends ConsumerState<QuizPlayerScreen> {
  LearningQuiz? _quiz;
  LearningQuizAttempt? _attempt;
  String? _error;
  bool _loading = true;
  bool _submitting = false;
  final Map<String, int> _mcq = {};
  final Map<String, List<TextEditingController>> _forms = {};

  String get _base => widget.isStudent
      ? '${widget.routePrefix}/learn/${widget.subjectId}/quiz'
      : '${widget.routePrefix}/learning/${widget.subjectId}/quiz';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      if (!widget.isStudent) {
        final quiz = await ref.read(learningQuizApiProvider).getQuiz(widget.quizId);
        setState(() {
          _quiz = quiz;
          _loading = false;
        });
        return;
      }
      final attempt = await ref.read(learningQuizApiProvider).startAttempt(widget.quizId);
      final quiz = attempt.quiz ?? await ref.read(learningQuizApiProvider).getQuiz(widget.quizId);
      for (final q in quiz.questions.where((q) => q.isFormCompletion)) {
        final blanks = '___'.allMatches(q.prompt).length;
        final count = blanks > 0 ? blanks : (q.answers.isNotEmpty ? q.answers.length : 1);
        _forms[q.id] = List.generate(count, (_) => TextEditingController());
      }
      setState(() {
        _attempt = attempt;
        _quiz = quiz;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    for (final list in _forms.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_attempt == null || _quiz == null) return;
    setState(() => _submitting = true);
    try {
      final answers = <LearningQuizAttemptAnswer>[];
      for (final q in _quiz!.questions) {
        if (q.isMcq) {
          answers.add(LearningQuizAttemptAnswer(
            questionId: q.id,
            selectedOptionIndex: _mcq[q.id],
          ));
        } else {
          answers.add(LearningQuizAttemptAnswer(
            questionId: q.id,
            textAnswers: (_forms[q.id] ?? []).map((c) => c.text.trim()).toList(),
          ));
        }
      }
      final result = await ref.read(learningQuizApiProvider).submitAttempt(
            attemptId: _attempt!.id,
            answers: answers,
          );
      ref.invalidate(learningQuizHistoryProvider(widget.subjectId));
      if (mounted) {
        context.go('$_base/results/${result.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingState(message: 'Loading quiz...'));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: EmptyState(title: 'Cannot start quiz', message: _error!, icon: Icons.lock_outline),
      );
    }
    final quiz = _quiz!;
    final labels = ['A', 'B', 'C', 'D'];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quiz.title),
            Text(
              '${quiz.level} · ${quiz.topic}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: AppSpacing.pagePaddingWide,
        children: [
          if (quiz.description.isNotEmpty) ...[
            Text(quiz.description),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            'Pass mark: ${quiz.passingScore}%'
            '${quiz.timeLimitMinutes > 0 ? ' · ${quiz.timeLimitMinutes} min' : ''}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < quiz.questions.length; i++) ...[
            _QuestionCard(
              index: i,
              question: quiz.questions[i],
              labels: labels,
              selected: _mcq[quiz.questions[i].id],
              formControllers: _forms[quiz.questions[i].id],
              readOnly: !widget.isStudent,
              onSelect: widget.isStudent
                  ? (opt) => setState(() => _mcq[quiz.questions[i].id] = opt)
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (widget.isStudent)
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit quiz'),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.labels,
    required this.selected,
    required this.formControllers,
    required this.readOnly,
    required this.onSelect,
  });

  final int index;
  final LearningQuizQuestion question;
  final List<String> labels;
  final int? selected;
  final List<TextEditingController>? formControllers;
  final bool readOnly;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Q${index + 1}. ${question.prompt}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (question.isMcq)
              for (var o = 0; o < question.options.length; o++)
                RadioListTile<int>(
                  value: o,
                  groupValue: selected,
                  onChanged: readOnly || onSelect == null ? null : (v) => onSelect!(v ?? o),
                  title: Text('${labels[o < labels.length ? o : 0]}. ${question.options[o]}'),
                )
            else
              for (var a = 0; a < (formControllers?.length ?? 0); a++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: TextField(
                    controller: formControllers![a],
                    enabled: !readOnly,
                    decoration: InputDecoration(labelText: 'Blank ${a + 1}'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class QuizResultsScreen extends ConsumerStatefulWidget {
  const QuizResultsScreen({
    super.key,
    required this.subjectId,
    required this.attemptId,
    this.routePrefix = '/student',
  });

  final String subjectId;
  final String attemptId;
  final String routePrefix;

  @override
  ConsumerState<QuizResultsScreen> createState() => _QuizResultsScreenState();
}

class _QuizResultsScreenState extends ConsumerState<QuizResultsScreen> {
  LearningQuizAttempt? _attempt;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final attempt = await ref.read(learningQuizApiProvider).getAttempt(widget.attemptId);
      setState(() {
        _attempt = attempt;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingState(message: 'Loading results...'));
    if (_error != null || _attempt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: EmptyState(title: 'Results unavailable', message: _error ?? 'Unknown error'),
      );
    }
    final a = _attempt!;
    final quiz = a.quiz;
    final base = '${widget.routePrefix}/learn/${widget.subjectId}/quiz';

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz results')),
      body: ListView(
        padding: AppSpacing.pagePaddingWide,
        children: [
          Icon(
            a.passed ? Icons.emoji_events_outlined : Icons.replay_outlined,
            size: 56,
            color: a.passed ? Colors.amber : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            a.passed ? 'Passed' : 'Not passed',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            '${a.scorePercent}% · ${a.pointsEarned}/${a.pointsPossible} points'
            '${quiz != null ? ' · pass at ${quiz.passingScore}%' : ''}',
            textAlign: TextAlign.center,
          ),
          if (quiz != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${quiz.title} · ${quiz.level} · ${quiz.topic}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (quiz != null)
            for (var i = 0; i < quiz.questions.length; i++) ...[
              Builder(
                builder: (context) {
                  final q = quiz.questions[i];
                  final matches = a.answers.where((x) => x.questionId == q.id);
                  final ans = matches.isEmpty ? null : matches.first;
                  final ok = ans?.correct == true;
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        ok ? Icons.check_circle : Icons.cancel,
                        color: ok ? Colors.green : Colors.redAccent,
                      ),
                      title: Text('Q${i + 1}. ${q.prompt}'),
                      subtitle: Text(
                        q.isMcq
                            ? 'Your answer: ${ans?.selectedOptionIndex != null && ans!.selectedOptionIndex! < q.options.length ? q.options[ans.selectedOptionIndex!] : '—'}'
                            : 'Your answers: ${(ans?.textAnswers ?? const []).join(', ')}',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          FilledButton(
            onPressed: () => context.go(base),
            child: const Text('Back to quizzes'),
          ),
        ],
      ),
    );
  }
}
