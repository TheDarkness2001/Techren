import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/attendance.dart';
import '../../../providers/attendance_provider.dart';
import 'dashboard_header.dart';

/// Compact horizontal feedback cards for the student dashboard (near top).
class StudentDashboardFeedbackStrip extends ConsumerWidget {
  const StudentDashboardFeedbackStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(
      feedbackListProvider((studentId: null, page: 1, search: '')),
    );

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (page) {
        final items = page.items.take(8).toList();
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardSection(
              title: l10n.latestFeedback,
              trailing: TextButton(
                onPressed: () => context.go('/student/feedback'),
                child: Text(l10n.viewAll),
              ),
              child: SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) => _FeedbackMiniCard(entry: items[i]),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        );
      },
    );
  }
}

String _formatFeedbackHomeDate(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return trimmed;
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${weekdays[parsed.weekday - 1]}, ${months[parsed.month - 1]} ${parsed.day}';
}

class _FeedbackMiniCard extends StatelessWidget {
  const _FeedbackMiniCard({required this.entry});

  final FeedbackEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final semantic = context.semantic;
    final theme = Theme.of(context);
    final teacher = entry.teacherName?.trim();
    final dateLabel = _formatFeedbackHomeDate(entry.date);

    return Material(
      color: semantic.surfaceContainer,
      borderRadius: AppRadius.card,
      child: InkWell(
        borderRadius: AppRadius.card,
        onTap: () => context.go('/student/feedback'),
        child: Container(
          width: 220,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(color: semantic.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.className.isEmpty ? l10n.classLabel : entry.className,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (dateLabel.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.calendar_today_outlined, size: 12, color: semantic.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      dateLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: semantic.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              if (teacher != null && teacher.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  teacher,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(color: semantic.textMuted),
                ),
              ],
              const Spacer(),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _ScoreChip(label: l10n.homeworkScore, value: entry.homework),
                  _ScoreChip(label: l10n.behaviorScore, value: entry.behavior),
                  _ScoreChip(label: l10n.participationScore, value: entry.participation),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: semantic.border),
      ),
      child: Text(
        '$label $value%',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
      ),
    );
  }
}
