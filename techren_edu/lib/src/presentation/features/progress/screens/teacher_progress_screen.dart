import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/person_avatar.dart';
import '../../../../domain/entities/student_progress.dart';
import '../../../providers/progress_provider.dart';
import '../../../shells/teacher_shell.dart';

String _friendlyError(Object error) {
  final text = error.toString();
  if (text.contains('403') || text.contains('FORBIDDEN') || text.contains('permission')) {
    return 'You do not have access to student progress yet. Ask an admin to enable student viewing for teachers, then try again.';
  }
  if (text.contains('branch')) {
    return 'Your account has no branch assigned. Ask an admin to fix that, then try again.';
  }
  if (text.contains('connection') || text.contains('SocketException') || text.contains('CONNECTION')) {
    return 'Cannot reach the server. Check your connection and try again.';
  }
  return 'Could not load progress. Please try again.';
}

/// Teacher view: student progress for their own groups, sectioned group-by-group.
class TeacherProgressScreen extends ConsumerWidget {
  const TeacherProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(teacherMyGroupsProgressProvider);

    return AdaptiveScaffold(
      title: 'Student Progress',
      selectedIndex: 3,
      selectedRoute: '/teacher/progress',
      items: teacherNavItems,
      onDestinationSelected: (i) => context.go(teacherNavItems[i].route),
      body: async.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => Center(
          child: Padding(
            padding: AppSpacing.pagePaddingWide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _friendlyError(e),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => ref.invalidate(teacherMyGroupsProgressProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (reports) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(teacherMyGroupsProgressProvider),
          child: reports.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.pagePaddingWide,
                  children: const [
                    SizedBox(height: 80),
                    EmptyState(
                      title: 'No groups yet',
                      message: 'When you are assigned to a class group, your students’ progress will appear here by group.',
                      icon: Icons.groups_outlined,
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppSpacing.pagePaddingWide,
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) => _TeacherGroupProgressCard(report: reports[index]),
                ),
        ),
      ),
    );
  }
}

class _TeacherGroupProgressCard extends StatelessWidget {
  const _TeacherGroupProgressCard({required this.report});

  final GroupProgressReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = context.semantic.textMuted;
    final groupName = report.group['groupName'] as String? ?? 'Group';
    final subjectName = report.group['subjectName'] as String? ?? 'Subject';
    final studentCount = report.students.length;
    final avgWords = (report.aggregate['avgWordsAccuracy'] as num?)?.toInt() ?? 0;
    final avgSentences = (report.aggregate['avgSentencesAccuracy'] as num?)?.toInt() ?? 0;

    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: reportsShouldExpand(studentCount),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        title: Text(groupName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '$subjectName · $studentCount student${studentCount == 1 ? '' : 's'}',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _StatChip(label: 'Avg words', value: '$avgWords%'),
              _StatChip(label: 'Avg sentences', value: '$avgSentences%'),
              _StatChip(
                label: 'Lessons passed',
                value: '${report.aggregate['totalLessonsPassed'] ?? 0}',
              ),
              _StatChip(label: 'Total XP', value: '${report.aggregate['totalXp'] ?? 0}'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (report.students.isEmpty)
            Text('No students in this group.', style: TextStyle(color: muted))
          else ...[
            Row(
              children: [
                Expanded(flex: 4, child: Text('Student', style: _headerStyle(muted))),
                Expanded(flex: 2, child: Text('Words', textAlign: TextAlign.center, style: _headerStyle(muted))),
                Expanded(flex: 2, child: Text('Sentences', textAlign: TextAlign.center, style: _headerStyle(muted))),
                Expanded(flex: 2, child: Text('Lessons', textAlign: TextAlign.center, style: _headerStyle(muted))),
                Expanded(flex: 2, child: Text('XP', textAlign: TextAlign.center, style: _headerStyle(muted))),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            for (final student in report.students) ...[
              _StudentProgressRow(student: student),
              if (student != report.students.last) const Divider(height: 1),
            ],
          ],
        ],
      ),
    );
  }

  static bool reportsShouldExpand(int studentCount) => studentCount > 0 && studentCount <= 12;

  TextStyle _headerStyle(Color muted) => TextStyle(
        color: muted,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      );
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label · ', style: TextStyle(color: context.semantic.textMuted, fontSize: 12)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _StudentProgressRow extends StatelessWidget {
  const _StudentProgressRow({required this.student});

  final StudentProgressSummary student;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                PersonAvatar(
                  name: student.name,
                  profileImage: student.profileImage,
                  radius: 16,
                  isStudent: true,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      if (student.studentCode != null && student.studentCode!.isNotEmpty)
                        Text(
                          student.studentCode!,
                          style: TextStyle(color: context.semantic.textMuted, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(flex: 2, child: Center(child: _PercentPill(student.wordsAccuracy))),
          Expanded(flex: 2, child: Center(child: _PercentPill(student.sentencesAccuracy))),
          Expanded(
            flex: 2,
            child: Center(
              child: Text('${student.lessonsPassed}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text('${student.totalXp}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentPill extends StatelessWidget {
  const _PercentPill(this.value);

  final int value;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (value <= 0) {
      bg = const Color(0xFFFCE7F3);
      fg = const Color(0xFFBE123C);
    } else if (value < 50) {
      bg = const Color(0xFFFFEDD5);
      fg = const Color(0xFFC2410C);
    } else if (value < 70) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
    } else {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text('$value%', style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}
