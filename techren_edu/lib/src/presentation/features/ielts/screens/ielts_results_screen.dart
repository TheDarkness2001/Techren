import 'package:flutter/material.dart';
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

class IeltsResultsScreen extends ConsumerStatefulWidget {
  const IeltsResultsScreen({
    super.key,
    required this.subjectId,
    required this.attemptId,
    this.routePrefix = '/student',
  });

  final String subjectId;
  final String attemptId;
  final String routePrefix;

  @override
  ConsumerState<IeltsResultsScreen> createState() => _IeltsResultsScreenState();
}

class _IeltsResultsScreenState extends ConsumerState<IeltsResultsScreen> {
  IeltsAttemptBundle? _bundle;
  String? _error;
  bool _loading = true;

  String get _hub => ieltsHubRoute(widget.routePrefix, widget.subjectId);
  String get _history => '$_hub/history';

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
      final bundle = await ref.read(ieltsApiProvider).getAttempt(widget.attemptId);
      setState(() {
        _bundle = bundle;
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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Results'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go(_hub)),
        ),
        body: const LoadingState(message: 'Loading results...'),
      );
    }
    if (_error != null || _bundle == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Results'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go(_hub)),
        ),
        body: ErrorState(message: _error ?? 'Missing', onRetry: _load),
      );
    }

    final attempt = _bundle!.attempt;
    final scores = attempt.scores;
    final review = _bundle!.writingReview;
    final muted = context.semantic.textMuted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(_hub),
        ),
      ),
      body: ListView(
        padding: AppSpacing.pagePaddingWide,
        children: [
          Text(_bundle!.exam.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Status: ${attempt.status}', style: TextStyle(color: muted)),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _BandCard('Listening', scores.listeningBand, detail: scores.listeningRaw != null ? '${scores.listeningRaw}/${scores.listeningMax}' : null),
              _BandCard('Reading', scores.readingBand, detail: scores.readingRaw != null ? '${scores.readingRaw}/${scores.readingMax}' : null),
              _BandCard('Writing', scores.writingBand, detail: review == null ? 'Pending teacher review' : null),
              _BandCard('Overall', scores.overallBand, emphasize: true),
            ],
          ),
          if (review != null) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Writing criteria', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('TA/TR ${review.taskAchievement} · CC ${review.coherenceCohesion} · LR ${review.lexicalResource} · GRA ${review.grammaticalRange}'),
            if (review.comments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comments),
            ],
            if (review.corrections.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Corrections', style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(review.corrections),
            ],
          ],
          if (attempt.questionReview.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            Text('Question review', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...attempt.questionReview.map((r) {
              final studentText = r.studentAnswer is Map
                  ? (r.studentAnswer as Map).entries.map((e) => '${e.key}: ${e.value}').join(', ')
                  : r.studentAnswer is List
                      ? (r.studentAnswer as List).join(', ')
                      : (r.studentAnswer?.toString() ?? '—');
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            r.correct ? Icons.check_circle : Icons.cancel,
                            color: r.correct ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Q${r.number ?? '—'} · ${r.type.replaceAll('_', ' ')}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(r.correct ? 'Correct' : 'Incorrect'),
                        ],
                      ),
                      if (r.prompt.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(r.prompt, style: const TextStyle(height: 1.35)),
                      ],
                      const SizedBox(height: 6),
                      Text('Your answer: $studentText', style: TextStyle(color: muted)),
                      if (!r.correct)
                        Text(
                          'Accepted: ${r.correctAnswers.isEmpty ? '—' : r.correctAnswers.join(' / ')}',
                          style: TextStyle(color: muted),
                        ),
                      if (r.reason != null && r.reason!.isNotEmpty)
                        Text(r.reason!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                      if (r.explanation.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(r.explanation, style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton(
            onPressed: () => context.go(_history),
            child: const Text('Exam history'),
          ),
        ],
      ),
    );
  }
}

class _BandCard extends StatelessWidget {
  const _BandCard(this.label, this.band, {this.detail, this.emphasize = false});
  final String label;
  final double? band;
  final String? detail;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        border: Border.all(color: emphasize ? AppColors.primary : context.semantic.border),
        color: emphasize ? AppColors.primary.withValues(alpha: 0.08) : Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            band == null ? '—' : band!.toStringAsFixed(band! % 1 == 0 ? 0 : 1),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (detail != null) Text(detail!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class IeltsHistoryScreen extends ConsumerWidget {
  const IeltsHistoryScreen({
    super.key,
    required this.subjectId,
    this.routePrefix = '/student',
  });

  final String subjectId;
  final String routePrefix;

  String get _hub => ieltsHubRoute(routePrefix, subjectId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ieltsHistoryProvider(subjectId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam history'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(_hub),
        ),
      ),
      body: async.when(
        loading: () => const LoadingState(message: 'Loading history...'),
        error: (e, _) => ErrorState(message: e.toString(), onRetry: () => ref.invalidate(ieltsHistoryProvider)),
        data: (page) {
          if (page.items.isEmpty) {
            return const EmptyState(title: 'No attempts yet', message: 'Completed mocks will appear here.');
          }
          return ListView.separated(
            padding: AppSpacing.pagePaddingWide,
            itemCount: page.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final a = page.items[i];
              final title = a.exam?.title ?? 'Exam';
              final overall = a.scores.overallBand;
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.card,
                  side: BorderSide(color: context.semantic.border),
                ),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  '${a.submittedAt?.toLocal().toString().split('.').first ?? a.status}'
                  ' · L ${a.scores.listeningBand ?? '—'} · R ${a.scores.readingBand ?? '—'} · W ${a.scores.writingBand ?? '—'}',
                ),
                trailing: Text(
                  overall == null ? '—' : overall.toStringAsFixed(overall % 1 == 0 ? 0 : 1),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                onTap: () => context.go('$_hub/results/${a.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
