import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/ielts.dart';
import '../../../providers/ielts_provider.dart';
import '../widgets/ielts_audio_once_player.dart';

class IeltsExamPlayerScreen extends ConsumerStatefulWidget {
  const IeltsExamPlayerScreen({
    super.key,
    required this.subjectId,
    required this.examId,
    this.routePrefix = '/student',
  });

  final String subjectId;
  final String examId;
  final String routePrefix;

  @override
  ConsumerState<IeltsExamPlayerScreen> createState() => _IeltsExamPlayerScreenState();
}

class _IeltsExamPlayerScreenState extends ConsumerState<IeltsExamPlayerScreen> {
  IeltsAttemptBundle? _bundle;
  String? _error;
  bool _loading = true;
  bool _submitting = false;

  final Map<String, dynamic> _answers = {};
  final Map<String, bool> _flags = {};
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, TextEditingController> _writingControllers = {};

  int _sectionIndex = 0;
  int _questionIndex = 0;
  int _remainingSeconds = 0;
  Timer? _tick;
  Timer? _autosave;
  bool _audioPlayed = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _autosave?.cancel();
    for (final c in _textControllers.values) {
      c.dispose();
    }
    for (final c in _writingControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(ieltsApiProvider);
      final bundle = await api.startAttempt(widget.examId);
      _answers.addAll(bundle.attempt.answers);
      _flags.addAll(bundle.attempt.flags);
      for (final entry in bundle.attempt.writingResponses.entries) {
        _writingControllers[entry.key] = TextEditingController(text: entry.value);
      }
      final sections = bundle.exam.sections;
      var sIdx = 0;
      if (bundle.attempt.currentSectionId != null) {
        final i = sections.indexWhere((s) => s.id == bundle.attempt.currentSectionId);
        if (i >= 0) sIdx = i;
      }
      _sectionIndex = sIdx;
      _remainingSeconds = bundle.attempt.remainingSeconds ?? bundle.exam.timers.totalSecondsForMode(bundle.exam.mode);
      _audioPlayed = bundle.attempt.audioPlayed;
      _bundle = bundle;
      _startTimers();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _startTimers() {
    _tick?.cancel();
    _autosave?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _submitting) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds -= 1;
        } else {
          _tick?.cancel();
          _submit(auto: true);
        }
      });
    });
    _autosave = Timer.periodic(const Duration(seconds: 8), (_) => _save());
  }

  Future<void> _save() async {
    final bundle = _bundle;
    if (bundle == null || _submitting) return;
    final writing = <String, String>{};
    for (final e in _writingControllers.entries) {
      writing[e.key] = e.value.text;
    }
    final sectionId = bundle.exam.sections.isNotEmpty ? bundle.exam.sections[_sectionIndex].id : null;
    try {
      await ref.read(ieltsApiProvider).autosave(
            bundle.attempt.id,
            answers: Map<String, dynamic>.from(_answers),
            flags: Map<String, bool>.from(_flags),
            writingResponses: writing,
            currentSectionId: sectionId,
            remainingSeconds: _remainingSeconds,
            audioPlayed: _audioPlayed,
          );
    } catch (_) {
      // Keep local state; next autosave retries.
    }
  }

  Future<void> _submit({bool auto = false}) async {
    if (_submitting || _bundle == null) return;
    if (!auto) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Submit exam?'),
          content: const Text('You cannot change answers after submission.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _submitting = true);
    await _save();
    try {
      final result = await ref.read(ieltsApiProvider).submitAttempt(_bundle!.attempt.id);
      if (!mounted) return;
      context.go('${widget.routePrefix}/learn/${widget.subjectId}/ielts/results/${result.attempt.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
    }
  }

  IeltsSection? get _section {
    final sections = _bundle?.exam.sections;
    if (sections == null || sections.isEmpty) return null;
    return sections[_sectionIndex.clamp(0, sections.length - 1)];
  }

  TextEditingController _controllerFor(String qid) {
    return _textControllers.putIfAbsent(
      qid,
      () => TextEditingController(text: _answers[qid]?.toString() ?? ''),
    );
  }

  TextEditingController _writingController(String sectionId) {
    return _writingControllers.putIfAbsent(sectionId, () => TextEditingController());
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: LoadingState(message: 'Starting exam...'));
    }
    if (_error != null || _bundle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('IELTS Exam')),
        body: ErrorState(message: _error ?? 'Unable to start', onRetry: _bootstrap),
      );
    }

    final exam = _bundle!.exam;
    final section = _section;
    final questions = section?.questions.where((q) => !q.isWriting).toList() ?? const <IeltsQuestion>[];
    final isWriting = section?.skill == 'writing';
    final muted = context.semantic.textMuted;

    return Scaffold(
      appBar: AppBar(
        title: Text(exam.title),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _remainingSeconds < 60
                    ? Colors.red.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatTime(_remainingSeconds),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: _remainingSeconds < 60 ? Colors.red : AppColors.primary,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: _submitting ? null : () => _submit(),
            child: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit'),
          ),
        ],
      ),
      body: Column(
        children: [
          _SectionTabs(
            sections: exam.sections,
            index: _sectionIndex,
            onSelect: (i) {
              setState(() {
                _sectionIndex = i;
                _questionIndex = 0;
              });
              _save();
            },
          ),
          if (!isWriting)
            _QuestionNavigator(
              questions: questions,
              current: _questionIndex,
              flags: _flags,
              answers: _answers,
              onSelect: (i) => setState(() => _questionIndex = i),
            ),
          Expanded(
            child: section == null
                ? const Center(child: Text('No sections'))
                : isWriting
                    ? _WritingPane(
                        section: section,
                        controller: _writingController(section.id),
                        onChanged: (_) => setState(() {}),
                      )
                    : _ObjectivePane(
                        section: section,
                        question: questions.isEmpty ? null : questions[_questionIndex.clamp(0, questions.length - 1)],
                        answers: _answers,
                        flags: _flags,
                        audioPlayed: _audioPlayed,
                        controllerFor: _controllerFor,
                        onAnswer: (qid, value) {
                          setState(() => _answers[qid] = value);
                        },
                        onToggleFlag: (qid) {
                          setState(() => _flags[qid] = !(_flags[qid] == true));
                        },
                        onAudioPlayed: () {
                          setState(() => _audioPlayed = true);
                          _save();
                        },
                      ),
          ),
          if (!isWriting && questions.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: _questionIndex > 0 ? () => setState(() => _questionIndex -= 1) : null,
                      child: const Text('Previous'),
                    ),
                    const Spacer(),
                    Text('${_questionIndex + 1} / ${questions.length}', style: TextStyle(color: muted)),
                    const Spacer(),
                    FilledButton(
                      onPressed: _questionIndex < questions.length - 1
                          ? () => setState(() => _questionIndex += 1)
                          : (_sectionIndex < exam.sections.length - 1
                              ? () => setState(() {
                                    _sectionIndex += 1;
                                    _questionIndex = 0;
                                  })
                              : () => _submit()),
                      child: Text(_questionIndex < questions.length - 1
                          ? 'Next'
                          : (_sectionIndex < exam.sections.length - 1 ? 'Next section' : 'Submit')),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({required this.sections, required this.index, required this.onSelect});
  final List<IeltsSection> sections;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < sections.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(sections[i].title.isNotEmpty ? sections[i].title : sections[i].skill),
                selected: i == index,
                onSelected: (_) => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuestionNavigator extends StatelessWidget {
  const _QuestionNavigator({
    required this.questions,
    required this.current,
    required this.flags,
    required this.answers,
    required this.onSelect,
  });

  final List<IeltsQuestion> questions;
  final int current;
  final Map<String, bool> flags;
  final Map<String, dynamic> answers;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final q = questions[i];
          final answered = answers[q.id] != null && answers[q.id].toString().trim().isNotEmpty;
          final flagged = flags[q.id] == true;
          return InkWell(
            onTap: () => onSelect(i),
            child: Container(
              width: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i == current
                    ? AppColors.primary
                    : answered
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: flagged ? Border.all(color: Colors.orange, width: 2) : null,
              ),
              child: Text(
                '${q.number}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: i == current ? Colors.white : null,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ObjectivePane extends StatelessWidget {
  const _ObjectivePane({
    required this.section,
    required this.question,
    required this.answers,
    required this.flags,
    required this.audioPlayed,
    required this.controllerFor,
    required this.onAnswer,
    required this.onToggleFlag,
    required this.onAudioPlayed,
  });

  final IeltsSection section;
  final IeltsQuestion? question;
  final Map<String, dynamic> answers;
  final Map<String, bool> flags;
  final bool audioPlayed;
  final TextEditingController Function(String qid) controllerFor;
  final void Function(String qid, dynamic value) onAnswer;
  final ValueChanged<String> onToggleFlag;
  final VoidCallback onAudioPlayed;

  @override
  Widget build(BuildContext context) {
    if (question == null) {
      return const Center(child: Text('No questions in this section'));
    }
    final q = question!;
    final muted = context.semantic.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.skill == 'reading' && section.passage.isNotEmpty)
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: AppRadius.card,
                border: Border.all(color: context.semantic.border),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: SingleChildScrollView(
                child: SelectableText(section.passage, style: const TextStyle(height: 1.5, fontSize: 15)),
              ),
            ),
          ),
        Expanded(
          flex: 5,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (section.skill == 'listening') ...[
                Text(section.instructions, style: TextStyle(color: muted)),
                const SizedBox(height: 8),
                if (section.hasAudio)
                  IeltsAudioOncePlayer(
                    sectionId: section.id,
                    alreadyPlayed: audioPlayed,
                    onPlayed: onAudioPlayed,
                  )
                else
                  Text('No audio uploaded for this section.', style: TextStyle(color: muted)),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Text('Question ${q.number}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Flag for review',
                    onPressed: () => onToggleFlag(q.id),
                    icon: Icon(
                      flags[q.id] == true ? Icons.flag : Icons.flag_outlined,
                      color: flags[q.id] == true ? Colors.orange : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(q.prompt, style: const TextStyle(height: 1.4, fontSize: 16)),
              const SizedBox(height: 16),
              if (q.options.isNotEmpty)
                ...q.options.map((opt) {
                  final selected = answers[q.id]?.toString() == opt;
                  return RadioListTile<String>(
                    value: opt,
                    groupValue: answers[q.id]?.toString(),
                    title: Text(opt),
                    onChanged: (v) {
                      if (v != null) onAnswer(q.id, v);
                    },
                    selected: selected,
                  );
                })
              else
                TextField(
                  controller: controllerFor(q.id),
                  decoration: const InputDecoration(
                    labelText: 'Your answer',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => onAnswer(q.id, v),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WritingPane extends StatelessWidget {
  const _WritingPane({
    required this.section,
    required this.controller,
    required this.onChanged,
  });

  final IeltsSection section;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  int get _words {
    final t = controller.text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(section.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 8),
          Text(section.prompt.isNotEmpty ? section.prompt : section.instructions, style: TextStyle(height: 1.4, color: muted)),
          const SizedBox(height: 8),
          Text('Words: $_words${section.minWords > 0 ? ' / ${section.minWords} min' : ''}',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
              decoration: const InputDecoration(
                hintText: 'Write your response here…',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
