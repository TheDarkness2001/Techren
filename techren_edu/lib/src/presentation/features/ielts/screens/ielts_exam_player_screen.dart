import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/ielts.dart';
import '../../../providers/ielts_provider.dart';
import '../ielts_nav.dart';
import '../widgets/ielts_audio_once_player.dart';
import '../widgets/questions/ielts_question_widgets.dart';

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
  final Map<String, TextEditingController> _writingControllers = {};
  final Map<String, bool> _audioPlayedBySection = {};
  final Map<String, int> _timePerQuestion = {};
  final Map<String, Map<String, dynamic>> _audioAnalytics = {};

  int _sectionIndex = 0;
  int _questionIndex = 0;
  int _remainingSeconds = 0;
  Timer? _tick;
  Timer? _autosave;

  // Reading pane customization (not persisted server-side).
  double _splitRatio = 0.5;
  double _fontSize = 15;
  double _lineSpacing = 1.5;

  String? _activeQuestionId;
  DateTime? _questionStartedAt;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _recordTimeSpent();
    _tick?.cancel();
    _autosave?.cancel();
    for (final c in _writingControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Adds elapsed seconds since the active question became visible to
  /// [_timePerQuestion], then clears the tracker (call before switching).
  void _recordTimeSpent() {
    final qid = _activeQuestionId;
    final startedAt = _questionStartedAt;
    if (qid != null && startedAt != null) {
      final elapsed = DateTime.now().difference(startedAt).inSeconds;
      if (elapsed > 0) {
        _timePerQuestion[qid] = (_timePerQuestion[qid] ?? 0) + elapsed;
      }
    }
    _questionStartedAt = null;
  }

  void _markQuestionActive(String? qid) {
    _recordTimeSpent();
    _activeQuestionId = qid;
    _questionStartedAt = qid == null ? null : DateTime.now();
  }

  void _onAudioAnalytics(String sectionId, Map<String, dynamic> stats) {
    _audioAnalytics[sectionId] = stats;
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
      _audioPlayedBySection.addAll(bundle.attempt.audioPlayedBySection);
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
      _remainingSeconds =
          bundle.attempt.remainingSeconds ?? bundle.exam.timers.totalSecondsForMode(bundle.exam.mode);
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

  Future<void> _save({String? playedSectionId}) async {
    final bundle = _bundle;
    if (bundle == null || _submitting) return;
    final writing = <String, String>{};
    for (final e in _writingControllers.entries) {
      writing[e.key] = e.value.text;
    }
    _recordTimeSpent();
    if (_activeQuestionId != null) _questionStartedAt = DateTime.now();
    final sectionId = bundle.exam.sections.isNotEmpty ? bundle.exam.sections[_sectionIndex].id : null;
    try {
      await ref.read(ieltsApiProvider).autosave(
            bundle.attempt.id,
            answers: Map<String, dynamic>.from(_answers),
            flags: Map<String, bool>.from(_flags),
            writingResponses: writing,
            currentSectionId: sectionId,
            remainingSeconds: _remainingSeconds,
            audioPlayed: _audioPlayedBySection.values.any((v) => v),
            playedSectionId: playedSectionId,
            audioPlayedBySection: Map<String, bool>.from(_audioPlayedBySection),
            timePerQuestion: _timePerQuestion.isEmpty ? null : Map<String, int>.from(_timePerQuestion),
            audioAnalytics: _audioAnalytics.isEmpty ? null : Map<String, dynamic>.from(_audioAnalytics),
          );
    } catch (_) {}
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
      context.go('${ieltsHubRoute(widget.routePrefix, widget.subjectId)}/results/${result.attempt.id}');
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

  TextEditingController _writingController(String sectionId) {
    return _writingControllers.putIfAbsent(sectionId, () => TextEditingController());
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool _isAnswered(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.values.any((v) => v != null && v.toString().trim().isNotEmpty);
    return value.toString().trim().isNotEmpty;
  }

  String get _hub => ieltsHubRoute(widget.routePrefix, widget.subjectId);

  Future<void> _goBack() async {
    if (_bundle == null || _bundle!.attempt.isInProgress != true) {
      if (mounted) context.go(_hub);
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave exam?'),
        content: const Text(
          'Your answers are autosaved. You can resume this attempt later from the exam list.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Leave')),
        ],
      ),
    );
    if (leave == true && mounted) {
      await _save();
      if (mounted) context.go(_hub);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('IELTS Exam'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(_hub),
          ),
        ),
        body: const LoadingState(message: 'Starting exam...'),
      );
    }
    if (_error != null || _bundle == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('IELTS Exam'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(_hub),
          ),
        ),
        body: ErrorState(message: _error ?? 'Unable to start', onRetry: _bootstrap),
      );
    }

    final exam = _bundle!.exam;
    final section = _section;
    final questions = section?.questions.where((q) => !q.isWriting).toList() ?? const <IeltsQuestion>[];
    final isWriting = section?.skill == 'writing';
    final muted = context.semantic.textMuted;

    final currentQid =
        (!isWriting && questions.isNotEmpty) ? questions[_questionIndex.clamp(0, questions.length - 1)].id : null;
    if (currentQid != _activeQuestionId) {
      _markQuestionActive(currentQid);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _goBack();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(exam.title),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
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
            child: _submitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Submit'),
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
              isAnswered: (qid) => _isAnswered(_answers[qid]),
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
                        questions: questions,
                        questionIndex: _questionIndex,
                        answers: _answers,
                        flags: _flags,
                        audioPlayed: _audioPlayedBySection[section.id] == true,
                        splitRatio: _splitRatio,
                        onSplitChanged: (v) => setState(() => _splitRatio = v),
                        fontSize: _fontSize,
                        onFontSizeChanged: (v) => setState(() => _fontSize = v),
                        lineSpacing: _lineSpacing,
                        onLineSpacingChanged: (v) => setState(() => _lineSpacing = v),
                        onAnswer: (qid, value) {
                          setState(() => _answers[qid] = value);
                        },
                        onToggleFlag: (qid) {
                          setState(() => _flags[qid] = !(_flags[qid] == true));
                        },
                        onAudioPlayed: () {
                          setState(() => _audioPlayedBySection[section.id] = true);
                          _save(playedSectionId: section.id);
                        },
                        onAudioAnalytics: (stats) => _onAudioAnalytics(section.id, stats),
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
                      child: Text(
                        _questionIndex < questions.length - 1
                            ? 'Next'
                            : (_sectionIndex < exam.sections.length - 1 ? 'Next section' : 'Submit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
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
                label: Text(
                  sections[i].part != null
                      ? 'Part ${sections[i].part}'
                      : (sections[i].title.isNotEmpty ? sections[i].title : sections[i].skill),
                ),
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
    required this.isAnswered,
    required this.onSelect,
  });

  final List<IeltsQuestion> questions;
  final int current;
  final Map<String, bool> flags;
  final bool Function(String qid) isAnswered;
  final ValueChanged<int> onSelect;

  Future<void> _openJumpTo(BuildContext context) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Jump to question', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < questions.length; i++)
                    _JumpChip(
                      label: '${questions[i].number}',
                      selected: i == current,
                      answered: isAnswered(questions[i].id),
                      flagged: flags[questions[i].id] == true,
                      onTap: () => Navigator.pop(ctx, i),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) onSelect(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Sticky nav bar: sits outside the scrollable pane content so it stays
      // visible while the student scrolls the passage/question area.
      height: 48,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Jump to question',
            onPressed: () => _openJumpTo(context),
            icon: const Icon(Icons.dashboard_customize_outlined, size: 20),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: questions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final q = questions[i];
                final answered = isAnswered(q.id);
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
          ),
        ],
      ),
    );
  }
}

class _JumpChip extends StatelessWidget {
  const _JumpChip({
    required this.label,
    required this.selected,
    required this.answered,
    required this.flagged,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool answered;
  final bool flagged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : answered
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: flagged ? Border.all(color: Colors.orange, width: 2) : null,
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w700, color: selected ? Colors.white : null),
        ),
      ),
    );
  }
}

class _ObjectivePane extends StatelessWidget {
  const _ObjectivePane({
    required this.section,
    required this.questions,
    required this.questionIndex,
    required this.answers,
    required this.flags,
    required this.audioPlayed,
    required this.onAnswer,
    required this.onToggleFlag,
    required this.onAudioPlayed,
    this.splitRatio = 0.5,
    this.onSplitChanged,
    this.fontSize = 15,
    this.onFontSizeChanged,
    this.lineSpacing = 1.5,
    this.onLineSpacingChanged,
    this.onAudioAnalytics,
  });

  final IeltsSection section;
  final List<IeltsQuestion> questions;
  final int questionIndex;
  final Map<String, dynamic> answers;
  final Map<String, bool> flags;
  final bool audioPlayed;
  final void Function(String qid, dynamic value) onAnswer;
  final ValueChanged<String> onToggleFlag;
  final VoidCallback onAudioPlayed;
  final double splitRatio;
  final ValueChanged<double>? onSplitChanged;
  final double fontSize;
  final ValueChanged<double>? onFontSizeChanged;
  final double lineSpacing;
  final ValueChanged<double>? onLineSpacingChanged;
  final ValueChanged<Map<String, dynamic>>? onAudioAnalytics;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Center(child: Text('No questions in this section'));
    }
    final q = questions[questionIndex.clamp(0, questions.length - 1)];
    final muted = context.semantic.textMuted;
    final partLabel = section.part != null
        ? 'Listening Part ${section.part}${section.title.isNotEmpty ? ' — ${section.title}' : ''}'
        : (section.title.isNotEmpty ? section.title : null);
    final hasPassage = section.skill == 'reading' && section.passage.isNotEmpty;

    final questionColumn = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (section.skill == 'listening') ...[
          if (section.instructions.isNotEmpty) Text(section.instructions, style: TextStyle(color: muted)),
          const SizedBox(height: 8),
          if (section.hasAudio)
            IeltsAudioOncePlayer(
              sectionId: section.id,
              alreadyPlayed: audioPlayed,
              partLabel: partLabel,
              onPlayed: onAudioPlayed,
              onAnalytics: onAudioAnalytics,
            )
          else
            Text('No audio uploaded for this section.', style: TextStyle(color: muted)),
          const SizedBox(height: AppSpacing.md),
        ],
        IeltsQuestionView(
          question: q,
          value: answers[q.id],
          flagged: flags[q.id] == true,
          onChanged: (v) => onAnswer(q.id, v),
          onToggleFlag: () => onToggleFlag(q.id),
        ),
      ],
    );

    if (!hasPassage) {
      return questionColumn;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const dividerWidth = 10.0;
        final available = constraints.maxWidth - dividerWidth;
        final leftWidth = (available * splitRatio).clamp(160.0, available - 160.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: leftWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PassageToolbar(
                    fontSize: fontSize,
                    lineSpacing: lineSpacing,
                    onFontSizeChanged: onFontSizeChanged,
                    onLineSpacingChanged: onLineSpacingChanged,
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.card,
                        border: Border.all(color: context.semantic.border),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: SingleChildScrollView(
                        child: section.isHtmlPassage
                            ? Html(
                                data: section.passage,
                                style: {
                                  'body': Style(
                                    fontSize: FontSize(fontSize),
                                    lineHeight: LineHeight(lineSpacing),
                                    margin: Margins.zero,
                                  ),
                                },
                              )
                            : SelectableText(
                                section.passage,
                                style: TextStyle(height: lineSpacing, fontSize: fontSize),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                final handler = onSplitChanged;
                if (handler == null) return;
                final next = ((leftWidth + details.delta.dx) / available).clamp(0.2, 0.8);
                handler(next);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: SizedBox(
                  width: dividerWidth,
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.semantic.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: questionColumn),
          ],
        );
      },
    );
  }
}

class _PassageToolbar extends StatelessWidget {
  const _PassageToolbar({
    required this.fontSize,
    required this.lineSpacing,
    required this.onFontSizeChanged,
    required this.onLineSpacingChanged,
  });

  final double fontSize;
  final double lineSpacing;
  final ValueChanged<double>? onFontSizeChanged;
  final ValueChanged<double>? onLineSpacingChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Text', style: TextStyle(color: context.semantic.textMuted, fontSize: 12)),
          IconButton(
            tooltip: 'Smaller text',
            visualDensity: VisualDensity.compact,
            onPressed: onFontSizeChanged == null ? null : () => onFontSizeChanged!((fontSize - 1).clamp(11, 24)),
            icon: const Icon(Icons.text_decrease, size: 18),
          ),
          IconButton(
            tooltip: 'Larger text',
            visualDensity: VisualDensity.compact,
            onPressed: onFontSizeChanged == null ? null : () => onFontSizeChanged!((fontSize + 1).clamp(11, 24)),
            icon: const Icon(Icons.text_increase, size: 18),
          ),
          const SizedBox(width: 8),
          Text('Spacing', style: TextStyle(color: context.semantic.textMuted, fontSize: 12)),
          IconButton(
            tooltip: 'Tighter lines',
            visualDensity: VisualDensity.compact,
            onPressed: onLineSpacingChanged == null
                ? null
                : () => onLineSpacingChanged!((lineSpacing - 0.15).clamp(1.0, 2.2)),
            icon: const Icon(Icons.format_line_spacing, size: 18),
          ),
          IconButton(
            tooltip: 'Wider lines',
            visualDensity: VisualDensity.compact,
            onPressed: onLineSpacingChanged == null
                ? null
                : () => onLineSpacingChanged!((lineSpacing + 0.15).clamp(1.0, 2.2)),
            icon: const Icon(Icons.format_line_spacing_outlined, size: 18),
          ),
        ],
      ),
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
          Text(
            section.prompt.isNotEmpty ? section.prompt : section.instructions,
            style: TextStyle(height: 1.4, color: muted),
          ),
          const SizedBox(height: 8),
          Text(
            'Words: $_words${section.minWords > 0 ? ' / ${section.minWords} min' : ''}',
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
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
