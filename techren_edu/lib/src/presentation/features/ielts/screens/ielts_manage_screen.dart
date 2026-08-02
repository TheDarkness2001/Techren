import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/ielts.dart';
import '../../../providers/ielts_provider.dart';
import '../../../shells/staff_shell.dart';
import '../ielts_nav.dart';
import '../ielts_ui.dart';

class IeltsManageScreen extends ConsumerStatefulWidget {
  const IeltsManageScreen({
    super.key,
    required this.subjectId,
    this.routePrefix = '/admin',
    this.navItems = const [],
    this.selectedRoute,
  });

  final String subjectId;
  final String routePrefix;
  final List<NavItem> navItems;
  final String? selectedRoute;

  @override
  ConsumerState<IeltsManageScreen> createState() => _IeltsManageScreenState();
}

class _IeltsManageScreenState extends ConsumerState<IeltsManageScreen> {
  bool _busy = false;

  String get _hub => '${widget.routePrefix}/learning/${widget.subjectId}/ielts';
  String get _learningSelected =>
      widget.selectedRoute ?? '${widget.routePrefix}/learning';

  Future<void> _create() async {
    final titleCtrl = TextEditingController(text: 'New IELTS Mock');
    String mode = 'full';
    String training = 'academic';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: IeltsUi.dialogInset,
        titlePadding: IeltsUi.titlePadding,
        contentPadding: IeltsUi.contentPadding,
        actionsPadding: IeltsUi.actionsPadding,
        title: const Text('Create exam'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: titleCtrl, decoration: IeltsUi.field('Title')),
            IeltsUi.fieldGap,
            DropdownButtonFormField<String>(
              value: mode,
              items: const [
                DropdownMenuItem(value: 'full', child: Text('Full mock (L→R→W→S)')),
                DropdownMenuItem(value: 'listening', child: Text('Listening only')),
                DropdownMenuItem(value: 'reading', child: Text('Reading only')),
                DropdownMenuItem(value: 'writing', child: Text('Writing only')),
                DropdownMenuItem(value: 'speaking', child: Text('Speaking only')),
              ],
              onChanged: (v) => mode = v ?? 'full',
              decoration: IeltsUi.field('Mode'),
            ),
            IeltsUi.fieldGap,
            DropdownButtonFormField<String>(
              value: training,
              items: const [
                DropdownMenuItem(value: 'academic', child: Text('Academic')),
                DropdownMenuItem(value: 'general', child: Text('General Training')),
              ],
              onChanged: (v) => training = v ?? 'academic',
              decoration: IeltsUi.field('Training type'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(ieltsApiProvider).createExam({
      'subjectId': widget.subjectId,
      'title': titleCtrl.text.trim(),
      'mode': mode,
      'trainingType': training,
      'published': false,
    });
    ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: null)));
  }

  Future<void> _importReadingJson() async {
    final jsonCtrl = TextEditingController();

    Future<void> pickFile(void Function(void Function()) setLocal) async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      String? text;
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        text = utf8.decode(file.bytes!);
      } else if (file.path != null && file.path!.isNotEmpty) {
        text = await File(file.path!).readAsString();
      }
      if (text == null || text.trim().isEmpty) return;
      setLocal(() => jsonCtrl.text = text!);
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          insetPadding: IeltsUi.dialogInset,
          titlePadding: IeltsUi.titlePadding,
          contentPadding: IeltsUi.contentPadding,
          actionsPadding: IeltsUi.actionsPadding,
          title: const Text('Import reading JSON'),
          content: ConstrainedBox(
            constraints: IeltsUi.dialogConstraints(ctx, maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Paste Academic Reading generator JSON (3 passages, 40 questions), or pick a .json file. '
                  'Creates an unpublished reading-only exam. See docs/IELTS-READING-GENERATOR.md.',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                IeltsUi.fieldGap,
                OutlinedButton.icon(
                  onPressed: () => pickFile(setLocal),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Pick .json file'),
                ),
                IeltsUi.fieldGap,
                SizedBox(
                  height: 320,
                  child: TextField(
                    controller: jsonCtrl,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '{ "title": "...", "module": "Academic", "passages": [...] }',
                    ),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final raw = jsonCtrl.text.trim();
    if (raw.isEmpty) return;

    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException('Root JSON must be an object');
      }
      body = Map<String, dynamic>.from(decoded);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid JSON: ${IeltsUi.errorMessage(e)}')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      body['subjectId'] = widget.subjectId;
      final exam = await ref.read(ieltsApiProvider).importExamJson(body, subjectId: widget.subjectId);
      ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: null)));
      ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: 'reading')));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported “${exam.title}” as draft')),
      );
      context.go('${widget.routePrefix}/learning/${widget.subjectId}/ielts/manage/${exam.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: ${IeltsUi.errorMessage(e)}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _togglePublish(IeltsExam exam) async {
    try {
      if (!exam.published) {
        final bundle = await ref.read(ieltsApiProvider).getExam(exam.id);
        final issues = IeltsUi.publishBlockingIssues(bundle);
        if (issues.isNotEmpty && mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Cannot publish yet'),
              content: Text(
                'Authentic IELTS structure required:\n\n• ${issues.join('\n• ')}\n\n'
                'Open the exam editor, add the missing passages/parts/questions, then publish.',
              ),
              actions: [
                FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
              ],
            ),
          );
          return;
        }
        if (exam.mode == 'full') {
          final skills = bundle.sections.map((s) => s.skill).toSet();
          final missing = kIeltsSkillOrder.where((s) => !skills.contains(s)).toList();
          if (missing.isNotEmpty && mounted) {
            final proceed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Full Mock incomplete'),
                content: Text(
                  'This Full Mock is missing: ${missing.join(', ')}. '
                  'Real IELTS order is Listening → Reading → Writing → Speaking. Publish anyway?',
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Publish')),
                ],
              ),
            );
            if (proceed != true) return;
          }
        }
      }
      await ref.read(ieltsApiProvider).updateExam(exam.id, {'published': !exam.published});
      ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: null)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(IeltsUi.errorMessage(e))),
      );
    }
  }

  Future<void> _toggleArchive(IeltsExam exam) async {
    await ref.read(ieltsApiProvider).updateExam(exam.id, {'archived': !exam.archived});
    ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: null)));
  }

  Future<void> _duplicate(IeltsExam exam) async {
    setState(() => _busy = true);
    try {
      await ref.read(ieltsApiProvider).duplicateExam(exam.id, overrides: {'title': '${exam.title} (copy)'});
      ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: null)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Duplicate failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(IeltsExam exam) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: IeltsUi.dialogInset,
        titlePadding: IeltsUi.titlePadding,
        actionsPadding: IeltsUi.actionsPadding,
        title: Text('Delete ${exam.title}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(ieltsApiProvider).deleteExam(exam.id);
    ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: null)));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ieltsExamsProvider((subjectId: widget.subjectId, mode: null)));
    final body = async.when(
      loading: () => const LoadingState(message: 'Loading...'),
      error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(ieltsExamsProvider)),
      data: (exams) {
        if (exams.isEmpty) {
          return EmptyState(
            title: 'No exams yet',
            message:
                'Create a mock here, then open it from IELTS Preparation (Listening / Reading / Writing / Speaking).',
            icon: Icons.quiz_outlined,
            action: FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('New exam'),
            ),
          );
        }
        return ListView.separated(
          padding: AppSpacing.pagePaddingWide,
          itemCount: exams.length,
          separatorBuilder: (_, __) => const SizedBox(height: IeltsUi.listGap),
          itemBuilder: (context, i) {
            final exam = exams[i];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.card,
                side: BorderSide(color: context.semantic.border),
              ),
              title: Row(
                children: [
                  Flexible(child: Text(exam.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                  if (exam.archived) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Archived', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
              subtitle: Text(
                '${exam.mode} · ${exam.trainingType} · ${exam.published ? 'Published' : 'Draft'}'
                '${exam.publishAt != null ? ' · publishes ${exam.publishAt!.toLocal().toString().split('.').first}' : ''}',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Edit content',
                    onPressed: () => context.go(
                      '${widget.routePrefix}/learning/${widget.subjectId}/ielts/manage/${exam.id}',
                    ),
                    icon: const Icon(Icons.edit_note),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: exam.published ? 'Unpublish' : 'Publish',
                    onPressed: () => _togglePublish(exam),
                    icon: Icon(exam.published ? Icons.visibility : Icons.visibility_off),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Duplicate',
                    onPressed: _busy ? null : () => _duplicate(exam),
                    icon: const Icon(Icons.copy_outlined),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: exam.archived ? 'Unarchive' : 'Archive',
                    onPressed: () => _toggleArchive(exam),
                    icon: Icon(exam.archived ? Icons.unarchive_outlined : Icons.archive_outlined),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete',
                    onPressed: () => _delete(exam),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final navItems = widget.navItems.isNotEmpty
        ? widget.navItems
        : (widget.routePrefix.startsWith('/founder') ? founderNavItems : adminNavItems);
    final selectedIndex = navItems.indexWhere(
      (i) => _learningSelected.startsWith(i.route) || i.route.contains('/learning'),
    );

    return AdaptiveScaffold(
      title: 'Manage IELTS exams',
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
          tooltip: 'Import reading JSON',
          onPressed: _busy ? null : _importReadingJson,
          icon: const Icon(Icons.upload_file_outlined),
        ),
        IconButton(
          tooltip: 'Back to IELTS Preparation',
          onPressed: () => context.go(_hub),
          icon: const Icon(Icons.arrow_back),
        ),
      ],
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'ielts-import-reading',
            onPressed: _busy ? null : _importReadingJson,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Import reading'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'ielts-new-exam',
            onPressed: _busy ? null : _create,
            icon: const Icon(Icons.add),
            label: const Text('New exam'),
          ),
        ],
      ),
      body: body,
    );
  }
}

class IeltsWritingReviewScreen extends ConsumerStatefulWidget {
  const IeltsWritingReviewScreen({
    super.key,
    required this.subjectId,
    this.routePrefix = '/admin',
  });

  final String subjectId;
  final String routePrefix;

  @override
  ConsumerState<IeltsWritingReviewScreen> createState() => _IeltsWritingReviewScreenState();
}

class _IeltsWritingReviewScreenState extends ConsumerState<IeltsWritingReviewScreen> {
  Future<void> _score(Map<String, dynamic> item) async {
    final attempt = IeltsAttempt.fromJson(item['attempt'] as Map<String, dynamic>);
    final detailed = (item['writingResponsesDetailed'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final hasDual = detailed.where((e) => (e['text'] as String? ?? '').trim().isNotEmpty).length >= 2 ||
        (detailed.any((e) => e['writingTask'] == 'task1') &&
            detailed.any((e) => e['writingTask'] == 'task2'));

    double ta = 6, cc = 6, lr = 6, gra = 6;
    double t1Ta = 6, t1Cc = 6, t1Lr = 6, t1Gra = 6;
    double t2Ta = 6, t2Cc = 6, t2Lr = 6, t2Gra = 6;
    final comments = TextEditingController();
    final corrections = TextEditingController();
    final existing = item['writingReview'];
    if (existing is Map<String, dynamic>) {
      final r = IeltsWritingReview.fromJson(existing);
      ta = r.taskAchievement;
      cc = r.coherenceCohesion;
      lr = r.lexicalResource;
      gra = r.grammaticalRange;
      if (r.task1 != null) {
        t1Ta = r.task1!.taskAchievement;
        t1Cc = r.task1!.coherenceCohesion;
        t1Lr = r.task1!.lexicalResource;
        t1Gra = r.task1!.grammaticalRange;
      }
      if (r.task2 != null) {
        t2Ta = r.task2!.taskAchievement;
        t2Cc = r.task2!.coherenceCohesion;
        t2Lr = r.task2!.lexicalResource;
        t2Gra = r.task2!.grammaticalRange;
      } else {
        t2Ta = ta;
        t2Cc = cc;
        t2Lr = lr;
        t2Gra = gra;
      }
      comments.text = r.comments;
      corrections.text = r.corrections;
    }

    final writingText = detailed.isNotEmpty
        ? detailed
            .map((e) {
              final label = e['title']?.toString() ?? e['writingTask']?.toString() ?? 'Writing';
              final text = (e['text'] as String? ?? '').trim();
              return '### $label\n${text.isEmpty ? '(empty)' : text}';
            })
            .join('\n\n')
        : attempt.writingResponses.values.join('\n\n---\n\n');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final overall = hasDual
                ? ((((t1Ta + t1Cc + t1Lr + t1Gra) / 4) + 2 * ((t2Ta + t2Cc + t2Lr + t2Gra) / 4)) / 3 * 2)
                        .round() /
                    2
                : ((ta + cc + lr + gra) / 4 * 2).round() / 2;
            return AlertDialog(
              insetPadding: IeltsUi.dialogInset,
              titlePadding: IeltsUi.titlePadding,
              contentPadding: IeltsUi.contentPadding,
              actionsPadding: IeltsUi.actionsPadding,
              title: const Text('Score writing'),
              content: ConstrainedBox(
                constraints: IeltsUi.dialogConstraints(ctx),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(writingText.isEmpty ? '(No writing text)' : writingText),
                      const SizedBox(height: AppSpacing.md),
                      if (hasDual) ...[
                        Text('Task 1 (×1)', style: Theme.of(ctx).textTheme.titleSmall),
                        _BandSlider('Task Achievement / Response', t1Ta, (v) => setLocal(() => t1Ta = v)),
                        _BandSlider('Coherence & Cohesion', t1Cc, (v) => setLocal(() => t1Cc = v)),
                        _BandSlider('Lexical Resource', t1Lr, (v) => setLocal(() => t1Lr = v)),
                        _BandSlider('Grammatical Range & Accuracy', t1Gra, (v) => setLocal(() => t1Gra = v)),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Task 2 (×2)', style: Theme.of(ctx).textTheme.titleSmall),
                        _BandSlider('Task Achievement / Response', t2Ta, (v) => setLocal(() => t2Ta = v)),
                        _BandSlider('Coherence & Cohesion', t2Cc, (v) => setLocal(() => t2Cc = v)),
                        _BandSlider('Lexical Resource', t2Lr, (v) => setLocal(() => t2Lr = v)),
                        _BandSlider('Grammatical Range & Accuracy', t2Gra, (v) => setLocal(() => t2Gra = v)),
                        Text('Overall (T1 + 2×T2) / 3: $overall'),
                      ] else ...[
                        _BandSlider('Task Achievement / Response', ta, (v) => setLocal(() => ta = v)),
                        _BandSlider('Coherence & Cohesion', cc, (v) => setLocal(() => cc = v)),
                        _BandSlider('Lexical Resource', lr, (v) => setLocal(() => lr = v)),
                        _BandSlider('Grammatical Range & Accuracy', gra, (v) => setLocal(() => gra = v)),
                        Text('Overall: $overall'),
                      ],
                      IeltsUi.fieldGap,
                      TextField(controller: comments, maxLines: 3, decoration: IeltsUi.field('Comments')),
                      IeltsUi.fieldGap,
                      TextField(controller: corrections, maxLines: 3, decoration: IeltsUi.field('Corrections')),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save score')),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return;
    if (hasDual) {
      await ref.read(ieltsApiProvider).submitWritingReview(
            attempt.id,
            task1: {
              'taskAchievement': t1Ta,
              'coherenceCohesion': t1Cc,
              'lexicalResource': t1Lr,
              'grammaticalRange': t1Gra,
            },
            task2: {
              'taskAchievement': t2Ta,
              'coherenceCohesion': t2Cc,
              'lexicalResource': t2Lr,
              'grammaticalRange': t2Gra,
            },
            comments: comments.text,
            corrections: corrections.text,
          );
    } else {
      await ref.read(ieltsApiProvider).submitWritingReview(
            attempt.id,
            taskAchievement: ta,
            coherenceCohesion: cc,
            lexicalResource: lr,
            grammaticalRange: gra,
            comments: comments.text,
            corrections: corrections.text,
          );
    }
    ref.invalidate(ieltsWritingQueueProvider(widget.subjectId));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ieltsWritingQueueProvider(widget.subjectId));
    final hub = ieltsHubRoute(widget.routePrefix, widget.subjectId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Writing review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(hub),
        ),
      ),
      body: async.when(
        loading: () => const LoadingState(message: 'Loading queue...'),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(ieltsWritingQueueProvider)),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(title: 'Queue empty', message: 'Submitted writing will appear here.');
          }
          return ListView.separated(
            padding: AppSpacing.pagePaddingWide,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: IeltsUi.listGap),
            itemBuilder: (context, i) {
              final item = items[i];
              final attempt = IeltsAttempt.fromJson(item['attempt'] as Map<String, dynamic>);
              final pending = item['pending'] == true;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.card,
                  side: BorderSide(color: context.semantic.border),
                ),
                title: Text('Attempt ${attempt.id.substring(0, 8)}…'),
                subtitle: Text(pending ? 'Pending review' : 'Scored · band ${attempt.scores.writingBand}'),
                trailing: FilledButton.tonal(
                  onPressed: () => _score(item),
                  child: Text(pending ? 'Score' : 'Edit'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class IeltsSpeakingReviewScreen extends ConsumerStatefulWidget {
  const IeltsSpeakingReviewScreen({
    super.key,
    required this.subjectId,
    this.routePrefix = '/admin',
  });

  final String subjectId;
  final String routePrefix;

  @override
  ConsumerState<IeltsSpeakingReviewScreen> createState() => _IeltsSpeakingReviewScreenState();
}

class _IeltsSpeakingReviewScreenState extends ConsumerState<IeltsSpeakingReviewScreen> {
  Future<void> _score(Map<String, dynamic> item) async {
    final attempt = IeltsAttempt.fromJson(item['attempt'] as Map<String, dynamic>);
    double fc = 6, lr = 6, gra = 6, pr = 6;
    final comments = TextEditingController();
    final existing = item['speakingReview'];
    if (existing is Map<String, dynamic>) {
      final r = IeltsSpeakingReview.fromJson(existing);
      fc = r.fluencyCoherence;
      lr = r.lexicalResource;
      gra = r.grammaticalRange;
      pr = r.pronunciation;
      comments.text = r.comments;
    }

    final sectionIds = attempt.speakingRecordings.entries
        .where((e) => e.value.hasRecording)
        .map((e) => e.key)
        .toList();
    final sectionId = sectionIds.isNotEmpty ? sectionIds.first : null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              insetPadding: IeltsUi.dialogInset,
              titlePadding: IeltsUi.titlePadding,
              contentPadding: IeltsUi.contentPadding,
              actionsPadding: IeltsUi.actionsPadding,
              title: const Text('Score speaking'),
              content: ConstrainedBox(
                constraints: IeltsUi.dialogConstraints(ctx),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (sectionId != null)
                        _SpeakingAudioPlayer(
                          attemptId: attempt.id,
                          sectionId: sectionId,
                        )
                      else
                        const Text('(No recording)'),
                      const SizedBox(height: AppSpacing.md),
                      _BandSlider('Fluency & Coherence', fc, (v) => setLocal(() => fc = v)),
                      _BandSlider('Lexical Resource', lr, (v) => setLocal(() => lr = v)),
                      _BandSlider('Grammatical Range & Accuracy', gra, (v) => setLocal(() => gra = v)),
                      _BandSlider('Pronunciation', pr, (v) => setLocal(() => pr = v)),
                      Text('Overall: ${((fc + lr + gra + pr) / 4 * 2).round() / 2}'),
                      IeltsUi.fieldGap,
                      TextField(controller: comments, maxLines: 3, decoration: IeltsUi.field('Comments')),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save score')),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return;
    await ref.read(ieltsApiProvider).submitSpeakingReview(
          attempt.id,
          fluencyCoherence: fc,
          lexicalResource: lr,
          grammaticalRange: gra,
          pronunciation: pr,
          comments: comments.text,
        );
    ref.invalidate(ieltsSpeakingQueueProvider(widget.subjectId));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ieltsSpeakingQueueProvider(widget.subjectId));
    final hub = ieltsHubRoute(widget.routePrefix, widget.subjectId);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speaking review'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(hub),
        ),
      ),
      body: async.when(
        loading: () => const LoadingState(message: 'Loading queue...'),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(ieltsSpeakingQueueProvider(widget.subjectId)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(title: 'Queue empty', message: 'Submitted speaking will appear here.');
          }
          return ListView.separated(
            padding: AppSpacing.pagePaddingWide,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: IeltsUi.listGap),
            itemBuilder: (context, i) {
              final item = items[i];
              final attempt = IeltsAttempt.fromJson(item['attempt'] as Map<String, dynamic>);
              final pending = item['pending'] == true;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.card,
                  side: BorderSide(color: context.semantic.border),
                ),
                title: Text('Attempt ${attempt.id.substring(0, 8)}…'),
                subtitle: Text(pending ? 'Pending review' : 'Scored · band ${attempt.scores.speakingBand}'),
                trailing: FilledButton.tonal(
                  onPressed: () => _score(item),
                  child: Text(pending ? 'Score' : 'Edit'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SpeakingAudioPlayer extends ConsumerStatefulWidget {
  const _SpeakingAudioPlayer({required this.attemptId, required this.sectionId});

  final String attemptId;
  final String sectionId;

  @override
  ConsumerState<_SpeakingAudioPlayer> createState() => _SpeakingAudioPlayerState();
}

class _SpeakingAudioPlayerState extends ConsumerState<_SpeakingAudioPlayer> {
  final _player = AudioPlayer();
  bool _loading = false;
  bool _playing = false;
  String? _error;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final path = await ref.read(ieltsApiProvider).downloadSpeakingAudio(widget.attemptId, widget.sectionId);
      await _player.setFilePath(path);
      setState(() => _playing = true);
      await _player.play();
      await _player.playerStateStream.firstWhere((s) => s.processingState == ProcessingState.completed);
      if (mounted) setState(() => _playing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _playing = false;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _loading ? null : _toggle,
          icon: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(_playing ? Icons.stop : Icons.play_arrow),
          label: Text(_playing ? 'Stop' : 'Play recording'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
      ],
    );
  }
}

class _BandSlider extends StatelessWidget {
  const _BandSlider(this.label, this.value, this.onChanged);
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toStringAsFixed(1)}'),
        Slider(
          value: value,
          min: 0,
          max: 9,
          divisions: 18,
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
