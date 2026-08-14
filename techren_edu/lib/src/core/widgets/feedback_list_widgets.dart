import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

/// Shared display helpers for student / parent feedback lists.
String formatFeedbackClassDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '—';
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return trimmed;
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${weekdays[parsed.weekday - 1]}, ${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
}

String formatFeedbackSubmittedAt(DateTime? createdAt) {
  if (createdAt == null) return '';
  final local = createdAt.toLocal();
  final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final m = local.minute.toString().padLeft(2, '0');
  final ampm = local.hour >= 12 ? 'PM' : 'AM';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[local.month - 1]} ${local.day}, ${local.year} · $h:$m $ampm';
}

class FeedbackScoreSummary {
  const FeedbackScoreSummary({
    required this.isEnglish,
    required this.primaryLabel,
    required this.primaryValue,
    this.secondaryLabel,
    this.secondaryValue,
    required this.behavior,
    required this.participation,
    this.examPercentage,
    this.isExamDay = false,
  });

  final bool isEnglish;
  final String primaryLabel;
  final int primaryValue;
  final String? secondaryLabel;
  final int? secondaryValue;
  final int behavior;
  final int participation;
  final int? examPercentage;
  final bool isExamDay;
}

class FeedbackListCard extends StatelessWidget {
  const FeedbackListCard({
    super.key,
    required this.title,
    required this.classDateLabel,
    required this.submittedAtLabel,
    required this.summary,
    this.teacherName,
    this.footer,
    this.trailing,
    this.onMore,
  });

  final String title;
  final String classDateLabel;
  final String submittedAtLabel;
  final FeedbackScoreSummary summary;
  final String? teacherName;
  final String? footer;
  final Widget? trailing;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: semantic.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.9),
                        AppColors.primary.withValues(alpha: 0.55),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.rate_review_outlined, color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Class date · $classDateLabel',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: semantic.textMuted),
                      ),
                      if (submittedAtLabel.isNotEmpty)
                        Text(
                          'Submitted · $submittedAtLabel',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: semantic.textMuted),
                        ),
                      if (teacherName != null && teacherName!.isNotEmpty)
                        Text(
                          teacherName!,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: semantic.textMuted),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                if (onMore != null)
                  TextButton(
                    onPressed: onMore,
                    child: const Text('More'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(label: summary.primaryLabel, value: summary.primaryValue),
                if (summary.secondaryLabel != null && summary.secondaryValue != null)
                  _MetricChip(label: summary.secondaryLabel!, value: summary.secondaryValue!),
                _MetricChip(label: 'Behavior', value: summary.behavior),
                _MetricChip(label: 'Participation', value: summary.participation),
                if (summary.isExamDay)
                  _MetricChip(label: 'Exam', value: summary.examPercentage ?? 0, accent: true),
              ],
            ),
            if (footer != null && footer!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(footer!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value, this.accent = false});

  final String label;
  final int value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ? AppColors.warning : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$label $value%',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

enum FeedbackInsightsRange { all, days7, days30 }

Future<void> showFeedbackInsightsSheet({
  required BuildContext context,
  required String title,
  required List<FeedbackInsightPoint> points,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _FeedbackInsightsSheet(title: title, points: points),
  );
}

class FeedbackInsightPoint {
  const FeedbackInsightPoint({
    required this.id,
    required this.className,
    required this.date,
    required this.createdAt,
    required this.isEnglish,
    required this.homework,
    required this.words,
    required this.sentence,
    required this.behavior,
    required this.participation,
  });

  final String id;
  final String className;
  final String date;
  final DateTime? createdAt;
  final bool isEnglish;
  final int homework;
  final int words;
  final int sentence;
  final int behavior;
  final int participation;

  DateTime get sortDate {
    if (createdAt != null) return createdAt!;
    return DateTime.tryParse(date) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _FeedbackInsightsSheet extends StatefulWidget {
  const _FeedbackInsightsSheet({required this.title, required this.points});

  final String title;
  final List<FeedbackInsightPoint> points;

  @override
  State<_FeedbackInsightsSheet> createState() => _FeedbackInsightsSheetState();
}

class _FeedbackInsightsSheetState extends State<_FeedbackInsightsSheet> {
  FeedbackInsightsRange _range = FeedbackInsightsRange.days30;
  String _metric = 'all'; // all | primary | behavior | participation

  List<FeedbackInsightPoint> get _filtered {
    final now = DateTime.now();
    return widget.points.where((p) {
      if (_range == FeedbackInsightsRange.days7 &&
          p.sortDate.isBefore(now.subtract(const Duration(days: 7)))) {
        return false;
      }
      if (_range == FeedbackInsightsRange.days30 &&
          p.sortDate.isBefore(now.subtract(const Duration(days: 30)))) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.sortDate.compareTo(b.sortDate));
  }

  double _avg(Iterable<int> values) {
    final list = values.toList();
    if (list.isEmpty) return 0;
    return list.reduce((a, b) => a + b) / list.length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final semantic = context.semantic;
    final englishCount = filtered.where((e) => e.isEnglish).length;
    final useEnglish = englishCount >= (filtered.length / 2).ceil() && filtered.isNotEmpty;

    final primaryAvg = useEnglish
        ? _avg(filtered.expand((e) => [e.words, e.sentence]))
        : _avg(filtered.map((e) => e.homework));
    final behaviorAvg = _avg(filtered.map((e) => e.behavior));
    final participationAvg = _avg(filtered.map((e) => e.participation));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Charts and filters for recent feedback',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: semantic.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in FeedbackInsightsRange.values)
                  ChoiceChip(
                    label: Text(switch (r) {
                      FeedbackInsightsRange.all => 'All',
                      FeedbackInsightsRange.days7 => '7 days',
                      FeedbackInsightsRange.days30 => '30 days',
                    }),
                    selected: _range == r,
                    onSelected: (_) => setState(() => _range = r),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(useEnglish ? 'Words/Sentence' : 'Homework'),
                  selected: _metric == 'primary',
                  onSelected: (_) => setState(() => _metric = 'primary'),
                ),
                ChoiceChip(
                  label: const Text('Behavior'),
                  selected: _metric == 'behavior',
                  onSelected: (_) => setState(() => _metric = 'behavior'),
                ),
                ChoiceChip(
                  label: const Text('Participation'),
                  selected: _metric == 'participation',
                  onSelected: (_) => setState(() => _metric = 'participation'),
                ),
                ChoiceChip(
                  label: const Text('Overview'),
                  selected: _metric == 'all',
                  onSelected: (_) => setState(() => _metric = 'all'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No feedback in this range',
                    style: TextStyle(color: semantic.textMuted),
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _AvgTile(
                      label: useEnglish ? 'Words+Sentence' : 'Homework',
                      value: primaryAvg,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AvgTile(label: 'Behavior', value: behaviorAvg, color: AppColors.success),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _AvgTile(
                      label: 'Participation',
                      value: participationAvg,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Trend',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 180,
                child: _SimpleBarChart(
                  values: [
                    for (final p in filtered)
                      switch (_metric) {
                        'behavior' => p.behavior.toDouble(),
                        'participation' => p.participation.toDouble(),
                        'primary' => useEnglish
                            ? ((p.words + p.sentence) / 2).toDouble()
                            : p.homework.toDouble(),
                        _ => ((useEnglish ? ((p.words + p.sentence) / 2) : p.homework) +
                                p.behavior +
                                p.participation) /
                            3,
                      },
                  ],
                  labels: [
                    for (final p in filtered)
                      (DateTime.tryParse(p.date) ?? p.sortDate).day.toString(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${filtered.length} entries',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final p in filtered.reversed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.className),
                  subtitle: Text(
                    '${formatFeedbackClassDate(p.date)}'
                    '${p.createdAt != null ? ' · ${formatFeedbackSubmittedAt(p.createdAt)}' : ''}',
                  ),
                  trailing: Text(
                    p.isEnglish
                        ? 'W ${p.words} · S ${p.sentence}'
                        : 'HW ${p.homework}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _AvgTile extends StatelessWidget {
  const _AvgTile({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            '${value.round()}%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _SimpleBarChart extends StatelessWidget {
  const _SimpleBarChart({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final max = values.fold<double>(1, (m, v) => v > m ? v : m);
    final semantic = context.semantic;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      decoration: BoxDecoration(
        color: semantic.surfaceContainer,
        borderRadius: AppRadius.card,
        border: Border.all(color: semantic.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: (values[i] / max).clamp(0.05, 1),
                        widthFactor: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withValues(alpha: 0.45),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
