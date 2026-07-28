import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/ielts.dart';
import '../../../providers/ielts_provider.dart';

/// Staff editor for sections, passages, prompts, questions, and listening audio.
class IeltsExamEditorScreen extends ConsumerStatefulWidget {
  const IeltsExamEditorScreen({super.key, required this.subjectId, required this.examId});

  final String subjectId;
  final String examId;

  @override
  ConsumerState<IeltsExamEditorScreen> createState() => _IeltsExamEditorScreenState();
}

class _IeltsExamEditorScreenState extends ConsumerState<IeltsExamEditorScreen> {
  IeltsExam? _exam;
  String? _error;
  bool _loading = true;
  bool _busy = false;

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

  Future<void> _addSection() async {
    String skill = 'listening';
    final title = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
              onChanged: (v) => skill = v ?? 'listening',
              decoration: const InputDecoration(labelText: 'Skill'),
            ),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final fields = <String, dynamic>{
        'skill': skill,
        'title': title.text.trim().isEmpty ? skill : title.text.trim(),
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

  Future<void> _editSection(IeltsSection section) async {
    final title = TextEditingController(text: section.title);
    final instructions = TextEditingController(text: section.instructions);
    final passage = TextEditingController(text: section.passage);
    final prompt = TextEditingController(text: section.prompt);
    String? audioPath;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${section.skill} section'),
        content: SizedBox(
          width: 520,
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
                if (section.skill == 'reading') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: passage,
                    maxLines: 8,
                    decoration: const InputDecoration(labelText: 'Passage', border: OutlineInputBorder()),
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
                if (section.skill == 'listening') ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
                      if (result?.files.single.path != null) {
                        audioPath = result!.files.single.path;
                      }
                    },
                    icon: const Icon(Icons.audio_file),
                    label: Text(section.hasAudio ? 'Replace audio' : 'Upload audio'),
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
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(ieltsApiProvider).updateSection(
            section.id,
            {
              'title': title.text.trim(),
              'instructions': instructions.text,
              if (section.skill == 'reading') 'passage': passage.text,
              if (section.skill == 'writing') 'prompt': prompt.text,
            },
            audioPath: audioPath,
          );
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addQuestion(IeltsSection section) async {
    String type = section.skill == 'reading'
        ? 'tfng'
        : section.skill == 'writing'
            ? (section.writingTask == 'task1' ? 'task1' : 'task2')
            : 'mcq';
    final prompt = TextEditingController();
    final options = TextEditingController();
    final answers = TextEditingController();
    final number = TextEditingController(text: '${section.questions.length + 1}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add question'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: number, decoration: const InputDecoration(labelText: 'Number'), keyboardType: TextInputType.number),
                DropdownButtonFormField<String>(
                  value: type,
                  items: _typesFor(section.skill)
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => type = v ?? type,
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                TextField(
                  controller: prompt,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Prompt', border: OutlineInputBorder()),
                ),
                if (type == 'mcq' || type == 'tfng' || type == 'ynng')
                  TextField(
                    controller: options,
                    decoration: const InputDecoration(
                      labelText: 'Options (comma-separated)',
                      hintText: 'True, False, Not Given',
                    ),
                  ),
                if (type != 'task1' && type != 'task2')
                  TextField(
                    controller: answers,
                    decoration: const InputDecoration(
                      labelText: 'Correct answer(s)',
                      hintText: 'Accepted answers, comma-separated',
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final opts = options.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final ans = answers.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      await ref.read(ieltsApiProvider).createQuestion(section.id, {
        'type': type,
        'prompt': prompt.text.trim(),
        'number': int.tryParse(number.text) ?? section.questions.length + 1,
        'options': opts.isNotEmpty
            ? opts
            : (type == 'tfng'
                ? ['True', 'False', 'Not Given']
                : type == 'ynng'
                    ? ['Yes', 'No', 'Not Given']
                    : <String>[]),
        'answers': ans,
        'points': (type == 'task1' || type == 'task2') ? 0 : 1,
      });
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> _typesFor(String skill) {
    if (skill == 'listening') {
      return ['mcq', 'matching', 'form_completion', 'sentence_completion', 'short_answer'];
    }
    if (skill == 'reading') {
      return ['tfng', 'ynng', 'mcq', 'matching_headings', 'summary_completion', 'short_answer'];
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
    if (_loading) return const Scaffold(body: LoadingState(message: 'Loading exam...'));
    if (_error != null || _exam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit exam')),
        body: ErrorState(message: _error ?? 'Missing', onRetry: _load),
      );
    }
    final exam = _exam!;
    final muted = context.semantic.textMuted;

    return Scaffold(
      appBar: AppBar(
        title: Text(exam.title),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _addSection,
        icon: const Icon(Icons.add),
        label: const Text('Add section'),
      ),
      body: ListView(
        padding: AppSpacing.pagePaddingWide,
        children: [
          Text(
            '${exam.trainingType.toUpperCase()} · ${exam.mode} · ${exam.published ? 'Published' : 'Draft'}',
            style: TextStyle(color: muted),
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
                          '${section.title} (${section.skill})',
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
                      subtitle: Text(q.type),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _deleteQuestion(q),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _addQuestion(section),
                      icon: const Icon(Icons.add),
                      label: const Text('Add question'),
                    ),
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
