import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../providers/learning_quiz_provider.dart';
import 'quiz_hub_screen.dart';

class QuizManageScreen extends ConsumerWidget {
  const QuizManageScreen({
    super.key,
    required this.subjectId,
    required this.routePrefix,
    this.quizId,
  });

  final String subjectId;
  final String routePrefix;
  final String? quizId;

  String get _base => '$routePrefix/learning/$subjectId/quiz';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (quizId != null) {
      return _QuizEditor(
        subjectId: subjectId,
        quizId: quizId!,
        routePrefix: routePrefix,
      );
    }

    final quizzesAsync = ref.watch(learningQuizzesProvider(subjectId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage quizzes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(_base),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('$_base/manage/new'),
        icon: const Icon(Icons.add),
        label: const Text('New quiz'),
      ),
      body: quizzesAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => EmptyState(title: 'Error', message: e.toString()),
        data: (quizzes) {
          if (quizzes.isEmpty) {
            return const EmptyState(
              title: 'No quizzes',
              message: 'Create a quiz for a topic and level.',
              icon: Icons.quiz_outlined,
            );
          }
          return ListView.separated(
            padding: AppSpacing.pagePaddingWide,
            itemCount: quizzes.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final q = quizzes[i];
              return Card(
                child: ListTile(
                  title: Text(q.title),
                  subtitle: Text(
                    '${q.level} · ${q.topic} · ${q.questionCount} Q · '
                    '${q.published ? 'Published' : 'Draft'} · '
                    '${q.unlockedFor.length} groups unlocked',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        context.go('$_base/manage/${q.id}');
                      } else if (value == 'unlock') {
                        await showQuizUnlockDialog(context, ref, q);
                      } else if (value == 'delete') {
                        await ref.read(learningQuizApiProvider).deleteQuiz(q.id);
                        ref.invalidate(learningQuizzesProvider(subjectId));
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'unlock', child: Text('Unlock / lock group')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                  onTap: () => context.go('$_base/manage/${q.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _QuizEditor extends ConsumerStatefulWidget {
  const _QuizEditor({
    required this.subjectId,
    required this.quizId,
    required this.routePrefix,
  });

  final String subjectId;
  final String quizId;
  final String routePrefix;

  @override
  ConsumerState<_QuizEditor> createState() => _QuizEditorState();
}

class _DraftQuestion {
  _DraftQuestion({
    this.id = '',
    this.type = 'mcq',
    this.prompt = '',
    List<String>? options,
    this.correctOptionIndex = 0,
    List<String>? answers,
    this.points = 1,
  })  : options = options ?? ['', '', '', ''],
        answers = answers ?? [''];

  String id;
  String type;
  String prompt;
  List<String> options;
  int correctOptionIndex;
  List<String> answers;
  int points;

  Map<String, dynamic> toPayload() => {
        if (id.isNotEmpty) 'id': id,
        'type': type,
        'prompt': prompt.trim(),
        'options': type == 'mcq' ? options.map((o) => o.trim()).where((o) => o.isNotEmpty).toList() : [],
        'correctOptionIndex': correctOptionIndex,
        'answers': type == 'form_completion'
            ? answers.map((a) => a.trim()).where((a) => a.isNotEmpty).toList()
            : [],
        'points': points,
      };
}

class _QuizEditorState extends ConsumerState<_QuizEditor> {
  final _title = TextEditingController();
  final _topic = TextEditingController();
  final _level = TextEditingController(text: 'A1');
  final _description = TextEditingController();
  final _passing = TextEditingController(text: '70');
  final _timeLimit = TextEditingController(text: '0');
  bool _published = false;
  bool _loading = true;
  bool _saving = false;
  final List<_DraftQuestion> _questions = [];

  String get _base => '${widget.routePrefix}/learning/${widget.subjectId}/quiz';
  bool get _isNew => widget.quizId == 'new';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (_isNew) {
      _questions.add(_DraftQuestion());
      setState(() => _loading = false);
      return;
    }
    try {
      final quiz = await ref.read(learningQuizApiProvider).getQuiz(widget.quizId);
      _title.text = quiz.title;
      _topic.text = quiz.topic;
      _level.text = quiz.level;
      _description.text = quiz.description;
      _passing.text = '${quiz.passingScore}';
      _timeLimit.text = '${quiz.timeLimitMinutes}';
      _published = quiz.published;
      _questions
        ..clear()
        ..addAll(quiz.questions.map((q) {
          final opts = [...q.options];
          while (opts.length < 4) {
            opts.add('');
          }
          return _DraftQuestion(
            id: q.id,
            type: q.type,
            prompt: q.prompt,
            options: opts.take(4).toList(),
            correctOptionIndex: q.correctOptionIndex ?? 0,
            answers: q.answers.isEmpty ? [''] : q.answers,
            points: q.points,
          );
        }));
      if (_questions.isEmpty) _questions.add(_DraftQuestion());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _topic.dispose();
    _level.dispose();
    _description.dispose();
    _passing.dispose();
    _timeLimit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = {
        'subjectId': widget.subjectId,
        'title': _title.text.trim(),
        'topic': _topic.text.trim(),
        'level': _level.text.trim(),
        'description': _description.text.trim(),
        'published': _published,
        'passingScore': int.tryParse(_passing.text.trim()) ?? 70,
        'timeLimitMinutes': int.tryParse(_timeLimit.text.trim()) ?? 0,
        'questions': _questions.map((q) => q.toPayload()).toList(),
      };
      if (_isNew) {
        await ref.read(learningQuizApiProvider).createQuiz(body);
      } else {
        await ref.read(learningQuizApiProvider).updateQuiz(widget.quizId, body);
      }
      ref.invalidate(learningQuizzesProvider(widget.subjectId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quiz saved')));
        context.go('$_base/manage');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingState(kind: LoadingSkeletonKind.list));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New quiz' : 'Edit quiz'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('$_base/manage'),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.pagePaddingWide,
        children: [
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: AppSpacing.sm),
          TextField(controller: _topic, decoration: const InputDecoration(labelText: 'Topic')),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _level,
            decoration: const InputDecoration(labelText: 'Level (e.g. A1, B1)'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 2,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _passing,
                  decoration: const InputDecoration(labelText: 'Pass %'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _timeLimit,
                  decoration: const InputDecoration(labelText: 'Time limit (min, 0=off)'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Published'),
            subtitle: const Text('Students only see published quizzes'),
            value: _published,
            onChanged: (v) => setState(() => _published = v),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Questions', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _questions.add(_DraftQuestion())),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
          for (var i = 0; i < _questions.length; i++) _buildQuestionEditor(i),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildQuestionEditor(int index) {
    final q = _questions[index];
    final labels = ['A', 'B', 'C', 'D'];
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Q${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                DropdownButton<String>(
                  value: q.type,
                  items: const [
                    DropdownMenuItem(value: 'mcq', child: Text('ABCD (MCQ)')),
                    DropdownMenuItem(value: 'form_completion', child: Text('Form completion')),
                  ],
                  onChanged: (v) => setState(() => q.type = v ?? 'mcq'),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: _questions.length <= 1
                      ? null
                      : () => setState(() => _questions.removeAt(index)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            TextFormField(
              initialValue: q.prompt,
              decoration: InputDecoration(
                labelText: q.type == 'form_completion'
                    ? 'Prompt (use ___ for blanks)'
                    : 'Question prompt',
              ),
              maxLines: 3,
              onChanged: (v) => q.prompt = v,
            ),
            if (q.type == 'mcq') ...[
              const SizedBox(height: AppSpacing.sm),
              for (var o = 0; o < 4; o++)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Radio<int>(
                      value: o,
                      groupValue: q.correctOptionIndex,
                      onChanged: (v) => setState(() => q.correctOptionIndex = v ?? 0),
                    ),
                    Expanded(
                      child: TextFormField(
                        initialValue: q.options[o],
                        decoration: InputDecoration(
                          labelText: 'Option ${labels[o]}',
                          isDense: true,
                        ),
                        onChanged: (v) => q.options[o] = v,
                      ),
                    ),
                  ],
                ),
              Text('Selected radio = correct answer', style: Theme.of(context).textTheme.bodySmall),
            ] else ...[
              const SizedBox(height: AppSpacing.sm),
              for (var a = 0; a < q.answers.length; a++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: q.answers[a],
                          decoration: InputDecoration(labelText: 'Blank ${a + 1} answer'),
                          onChanged: (v) => q.answers[a] = v,
                        ),
                      ),
                      IconButton(
                        onPressed: q.answers.length <= 1
                            ? null
                            : () => setState(() => q.answers.removeAt(a)),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                    ],
                  ),
                ),
              TextButton.icon(
                onPressed: () => setState(() => q.answers.add('')),
                icon: const Icon(Icons.add),
                label: const Text('Add blank answer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
