import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/task_integrity_scope.dart';
import '../../../../domain/entities/video.dart';
import '../../../providers/video_provider.dart';

class VideoTestScreen extends ConsumerStatefulWidget {
  const VideoTestScreen({super.key, required this.videoId, required this.mode});

  final String videoId;
  final String mode;

  @override
  ConsumerState<VideoTestScreen> createState() => _VideoTestScreenState();
}

class _VideoTestScreenState extends ConsumerState<VideoTestScreen> with WidgetsBindingObserver {
  VideoTopicTest? _test;
  final Map<String, dynamic> _answers = {};
  VideoTestAttemptResult? _result;
  bool _loading = true;
  int _warnings = 0;
  bool _terminated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTest();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.mode != 'exam' || _result != null || _terminated) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _registerWarning();
    }
  }

  Future<void> _registerWarning() async {
    _warnings += 1;
    final terminate = await ref.read(videoApiProvider).recordWarning(widget.videoId, _warnings);
    if (!mounted) return;
    if (terminate) {
      setState(() => _terminated = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam terminated after 3 warnings.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Warning $_warnings/3 — stay on this screen during the exam.')),
      );
    }
  }

  Future<void> _loadTest() async {
    setState(() => _loading = true);
    try {
      final test = await ref.read(videoApiProvider).getTest(widget.videoId, mode: widget.mode);
      if (mounted) setState(() => _test = test);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_test == null || _terminated) return;
    final answers = _test!.questions
        .map((q) => {'questionId': q.id, 'answer': _answers[q.id]})
        .toList();
    final result = await ref.read(videoApiProvider).submitAttempt(
          widget.videoId,
          mode: widget.mode,
          answers: answers,
          warnings: _warnings,
          terminated: _terminated,
        );
    if (mounted) setState(() => _result = result);
  }

  Widget _buildQuestion(VideoTestQuestion q) {
    switch (q.type) {
      case 'true-false':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(q.question, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'true', label: Text('True')),
                ButtonSegment(value: 'false', label: Text('False')),
              ],
              selected: {_answers[q.id]?.toString() ?? ''},
              onSelectionChanged: (s) => setState(() => _answers[q.id] = s.first),
            ),
          ],
        );
      case 'multiple-choice':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(q.question, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            ...q.options.map(
              (opt) => RadioListTile<String>(
                title: Text(opt),
                value: opt,
                groupValue: _answers[q.id]?.toString(),
                onChanged: (v) => setState(() => _answers[q.id] = v),
              ),
            ),
          ],
        );
      default:
        return TextField(
          decoration: InputDecoration(labelText: q.question, border: const OutlineInputBorder()),
          onChanged: (v) => _answers[q.id] = v,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPractice = widget.mode == 'practice';
    final body = Scaffold(
      appBar: AppBar(title: Text(isPractice ? 'Practice Test' : 'Topic Exam')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _test == null
              ? const Center(child: Text('No test available'))
              : Padding(
                  padding: AppSpacing.listGutter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isPractice)
                        Card(
                          color: Colors.orange.shade50,
                          child: const Padding(
                            padding: EdgeInsets.all(AppSpacing.sm),
                            child: Text('Exam mode: leaving the app counts as a warning (3 = terminated).'),
                          ),
                        ),
                      if (isPractice)
                        Card(
                          color: Colors.orange.shade50,
                          child: const Padding(
                            padding: EdgeInsets.all(AppSpacing.sm),
                            child: Text('Stay in TechRen EDU during this task. Leaving the app signs you out.'),
                          ),
                        ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _test!.questions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md + AppSpacing.xxs),
                          itemBuilder: (_, i) => _buildQuestion(_test!.questions[i]),
                        ),
                      ),
                      if (_result != null) ...[
                        Card(
                          color: _result!.passed
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          child: Padding(
                            padding: AppSpacing.cardPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Score: ${_result!.score}% (${_result!.correctCount}/${_result!.totalQuestions})'),
                                Text(_result!.passed ? 'Passed' : 'Not passed'),
                                if (isPractice)
                                  ..._result!.feedback.where((f) => !f.isCorrect).map(
                                        (f) => Padding(
                                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                                          child: Text('Correct: ${f.correctAnswer}'),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ] else
                        FilledButton(
                          onPressed: _terminated ? null : _submit,
                          child: const Text('Submit'),
                        ),
                    ],
                  ),
                ),
    );

    if (!isPractice) return body;
    return TaskIntegrityScope(child: body);
  }
}
