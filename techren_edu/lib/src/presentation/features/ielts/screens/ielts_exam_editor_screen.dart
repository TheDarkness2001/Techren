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
    String skill = 'listening';
    int? part = 1;
    final title = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Add section'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: skill,
                items: const [
                  DropdownMenuItem(value: 'listening', child: Text('Listening')),
                  DropdownMenuItem(value: 'reading', child: Text('Reading')),
                  DropdownMenuItem(value: 'writing', child: Text('Writing')),
                ],
                onChanged: (v) => setLocal(() => skill = v ?? 'listening'),
                decoration: const InputDecoration(labelText: 'Skill'),
              ),
              if (skill == 'listening') ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: part,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Part 1')),
                    DropdownMenuItem(value: 2, child: Text('Part 2')),
                    DropdownMenuItem(value: 3, child: Text('Part 3')),
                    DropdownMenuItem(value: 4, child: Text('Part 4')),
                  ],
                  onChanged: (v) => setLocal(() => part = v),
                  decoration: const InputDecoration(labelText: 'Listening part'),
                ),
              ],
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
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
      final fields = <String, dynamic>{
        'skill': skill,
        'title': title.text.trim().isEmpty
            ? (skill == 'listening' && part != null ? 'Part $part' : skill)
            : title.text.trim(),
        if (skill == 'listening' && part != null) 'part': part,
        if (skill == 'writing') 'writingTask': 'task2',
        if (skill == 'writing') 'minWords': '250',
        if (skill == 'writing')
          'prompt': 'Write an essay on the topic. Give reasons and examples.',
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
    final transcript = TextEditingController(text: section.transcript);
    final answerHighlights = TextEditingController(text: section.answerHighlights);
    int? part = section.part;
    String? audioPath;
    String passageFormat = section.passageFormat;
    String? sourceId = section.sourceId;
    List<IeltsSource> sources = const [];
    try {
      sources = await ref.read(ieltsApiProvider).listSources(subjectId: widget.subjectId);
    } catch (_) {}
    if (!mounted) return;

    Widget htmlToolbar(void Function(void Function()) setLocal) => Wrap(
          spacing: 6,
          runSpacing: 6,
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
          title: Text('Edit ${section.skill} section'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: instructions,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Instructions', border: OutlineInputBorder()),
                  ),
                  if (section.skill == 'listening' || section.skill == 'reading') ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: sources.any((s) => s.id == sourceId) ? sourceId : null,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('No source')),
                        for (final s in sources) DropdownMenuItem(value: s.id, child: Text(s.title, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => setLocal(() => sourceId = v),
                      decoration: const InputDecoration(labelText: 'Source (library)'),
                    ),
                  ],
                  if (section.skill == 'listening') ...[
                    const SizedBox(height: 8),
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
                      decoration: const InputDecoration(labelText: 'Listening part'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: transcript,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Transcript (staff / after submit)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Passage format:'),
                        const SizedBox(width: 12),
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
                    const SizedBox(height: 8),
                    if (passageFormat == 'html') ...[
                      htmlToolbar(setLocal),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: passage,
                      maxLines: 10,
                      decoration: InputDecoration(
                        labelText: passageFormat == 'html' ? 'Passage (HTML)' : 'Passage',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: answerHighlights,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Answer highlights (staff-only markers / notes)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (section.skill == 'writing') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: prompt,
                      maxLines: 6,
                      decoration: const InputDecoration(labelText: 'Prompt', border: OutlineInputBorder()),
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
              if (section.skill == 'listening') 'part': part,
              if (section.skill == 'listening') 'transcript': transcript.text,
              if (section.skill == 'reading') 'passage': passage.text,
              if (section.skill == 'reading') 'passageFormat': passageFormat,
              if (section.skill == 'reading') 'answerHighlights': answerHighlights.text,
              if (section.skill == 'writing') 'prompt': prompt.text,
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
            title: Text(existing == null ? 'Add question' : 'Edit question'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: number,
                      decoration: const InputDecoration(labelText: 'Number'),
                      keyboardType: TextInputType.number,
                    ),
                    DropdownButtonFormField<String>(
                      value: type,
                      items: _typesFor(section.skill)
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setLocal(() => type = v ?? type),
                      decoration: const InputDecoration(labelText: 'Type'),
                    ),
                    if (type == 'mcq')
                      DropdownButtonFormField<String>(
                        value: selectionMode,
                        items: const [
                          DropdownMenuItem(value: 'single', child: Text('Single answer')),
                          DropdownMenuItem(value: 'multiple', child: Text('Multiple answers')),
                        ],
                        onChanged: (v) => setLocal(() => selectionMode = v ?? 'single'),
                        decoration: const InputDecoration(labelText: 'Selection mode'),
                      ),
                    if (showMatching)
                      DropdownButtonFormField<String>(
                        value: matchingStyle,
                        items: const [
                          DropdownMenuItem(value: 'dropdown', child: Text('Dropdown')),
                          DropdownMenuItem(value: 'cards', child: Text('Card matching')),
                          DropdownMenuItem(value: 'drag_drop', child: Text('Drag & drop')),
                        ],
                        onChanged: (v) => setLocal(() => matchingStyle = v ?? 'dropdown'),
                        decoration: const InputDecoration(labelText: 'Matching style'),
                      ),
                    TextField(
                      controller: prompt,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Prompt / sentence (use ____ for blank)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    TextField(
                      controller: instruction,
                      decoration: const InputDecoration(
                        labelText: 'Instruction',
                        hintText: 'NO MORE THAN TWO WORDS AND/OR A NUMBER',
                      ),
                    ),
                    if (showAnswers)
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
                        decoration: const InputDecoration(labelText: 'Word limit'),
                      ),
                    if (showOptions)
                      TextField(
                        controller: options,
                        decoration: const InputDecoration(
                          labelText: 'Options (comma-separated)',
                          hintText: 'True, False, Not Given',
                        ),
                      ),
                    if (showMatching)
                      TextField(
                        controller: matchingChoices,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Choices / headings (one per line)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    if (showAnswers) ...[
                      TextField(
                        controller: answers,
                        decoration: const InputDecoration(
                          labelText: 'Correct / alternative answers (comma-separated)',
                        ),
                      ),
                      TextField(
                        controller: synonyms,
                        decoration: const InputDecoration(labelText: 'Synonyms (comma-separated)'),
                      ),
                      TextField(
                        controller: explanation,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Explanation (shown after submit)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Allow optional articles (a/an/the)'),
                        value: allowArticles,
                        onChanged: (v) => setLocal(() => allowArticles = v == true),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
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
        title: const Text('Save to question bank'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              TextField(controller: topic, decoration: const InputDecoration(labelText: 'Topic')),
              const SizedBox(height: 8),
              TextField(controller: difficulty, decoration: const InputDecoration(labelText: 'Difficulty')),
              const SizedBox(height: 8),
              TextField(controller: tags, decoration: const InputDecoration(labelText: 'Tags (comma-separated)')),
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
          title: const Text('Add from bank'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  decoration: const InputDecoration(labelText: 'Bank item'),
                ),
                const SizedBox(height: 8),
                if (versions.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedVersionId,
                    items: versions
                        .map((v) => DropdownMenuItem(value: v.id, child: Text('Version ${v.version}')))
                        .toList(),
                    onChanged: (v) => setLocal(() => selectedVersionId = v),
                    decoration: const InputDecoration(labelText: 'Version'),
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
        'short_answer',
        'map_labeling',
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
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          const SizedBox(height: AppSpacing.md),
          if (exam.sections.isEmpty)
            const EmptyState(title: 'No sections', message: 'Add Listening, Reading, or Writing sections.'),
          for (final section in exam.sections) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: AppRadius.card,
                border: Border.all(color: context.semantic.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        section.skill == 'listening'
                            ? Icons.headphones
                            : section.skill == 'reading'
                                ? Icons.menu_book
                                : Icons.edit_note,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${section.part != null ? 'Part ${section.part} · ' : ''}${section.title} (${section.skill})',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(onPressed: () => _editSection(section), icon: const Icon(Icons.edit_outlined)),
                      IconButton(onPressed: () => _deleteSection(section), icon: const Icon(Icons.delete_outline)),
                    ],
                  ),
                  if (section.hasAudio) Text('Audio uploaded', style: TextStyle(color: muted, fontSize: 12)),
                  if (section.passage.isNotEmpty)
                    Text(
                      section.passage.length > 120 ? '${section.passage.substring(0, 120)}…' : section.passage,
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  const SizedBox(height: 8),
                  for (final q in section.questions)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('Q${q.number}: ${q.prompt}', maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${q.type}${q.wordLimit != null ? ' · ${q.wordLimit}' : ''}${q.instruction.isNotEmpty ? ' · ${q.instruction}' : ''}',
                      ),
                      trailing: Wrap(
                        children: [
                          if (section.skill != 'writing')
                            IconButton(
                              tooltip: 'Save to bank',
                              icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                              onPressed: () => _saveQuestionToBank(q, section.skill),
                            ),
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _openQuestionEditor(section, existing: q),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () => _deleteQuestion(q),
                          ),
                        ],
                      ),
                    ),
                  Wrap(
                    spacing: 8,
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
                ],
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
