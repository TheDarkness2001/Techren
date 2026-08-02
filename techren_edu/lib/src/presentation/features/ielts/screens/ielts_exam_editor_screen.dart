import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/ielts.dart';
import '../../../providers/ielts_provider.dart';
import '../../../shells/staff_shell.dart';
import '../ielts_ui.dart';
import 'package:go_router/go_router.dart';

/// Staff editor for sections, passages, prompts, questions, and listening audio.
class IeltsExamEditorScreen extends ConsumerStatefulWidget {
  const IeltsExamEditorScreen({
    super.key,
    required this.subjectId,
    required this.examId,
    this.routePrefix = '/admin',
    this.navItems = const [],
    this.selectedRoute,
  });

  final String subjectId;
  final String examId;
  final String routePrefix;
  final List<NavItem> navItems;
  final String? selectedRoute;

  @override
  ConsumerState<IeltsExamEditorScreen> createState() => _IeltsExamEditorScreenState();
}

class _IeltsExamEditorScreenState extends ConsumerState<IeltsExamEditorScreen> {
  IeltsExam? _exam;
  String? _error;
  bool _loading = true;
  bool _busy = false;

  String get _manage => '${widget.routePrefix}/learning/${widget.subjectId}/ielts/manage';
  String get _learningSelected =>
      widget.selectedRoute ?? '${widget.routePrefix}/learning';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final exam = await ref.read(ieltsApiProvider).getExam(widget.examId);
      setState(() {
        _exam = exam;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleArchived() async {
    final exam = _exam;
    if (exam == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(ieltsApiProvider).updateExam(exam.id, {'archived': !exam.archived});
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPublishAt() async {
    final exam = _exam;
    if (exam == null) return;
    final now = DateTime.now();
    final initial = exam.publishAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (!mounted) return;
    final combined = DateTime(date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0);
    setState(() => _busy = true);
    try {
      await ref.read(ieltsApiProvider).updateExam(exam.id, {'publishAt': combined.toIso8601String()});
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearPublishAt() async {
    final exam = _exam;
    if (exam == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(ieltsApiProvider).updateExam(exam.id, {'publishAt': null});
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _duplicateExam() async {
    final exam = _exam;
    if (exam == null) return;
    setState(() => _busy = true);
    try {
      final copy = await ref.read(ieltsApiProvider).duplicateExam(exam.id, overrides: {'title': '${exam.title} (copy)'});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Duplicated as "${copy.title}"')));
      context.go('${widget.routePrefix}/learning/${widget.subjectId}/ielts/manage/${copy.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Duplicate failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportJson() async {
    final exam = _exam;
    if (exam == null) return;
    setState(() => _busy = true);
    try {
      final data = await ref.read(ieltsApiProvider).exportExamJson(exam.id);
      final pretty = const JsonEncoder.withIndent('  ').convert(data);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          insetPadding: IeltsUi.dialogInset,
          titlePadding: IeltsUi.titlePadding,
          contentPadding: IeltsUi.contentPadding,
          actionsPadding: IeltsUi.actionsPadding,
          title: const Text('Export JSON'),
          content: SizedBox(
            width: 560,
            height: 420,
            child: SingleChildScrollView(child: SelectableText(pretty, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: pretty));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Copy to clipboard'),
            ),
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addSection() async {
    final mode = _exam?.mode ?? 'full';
    final skillLocked = mode == 'listening' || mode == 'reading' || mode == 'writing' || mode == 'speaking';
    String skill = skillLocked ? mode : 'listening';
    int? part = 1;
    String writingTask = 'task1';
    final title = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          insetPadding: IeltsUi.dialogInset,
          titlePadding: IeltsUi.titlePadding,
          contentPadding: IeltsUi.contentPadding,
          actionsPadding: IeltsUi.actionsPadding,
          title: Text(skillLocked ? 'Add ${skill[0].toUpperCase()}${skill.substring(1)} section' : 'Add section'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!skillLocked)
                DropdownButtonFormField<String>(
                  value: skill,
                  items: const [
                    DropdownMenuItem(value: 'listening', child: Text('Listening')),
                    DropdownMenuItem(value: 'reading', child: Text('Reading')),
                    DropdownMenuItem(value: 'writing', child: Text('Writing')),
                    DropdownMenuItem(value: 'speaking', child: Text('Speaking')),
                  ],
                  onChanged: (v) => setLocal(() {
                    skill = v ?? 'listening';
                    if (skill == 'listening' || skill == 'reading') part = 1;
                  }),
                  decoration: IeltsUi.field('Skill'),
                ),
              if (skill == 'listening') ...[
                if (!skillLocked) IeltsUi.fieldGap,
                DropdownButtonFormField<int>(
                  value: part,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Part 1')),
                    DropdownMenuItem(value: 2, child: Text('Part 2')),
                    DropdownMenuItem(value: 3, child: Text('Part 3')),
                    DropdownMenuItem(value: 4, child: Text('Part 4')),
                  ],
                  onChanged: (v) => setLocal(() => part = v),
                  decoration: IeltsUi.field('Listening part'),
                ),
              ],
              if (skill == 'reading') ...[
                if (!skillLocked) IeltsUi.fieldGap,
                DropdownButtonFormField<int>(
                  value: part == null || part! > 3 ? 1 : part,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Passage 1')),
                    DropdownMenuItem(value: 2, child: Text('Passage 2')),
                    DropdownMenuItem(value: 3, child: Text('Passage 3')),
                  ],
                  onChanged: (v) => setLocal(() => part = v),
                  decoration: IeltsUi.field('Reading passage'),
                ),
              ],
              if (skill == 'writing') ...[
                if (!skillLocked) IeltsUi.fieldGap,
                DropdownButtonFormField<String>(
                  value: writingTask,
                  items: const [
                    DropdownMenuItem(value: 'task1', child: Text('Task 1')),
                    DropdownMenuItem(value: 'task2', child: Text('Task 2')),
                  ],
                  onChanged: (v) => setLocal(() => writingTask = v ?? 'task1'),
                  decoration: IeltsUi.field('Writing task'),
                ),
              ],
              IeltsUi.fieldGap,
              TextField(
                controller: title,
                decoration: IeltsUi.field('Title'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final defaultTitle = title.text.trim().isEmpty
          ? (skill == 'listening' && part != null
              ? 'Part $part'
              : skill == 'reading' && part != null
                  ? 'Passage $part'
                  : skill == 'writing'
                      ? (writingTask == 'task1' ? 'Task 1' : 'Task 2')
                      : skill == 'speaking'
                          ? 'Speaking cue card'
                          : skill)
          : title.text.trim();
      final fields = <String, dynamic>{
        'skill': skill,
        'title': defaultTitle,
        if ((skill == 'listening' || skill == 'reading') && part != null) 'part': part,
        if (skill == 'writing') 'writingTask': writingTask,
        if (skill == 'writing') 'minWords': writingTask == 'task1' ? '150' : '250',
        if (skill == 'writing') 'suggestedMinutes': writingTask == 'task1' ? 20 : 40,
        if (skill == 'writing')
          'prompt': writingTask == 'task1'
              ? 'Summarise the information by selecting and reporting the main features, and make comparisons where relevant.'
              : 'Write an essay on the topic. Give reasons and examples.',
        if (skill == 'speaking') 'speakingPart': 2,
        if (skill == 'speaking')
          'speakingPrompt':
              'Describe a place you like to visit. You should say:\n• where it is\n• how often you go there\n• what you do there\n• and explain why you like it.',
      };
      await ref.read(ieltsApiProvider).createSection(widget.examId, fields);
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Wraps the current selection (or inserts at cursor) in [open]/[close] tags.
  static void _wrapSelection(TextEditingController controller, String open, String close) {
    final sel = controller.selection;
    final text = controller.text;
    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    final selected = text.substring(start, end);
    final replacement = '$open$selected$close';
    final next = text.replaceRange(start, end, replacement);
    controller.value = controller.value.copyWith(
      text: next,
      selection: TextSelection.collapsed(offset: start + open.length + selected.length),
    );
  }

  Future<void> _editSection(IeltsSection section) async {
    final title = TextEditingController(text: section.title);
    final instructions = TextEditingController(text: section.instructions);
    final passage = TextEditingController(text: section.passage);
    final prompt = TextEditingController(text: section.prompt);
    final speakingPrompt = TextEditingController(text: section.speakingPrompt);
    final transcript = TextEditingController(text: section.transcript);
    final answerHighlights = TextEditingController(text: section.answerHighlights);
    final imageUrl = TextEditingController(text: section.imageUrl ?? '');
    final minWords = TextEditingController(text: section.minWords > 0 ? '${section.minWords}' : '');
    int? part = section.part;
    String writingTask = section.writingTask ?? 'task2';
    String? writingSubtype = section.writingSubtype;
    String? audioPath;
    String passageFormat = section.passageFormat;
    String? sourceId = section.sourceId;
    List<IeltsSource> sources = const [];
    try {
      sources = await ref.read(ieltsApiProvider).listSources(subjectId: widget.subjectId);
    } catch (_) {}
    if (!mounted) return;

    Widget htmlToolbar(void Function(void Function()) setLocal) => Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton(
              onPressed: () => setLocal(() => _wrapSelection(passage, '<b>', '</b>')),
              child: const Text('B', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            OutlinedButton(
              onPressed: () => setLocal(() => _wrapSelection(passage, '<i>', '</i>')),
              child: const Text('I', style: TextStyle(fontStyle: FontStyle.italic)),
            ),
            OutlinedButton(
              onPressed: () => setLocal(() => _wrapSelection(passage, '<ul>\n  <li>', '</li>\n</ul>')),
              child: const Text('UL'),
            ),
            OutlinedButton(
              onPressed: () => setLocal(() => _wrapSelection(passage, '<ol>\n  <li>', '</li>\n</ol>')),
              child: const Text('OL'),
            ),
            OutlinedButton(
              onPressed: () => setLocal(
                () => _wrapSelection(passage, '<table>\n  <tr><td>', '</td></tr>\n</table>'),
              ),
              child: const Text('Table'),
            ),
            OutlinedButton.icon(
              onPressed: () => setLocal(() => _wrapSelection(passage, '<p data-p="A">', '</p>')),
              icon: const Icon(Icons.label_outline, size: 16),
              label: const Text('Paragraph label'),
            ),
          ],
        );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          insetPadding: IeltsUi.dialogInset,
          titlePadding: IeltsUi.titlePadding,
          contentPadding: IeltsUi.contentPadding,
          actionsPadding: IeltsUi.actionsPadding,
          title: Text('Edit ${section.skill} section'),
          content: ConstrainedBox(
            constraints: IeltsUi.dialogConstraints(ctx, maxWidth: 560),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(controller: title, decoration: IeltsUi.field('Title')),
                  IeltsUi.fieldGap,
                  TextField(
                    controller: instructions,
                    maxLines: 2,
                    decoration: IeltsUi.field('Instructions'),
                  ),
                  if (section.skill == 'listening' || section.skill == 'reading') ...[
                    IeltsUi.fieldGap,
                    DropdownButtonFormField<String?>(
                      value: sources.any((s) => s.id == sourceId) ? sourceId : null,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No source')),
                        for (final s in sources) DropdownMenuItem(value: s.id, child: Text(s.title, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => setLocal(() => sourceId = v),
                      decoration: IeltsUi.field('Source (library)'),
                    ),
                  ],
                  if (section.skill == 'listening') ...[
                    IeltsUi.fieldGap,
                    DropdownButtonFormField<int?>(
                      value: part,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('No part')),
                        DropdownMenuItem(value: 1, child: Text('Part 1')),
                        DropdownMenuItem(value: 2, child: Text('Part 2')),
                        DropdownMenuItem(value: 3, child: Text('Part 3')),
                        DropdownMenuItem(value: 4, child: Text('Part 4')),
                      ],
                      onChanged: (v) => setLocal(() => part = v),
                      decoration: IeltsUi.field('Listening part'),
                    ),
                    IeltsUi.fieldGap,
                    TextField(
                      controller: transcript,
                      maxLines: 4,
                      decoration: IeltsUi.field('Transcript (staff / after submit)'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(type: FileType.audio);
                        if (result?.files.single.path != null) {
                          audioPath = result!.files.single.path;
                          setLocal(() {});
                        }
                      },
                      icon: const Icon(Icons.audio_file),
                      label: Text(
                        audioPath != null
                            ? 'Audio selected'
                            : (section.hasAudio ? 'Replace audio' : 'Upload audio'),
                      ),
                    ),
                  ],
                  if (section.skill == 'reading') ...[
                    IeltsUi.fieldGap,
                    DropdownButtonFormField<int?>(
                      value: part != null && part! >= 1 && part! <= 3 ? part : null,
                      items: const [
                        DropdownMenuItem(value: null, child: Text('No passage #')),
                        DropdownMenuItem(value: 1, child: Text('Passage 1')),
                        DropdownMenuItem(value: 2, child: Text('Passage 2')),
                        DropdownMenuItem(value: 3, child: Text('Passage 3')),
                      ],
                      onChanged: (v) => setLocal(() => part = v),
                      decoration: IeltsUi.field('Reading passage'),
                    ),
                    IeltsUi.fieldGap,
                    Row(
                      children: [
                        const Text('Passage format:'),
                        const SizedBox(width: AppSpacing.sm),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'plain', label: Text('Plain text')),
                            ButtonSegment(value: 'html', label: Text('HTML')),
                          ],
                          selected: {passageFormat},
                          onSelectionChanged: (s) => setLocal(() => passageFormat = s.first),
                        ),
                      ],
                    ),
                    IeltsUi.fieldGap,
                    if (passageFormat == 'html') ...[
                      htmlToolbar(setLocal),
                      IeltsUi.fieldGap,
                    ],
                    TextField(
                      controller: passage,
                      maxLines: 10,
                      decoration: IeltsUi.field(passageFormat == 'html' ? 'Passage (HTML)' : 'Passage'),
                    ),
                    IeltsUi.fieldGap,
                    TextField(
                      controller: answerHighlights,
                      maxLines: 3,
                      decoration: IeltsUi.field('Answer highlights (staff-only markers / notes)'),
                    ),
                  ],
                  if (section.skill == 'writing') ...[
                    IeltsUi.fieldGap,
                    DropdownButtonFormField<String>(
                      value: writingTask,
                      items: const [
                        DropdownMenuItem(value: 'task1', child: Text('Task 1')),
                        DropdownMenuItem(value: 'task2', child: Text('Task 2')),
                      ],
                      onChanged: (v) => setLocal(() {
                        writingTask = v ?? 'task2';
                        writingSubtype = null;
                        if (minWords.text.trim().isEmpty) {
                          minWords.text = writingTask == 'task1' ? '150' : '250';
                        }
                      }),
                      decoration: IeltsUi.field('Writing task'),
                    ),
                    IeltsUi.fieldGap,
                    Builder(builder: (context) {
                      const task1Subs = [
                        'chart', 'graph', 'table', 'diagram', 'map', 'process',
                        'letter_formal', 'letter_semi_formal', 'letter_informal',
                      ];
                      const task2Subs = [
                        'essay_opinion', 'essay_discussion', 'essay_problem_solution',
                        'essay_advantage_disadvantage', 'essay_two_part',
                      ];
                      final allowed = writingTask == 'task1' ? task1Subs : task2Subs;
                      final subtypeValue =
                          writingSubtype != null && allowed.contains(writingSubtype) ? writingSubtype : null;
                      return DropdownButtonFormField<String?>(
                        value: subtypeValue,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('No subtype')),
                          if (writingTask == 'task1') ...[
                            const DropdownMenuItem(value: 'chart', child: Text('Chart')),
                            const DropdownMenuItem(value: 'graph', child: Text('Graph')),
                            const DropdownMenuItem(value: 'table', child: Text('Table')),
                            const DropdownMenuItem(value: 'diagram', child: Text('Diagram')),
                            const DropdownMenuItem(value: 'map', child: Text('Map')),
                            const DropdownMenuItem(value: 'process', child: Text('Process')),
                            const DropdownMenuItem(value: 'letter_formal', child: Text('Letter (formal)')),
                            const DropdownMenuItem(value: 'letter_semi_formal', child: Text('Letter (semi-formal)')),
                            const DropdownMenuItem(value: 'letter_informal', child: Text('Letter (informal)')),
                          ] else ...[
                            const DropdownMenuItem(value: 'essay_opinion', child: Text('Opinion')),
                            const DropdownMenuItem(value: 'essay_discussion', child: Text('Discussion')),
                            const DropdownMenuItem(value: 'essay_problem_solution', child: Text('Problem / solution')),
                            const DropdownMenuItem(value: 'essay_advantage_disadvantage', child: Text('Advantages / disadvantages')),
                            const DropdownMenuItem(value: 'essay_two_part', child: Text('Two-part question')),
                          ],
                        ],
                        onChanged: (v) => setLocal(() => writingSubtype = v),
                        decoration: IeltsUi.field('Subtype'),
                      );
                    }),
                    IeltsUi.fieldGap,
                    TextField(
                      controller: prompt,
                      maxLines: 6,
                      decoration: IeltsUi.field('Prompt'),
                    ),
                    IeltsUi.fieldGap,
                    TextField(
                      controller: imageUrl,
                      decoration: IeltsUi.field('Task 1 image URL (chart / diagram)'),
                    ),
                    IeltsUi.fieldGap,
                    TextField(
                      controller: minWords,
                      keyboardType: TextInputType.number,
                      decoration: IeltsUi.field('Minimum words'),
                    ),
                  ],
                  if (section.skill == 'speaking') ...[
                    IeltsUi.fieldGap,
                    TextField(
                      controller: speakingPrompt,
                      maxLines: 8,
                      decoration: IeltsUi.field('Cue card / topic (Part 2)'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(ieltsApiProvider).updateSection(
            section.id,
            {
              'title': title.text.trim(),
              'instructions': instructions.text,
              if (section.skill == 'listening' || section.skill == 'reading') 'sourceId': sourceId ?? '',
              if (section.skill == 'listening' || section.skill == 'reading') 'part': part,
              if (section.skill == 'listening') 'transcript': transcript.text,
              if (section.skill == 'reading') 'passage': passage.text,
              if (section.skill == 'reading') 'passageFormat': passageFormat,
              if (section.skill == 'reading') 'answerHighlights': answerHighlights.text,
              if (section.skill == 'writing') 'prompt': prompt.text,
              if (section.skill == 'writing') 'writingTask': writingTask,
              if (section.skill == 'writing') 'writingSubtype': writingSubtype ?? '',
              if (section.skill == 'writing') 'imageUrl': imageUrl.text.trim(),
              if (section.skill == 'writing')
                'minWords': int.tryParse(minWords.text.trim()) ?? (writingTask == 'task1' ? 150 : 250),
              if (section.skill == 'writing') 'suggestedMinutes': writingTask == 'task1' ? 20 : 40,
              if (section.skill == 'speaking') 'speakingPrompt': speakingPrompt.text,
              if (section.skill == 'speaking') 'speakingPart': 2,
            },
            audioPath: audioPath,
          );
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openQuestionEditor(IeltsSection section, {IeltsQuestion? existing}) async {
    var type = existing?.type ??
        (section.skill == 'reading'
            ? 'tfng'
            : section.skill == 'writing'
                ? (section.writingTask == 'task1' ? 'task1' : 'task2')
                : 'mcq');
    final prompt = TextEditingController(text: existing?.prompt ?? '');
    final instruction = TextEditingController(text: existing?.instruction ?? '');
    final options = TextEditingController(text: (existing?.options ?? const []).join(', '));
    final answers = TextEditingController(
      text: existing == null
          ? ''
          : [
              if (existing.acceptedAnswers.primary.isNotEmpty) existing.acceptedAnswers.primary,
              ...existing.acceptedAnswers.alternatives,
              if (existing.acceptedAnswers.primary.isEmpty) ...existing.answers,
            ].join(', '),
    );
    final synonyms = TextEditingController(text: (existing?.acceptedAnswers.synonyms ?? const []).join(', '));
    final explanation = TextEditingController(text: existing?.acceptedAnswers.explanation ?? '');
    final matchingChoices = TextEditingController(text: (existing?.matchingChoices ?? const []).join('\n'));
    final number = TextEditingController(text: '${existing?.number ?? section.questions.length + 1}');
    String? wordLimit = existing?.wordLimit;
    var selectionMode = existing?.selectionMode ?? 'single';
    var matchingStyle = existing?.matchingStyle ?? 'dropdown';
    var allowArticles = existing?.allowArticles ?? false;
    var allowPlurals = existing?.allowPlurals ?? false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final showOptions = type == 'mcq' || type == 'tfng' || type == 'ynng';
          final showMatching = type == 'matching' || type == 'matching_headings';
          final showAnswers = type != 'task1' && type != 'task2';
          return AlertDialog(
            insetPadding: IeltsUi.dialogInset,
            titlePadding: IeltsUi.titlePadding,
            contentPadding: IeltsUi.contentPadding,
            actionsPadding: IeltsUi.actionsPadding,
            title: Text(existing == null ? 'Add question' : 'Edit question'),
            content: ConstrainedBox(
              constraints: IeltsUi.dialogConstraints(ctx),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: number,
                      decoration: IeltsUi.field('Number'),
                      keyboardType: TextInputType.number,
                    ),
                    IeltsUi.fieldGap,
                    DropdownButtonFormField<String>(
                      value: type,
                      items: _typesFor(section.skill)
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setLocal(() => type = v ?? type),
                      decoration: IeltsUi.field('Type'),
                    ),
                    if (type == 'mcq') ...[
                      IeltsUi.fieldGap,
                      DropdownButtonFormField<String>(
                        value: selectionMode,
                        items: const [
                          DropdownMenuItem(value: 'single', child: Text('Single answer')),
                          DropdownMenuItem(value: 'multiple', child: Text('Multiple answers')),
                        ],
                        onChanged: (v) => setLocal(() => selectionMode = v ?? 'single'),
                        decoration: IeltsUi.field('Selection mode'),
                      ),
                    ],
                    if (showMatching) ...[
                      IeltsUi.fieldGap,
                      DropdownButtonFormField<String>(
                        value: matchingStyle,
                        items: const [
                          DropdownMenuItem(value: 'dropdown', child: Text('Dropdown')),
                          DropdownMenuItem(value: 'cards', child: Text('Card matching')),
                          DropdownMenuItem(value: 'drag_drop', child: Text('Drag & drop')),
                        ],
                        onChanged: (v) => setLocal(() => matchingStyle = v ?? 'dropdown'),
                        decoration: IeltsUi.field('Matching style'),
                      ),
                    ],
                    IeltsUi.fieldGap,
                    TextField(
                      controller: prompt,
                      maxLines: 3,
                      decoration: IeltsUi.field(
                        'Prompt / sentence',
                        hint: 'Use ____ for a blank',
                        alignHint: true,
                      ),
                    ),
                    IeltsUi.fieldGap,
                    TextField(
                      controller: instruction,
                      decoration: IeltsUi.field(
                        'Instruction',
                        hint: 'NO MORE THAN TWO WORDS AND/OR A NUMBER',
                      ),
                    ),
                    if (showAnswers) ...[
                      IeltsUi.fieldGap,
                      DropdownButtonFormField<String?>(
                        value: wordLimit,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('No word limit')),
                          DropdownMenuItem(value: 'ONE_WORD', child: Text('ONE WORD')),
                          DropdownMenuItem(value: 'NO_MORE_THAN_TWO_WORDS', child: Text('NO MORE THAN TWO WORDS')),
                          DropdownMenuItem(value: 'NO_MORE_THAN_THREE_WORDS', child: Text('NO MORE THAN THREE WORDS')),
                          DropdownMenuItem(value: 'ONE_NUMBER', child: Text('ONE NUMBER')),
                          DropdownMenuItem(
                            value: 'ONE_WORD_AND_OR_A_NUMBER',
                            child: Text('ONE WORD AND/OR A NUMBER'),
                          ),
                          DropdownMenuItem(
                            value: 'NO_MORE_THAN_TWO_WORDS_AND_OR_A_NUMBER',
                            child: Text('NO MORE THAN TWO WORDS AND/OR A NUMBER'),
                          ),
                        ],
                        onChanged: (v) => setLocal(() => wordLimit = v),
                        decoration: IeltsUi.field('Word limit'),
                      ),
                    ],
                    if (showOptions) ...[
                      IeltsUi.fieldGap,
                      TextField(
                        controller: options,
                        decoration: IeltsUi.field(
                          'Options (comma-separated)',
                          hint: 'True, False, Not Given',
                        ),
                      ),
                    ],
                    if (showMatching) ...[
                      IeltsUi.fieldGap,
                      TextField(
                        controller: matchingChoices,
                        maxLines: 4,
                        decoration: IeltsUi.field(
                          'Choices / headings (one per line)',
                          alignHint: true,
                        ),
                      ),
                    ],
                    if (showAnswers) ...[
                      IeltsUi.fieldGap,
                      TextField(
                        controller: answers,
                        decoration: IeltsUi.field(
                          'Correct / alternative answers',
                          hint: 'Comma-separated',
                        ),
                      ),
                      IeltsUi.fieldGap,
                      TextField(
                        controller: synonyms,
                        decoration: IeltsUi.field('Synonyms (comma-separated)'),
                      ),
                      IeltsUi.fieldGap,
                      TextField(
                        controller: explanation,
                        maxLines: 2,
                        decoration: IeltsUi.field(
                          'Explanation',
                          hint: 'Shown after submit',
                          alignHint: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: const Text('Allow optional articles (a/an/the)'),
                        value: allowArticles,
                        onChanged: (v) => setLocal(() => allowArticles = v == true),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        title: const Text('Allow plural variants'),
                        value: allowPlurals,
                        onChanged: (v) => setLocal(() => allowPlurals = v == true),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(existing == null ? 'Add' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;

    final opts = options.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final ansList = answers.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final synList = synonyms.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final choiceLines =
        matchingChoices.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    final body = <String, dynamic>{
      'type': type,
      'prompt': prompt.text.trim(),
      'instruction': instruction.text.trim(),
      'number': int.tryParse(number.text) ?? (existing?.number ?? section.questions.length + 1),
      'selectionMode': selectionMode,
      'matchingStyle': matchingStyle,
      'wordLimit': wordLimit,
      'allowArticles': allowArticles,
      'allowPlurals': allowPlurals,
      'options': opts.isNotEmpty
          ? opts
          : (type == 'tfng'
              ? ['True', 'False', 'Not Given']
              : type == 'ynng'
                  ? ['Yes', 'No', 'Not Given']
                  : choiceLines),
      'answers': ansList,
      'acceptedAnswers': {
        'primary': ansList.isNotEmpty ? ansList.first : '',
        'alternatives': ansList.length > 1 ? ansList.sublist(1) : <String>[],
        'synonyms': synList,
        'rejected': <String>[],
        'explanation': explanation.text.trim(),
      },
      'metadata': {
        if (choiceLines.isNotEmpty) 'choices': choiceLines,
        if (choiceLines.isNotEmpty && type == 'matching_headings') 'headings': choiceLines,
        if (wordLimit != null) 'wordLimit': wordLimit,
      },
      'points': (type == 'task1' || type == 'task2') ? 0 : 1,
    };

    setState(() => _busy = true);
    try {
      if (existing == null) {
        await ref.read(ieltsApiProvider).createQuestion(section.id, body);
      } else {
        await ref.read(ieltsApiProvider).updateQuestion(existing.id, body);
      }
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addQuestion(IeltsSection section) => _openQuestionEditor(section);

  Future<void> _saveQuestionToBank(IeltsQuestion q, String skill) async {
    final title = TextEditingController(text: q.prompt.isEmpty ? 'Q${q.number}' : q.prompt);
    final topic = TextEditingController(text: 'General');
    final difficulty = TextEditingController(text: 'Medium');
    final tags = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: IeltsUi.dialogInset,
        titlePadding: IeltsUi.titlePadding,
        contentPadding: IeltsUi.contentPadding,
        actionsPadding: IeltsUi.actionsPadding,
        title: const Text('Save to question bank'),
        content: SizedBox(
          width: IeltsUi.dialogWidthNarrow,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: title, decoration: IeltsUi.field('Title')),
              IeltsUi.fieldGap,
              TextField(controller: topic, decoration: IeltsUi.field('Topic')),
              IeltsUi.fieldGap,
              TextField(controller: difficulty, decoration: IeltsUi.field('Difficulty')),
              IeltsUi.fieldGap,
              TextField(controller: tags, decoration: IeltsUi.field('Tags (comma-separated)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(ieltsApiProvider).importQuestionToBank(q.id, {
        'subjectId': widget.subjectId,
        'skill': skill,
        'title': title.text.trim(),
        'topic': topic.text.trim().isEmpty ? 'General' : topic.text.trim(),
        'difficulty': difficulty.text.trim().isEmpty ? 'Medium' : difficulty.text.trim(),
        'tags': tags.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to question bank')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addFromBank(IeltsSection section) async {
    List<IeltsBankItem> items = const [];
    try {
      items = await ref.read(ieltsApiProvider).listBank(subjectId: widget.subjectId, skill: section.skill);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load bank: $e')));
      return;
    }
    if (!mounted) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No matching bank items yet. Create some in Question Bank.')),
      );
      return;
    }

    IeltsBankItem? selectedItem;
    String? selectedVersionId;
    List<IeltsQuestionBankVersion> versions = const [];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          insetPadding: IeltsUi.dialogInset,
          titlePadding: IeltsUi.titlePadding,
          contentPadding: IeltsUi.contentPadding,
          actionsPadding: IeltsUi.actionsPadding,
          title: const Text('Add from bank'),
          content: SizedBox(
            width: IeltsUi.dialogWidthNarrow,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<IeltsBankItem>(
                  value: selectedItem,
                  isExpanded: true,
                  items: items
                      .map((it) => DropdownMenuItem(
                            value: it,
                            child: Text(
                              '${it.title.isEmpty ? it.type : it.title} (${it.type})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) async {
                    setLocal(() {
                      selectedItem = v;
                      selectedVersionId = null;
                      versions = const [];
                    });
                    if (v == null) return;
                    final full = await ref.read(ieltsApiProvider).getBankItem(v.id);
                    setLocal(() {
                      versions = full.versions;
                      selectedVersionId = versions.isNotEmpty ? versions.first.id : null;
                    });
                  },
                  decoration: IeltsUi.field('Bank item'),
                ),
                IeltsUi.fieldGap,
                if (versions.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedVersionId,
                    items: versions
                        .map((v) => DropdownMenuItem(value: v.id, child: Text('Version ${v.version}')))
                        .toList(),
                    onChanged: (v) => setLocal(() => selectedVersionId = v),
                    decoration: IeltsUi.field('Version'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: selectedVersionId == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Add to section'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || selectedVersionId == null) return;

    setState(() => _busy = true);
    try {
      await ref.read(ieltsApiProvider).addBankVersionToSection(section.id, selectedVersionId!);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> _typesFor(String skill) {
    if (skill == 'listening') {
      return [
        'mcq',
        'matching',
        'form_completion',
        'sentence_completion',
        'table_completion',
        'summary_completion',
        'short_answer',
        'map_labeling',
        'diagram_labeling',
      ];
    }
    if (skill == 'reading') {
      return [
        'tfng',
        'ynng',
        'mcq',
        'matching_headings',
        'summary_completion',
        'table_completion',
        'short_answer',
        'diagram_labeling',
      ];
    }
    return ['task1', 'task2'];
  }

  Future<void> _deleteQuestion(IeltsQuestion q) async {
    await ref.read(ieltsApiProvider).deleteQuestion(q.id);
    await _load();
  }

  Future<void> _deleteSection(IeltsSection s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: IeltsUi.dialogInset,
        titlePadding: IeltsUi.titlePadding,
        actionsPadding: IeltsUi.actionsPadding,
        title: Text('Delete ${s.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(ieltsApiProvider).deleteSection(s.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final navItems = widget.navItems.isNotEmpty
        ? widget.navItems
        : (widget.routePrefix.startsWith('/founder') ? founderNavItems : adminNavItems);
    final selectedIndex = navItems.indexWhere(
      (i) => _learningSelected.startsWith(i.route) || i.route.contains('/learning'),
    );

    Widget shell({required String title, required Widget body, Widget? fab}) {
      return AdaptiveScaffold(
        title: title,
        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
        selectedRoute: _learningSelected,
        items: navItems,
        onDestinationSelected: (i) => context.go(navItems[i].route),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(
            tooltip: 'Back to manage',
            onPressed: () => context.go(_manage),
            icon: const Icon(Icons.arrow_back),
          ),
        ],
        floatingActionButton: fab,
        body: body,
      );
    }

    if (_loading) {
      return shell(title: 'Edit exam', body: const LoadingState(message: 'Loading exam...'));
    }
    if (_error != null || _exam == null) {
      return shell(
        title: 'Edit exam',
        body: ErrorState(message: _error ?? 'Missing', onRetry: _load),
      );
    }
    final exam = _exam!;
    final muted = context.semantic.textMuted;

    return shell(
      title: exam.title,
      fab: FloatingActionButton.extended(
        onPressed: _busy ? null : _addSection,
        icon: const Icon(Icons.add),
        label: const Text('Add section'),
      ),
      body: ListView(
        padding: AppSpacing.pagePaddingWide,
        children: [
          Text(
            '${exam.trainingType.toUpperCase()} · ${exam.mode} · ${exam.published ? 'Published' : 'Draft'}'
            '${exam.archived ? ' · Archived' : ''}'
            '${exam.publishAt != null ? ' · publishes ${exam.publishAt!.toLocal().toString().split('.').first}' : ''}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : _duplicateExam,
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Duplicate exam'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _exportJson,
                icon: const Icon(Icons.download_outlined, size: 18),
                label: const Text('Export JSON'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pickPublishAt,
                icon: const Icon(Icons.schedule_outlined, size: 18),
                label: Text(exam.publishAt != null ? 'Change publish date' : 'Schedule publish'),
              ),
              if (exam.publishAt != null)
                TextButton(
                  onPressed: _busy ? null : _clearPublishAt,
                  child: const Text('Clear schedule'),
                ),
              FilterChip(
                label: Text(exam.archived ? 'Archived' : 'Archive'),
                selected: exam.archived,
                avatar: Icon(exam.archived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 16),
                onSelected: _busy ? null : (_) => _toggleArchived(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          if (exam.sections.isEmpty)
            EmptyState(
              title: 'No sections',
              message: switch (exam.mode) {
                'reading' => 'Add Passage 1–3 for this Reading exam.',
                'listening' => 'Add Parts 1–4 for this Listening exam.',
                'writing' => 'Add Task 1 and Task 2 for this Writing exam.',
                'speaking' => 'Add a Speaking cue-card section.',
                _ => 'Add Listening, Reading, Writing, or Speaking sections.',
              },
            ),
          for (final section in exam.sections) ...[
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                borderRadius: AppRadius.card,
                border: Border.all(color: context.semantic.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          section.skill == 'listening'
                              ? Icons.headphones
                              : section.skill == 'reading'
                                  ? Icons.menu_book
                                  : section.skill == 'speaking'
                                      ? Icons.record_voice_over_outlined
                                      : Icons.edit_note,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${section.part != null ? 'Part ${section.part} · ' : ''}${section.title} (${section.skill})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Edit section',
                        onPressed: () => _editSection(section),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Delete section',
                        onPressed: () => _deleteSection(section),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  if (section.hasAudio) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text('Audio uploaded', style: TextStyle(color: muted, fontSize: 12)),
                  ],
                  if (section.passage.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      section.passage.length > 160 ? '${section.passage.substring(0, 160)}…' : section.passage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted, height: 1.4),
                    ),
                  ],
                  if (section.skill == 'speaking' && section.speakingPrompt.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      section.speakingPrompt.length > 200
                          ? '${section.speakingPrompt.substring(0, 200)}…'
                          : section.speakingPrompt,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted, height: 1.4),
                    ),
                  ],
                  if (section.skill != 'speaking' && section.questions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    for (final q in section.questions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Q${q.number}: ${q.prompt}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${q.type}${q.wordLimit != null ? ' · ${q.wordLimit}' : ''}${q.instruction.isNotEmpty ? ' · ${q.instruction}' : ''}',
                          ),
                          trailing: Wrap(
                            spacing: AppSpacing.xxs,
                            children: [
                              if (section.skill != 'writing')
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Save to bank',
                                  icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                                  onPressed: () => _saveQuestionToBank(q, section.skill),
                                ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Edit',
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _openQuestionEditor(section, existing: q),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _deleteQuestion(q),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  if (section.skill != 'speaking') ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        TextButton.icon(
                          onPressed: () => _addQuestion(section),
                          icon: const Icon(Icons.add),
                          label: const Text('Add question'),
                        ),
                        if (section.skill != 'writing')
                          TextButton.icon(
                            onPressed: () => _addFromBank(section),
                            icon: const Icon(Icons.storage_outlined),
                            label: const Text('Add from bank'),
                          ),
                      ],
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'Students record one speaking response for this cue card. Teachers mark it in Speaking Review.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}
