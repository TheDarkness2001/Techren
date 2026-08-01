import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../domain/entities/ielts.dart';
import '../../../providers/ielts_provider.dart';
import '../../../shells/staff_shell.dart';

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
        title: const Text('Create exam'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: mode,
              items: const [
                DropdownMenuItem(value: 'full', child: Text('Full mock')),
                DropdownMenuItem(value: 'listening', child: Text('Listening only')),
                DropdownMenuItem(value: 'reading', child: Text('Reading only')),
                DropdownMenuItem(value: 'writing', child: Text('Writing only')),
              ],
              onChanged: (v) => mode = v ?? 'full',
              decoration: const InputDecoration(labelText: 'Mode'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: training,
              items: const [
                DropdownMenuItem(value: 'academic', child: Text('Academic')),
                DropdownMenuItem(value: 'general', child: Text('General Training')),
              ],
              onChanged: (v) => training = v ?? 'academic',
              decoration: const InputDecoration(labelText: 'Training type'),
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

  Future<void> _togglePublish(IeltsExam exam) async {
    await ref.read(ieltsApiProvider).updateExam(exam.id, {'published': !exam.published});
    ref.invalidate(ieltsExamsProvider((subjectId: widget.subjectId, mode: null)));
  }

  Future<void> _delete(IeltsExam exam) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
                'Create a mock here, then open it from IELTS Preparation (Listening / Reading / Writing).',
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
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final exam = exams[i];
            return ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.card,
                side: BorderSide(color: context.semantic.border),
              ),
              title: Text(exam.title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${exam.mode} · ${exam.trainingType} · ${exam.published ? 'Published' : 'Draft'}'),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: 'Edit content',
                    onPressed: () => context.go(
                      '${widget.routePrefix}/learning/${widget.subjectId}/ielts/manage/${exam.id}',
                    ),
                    icon: const Icon(Icons.edit_note),
                  ),
                  IconButton(
                    tooltip: exam.published ? 'Unpublish' : 'Publish',
                    onPressed: () => _togglePublish(exam),
                    icon: Icon(exam.published ? Icons.visibility : Icons.visibility_off),
                  ),
                  IconButton(
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
        IconButton(
          tooltip: 'Back to IELTS Preparation',
          onPressed: () => context.go(_hub),
          icon: const Icon(Icons.arrow_back),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('New exam'),
      ),
      body: body,
    );
  }
}

class IeltsWritingReviewScreen extends ConsumerStatefulWidget {
  const IeltsWritingReviewScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  ConsumerState<IeltsWritingReviewScreen> createState() => _IeltsWritingReviewScreenState();
}

class _IeltsWritingReviewScreenState extends ConsumerState<IeltsWritingReviewScreen> {
  Future<void> _score(Map<String, dynamic> item) async {
    final attempt = IeltsAttempt.fromJson(item['attempt'] as Map<String, dynamic>);
    double ta = 6, cc = 6, lr = 6, gra = 6;
    final comments = TextEditingController();
    final corrections = TextEditingController();
    final existing = item['writingReview'];
    if (existing is Map<String, dynamic>) {
      final r = IeltsWritingReview.fromJson(existing);
      ta = r.taskAchievement;
      cc = r.coherenceCohesion;
      lr = r.lexicalResource;
      gra = r.grammaticalRange;
      comments.text = r.comments;
      corrections.text = r.corrections;
    }

    final writingText = attempt.writingResponses.values.join('\n\n---\n\n');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Score writing'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(writingText.isEmpty ? '(No writing text)' : writingText),
                      const SizedBox(height: 16),
                      _BandSlider('Task Achievement / Response', ta, (v) => setLocal(() => ta = v)),
                      _BandSlider('Coherence & Cohesion', cc, (v) => setLocal(() => cc = v)),
                      _BandSlider('Lexical Resource', lr, (v) => setLocal(() => lr = v)),
                      _BandSlider('Grammatical Range & Accuracy', gra, (v) => setLocal(() => gra = v)),
                      Text('Overall: ${((ta + cc + lr + gra) / 4 * 2).round() / 2}'),
                      const SizedBox(height: 8),
                      TextField(controller: comments, maxLines: 3, decoration: const InputDecoration(labelText: 'Comments', border: OutlineInputBorder())),
                      const SizedBox(height: 8),
                      TextField(controller: corrections, maxLines: 3, decoration: const InputDecoration(labelText: 'Corrections', border: OutlineInputBorder())),
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
    await ref.read(ieltsApiProvider).submitWritingReview(
          attempt.id,
          taskAchievement: ta,
          coherenceCohesion: cc,
          lexicalResource: lr,
          grammaticalRange: gra,
          comments: comments.text,
          corrections: corrections.text,
        );
    ref.invalidate(ieltsWritingQueueProvider(widget.subjectId));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(ieltsWritingQueueProvider(widget.subjectId));
    return Scaffold(
      appBar: AppBar(title: const Text('Writing review')),
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
            separatorBuilder: (_, __) => const SizedBox(height: 8),
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
