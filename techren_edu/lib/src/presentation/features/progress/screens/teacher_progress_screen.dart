import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
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
    return 'You do not have access to student progress yet.';
  }
  if (text.contains('connection') || text.contains('SocketException') || text.contains('CONNECTION')) {
    return 'Cannot reach the server. Check your connection and try again.';
  }
  return 'Could not load progress. Please try again.';
}

/// Teacher progress: group tables with an in-header lesson dropdown (reference UI).
class TeacherProgressScreen extends ConsumerStatefulWidget {
  const TeacherProgressScreen({super.key});

  @override
  ConsumerState<TeacherProgressScreen> createState() => _TeacherProgressScreenState();
}

class _TeacherProgressScreenState extends ConsumerState<TeacherProgressScreen> {
  String? _subjectFilter;
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(teacherMyGroupsProgressProvider);

    return AdaptiveScaffold(
      title: 'Student Progress',
      selectedIndex: 3,
      selectedRoute: '/teacher/progress',
      items: teacherNavItems,
      onDestinationSelected: (i) => context.go(teacherNavItems[i].route),
      body: groupsAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => Center(
          child: Padding(
            padding: AppSpacing.pagePaddingWide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_friendlyError(e), textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => ref.invalidate(teacherMyGroupsProgressProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return const EmptyState(
              title: 'No groups yet',
              message: 'When you are assigned to a class group, student progress will appear here.',
              icon: Icons.groups_outlined,
            );
          }

          final subjects = <String>{
            for (final r in reports)
              if ((r.group['subjectName'] as String?)?.trim().isNotEmpty == true)
                (r.group['subjectName'] as String).trim(),
          }.toList()
            ..sort();

          final filtered = _subjectFilter == null
              ? reports
              : reports
                  .where((r) => (r.group['subjectName'] as String?)?.trim() == _subjectFilter)
                  .toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(teacherMyGroupsProgressProvider);
              ref.invalidate(progressLessonOptionsProvider);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.pagePaddingWide,
              children: [
                _FiltersBar(
                  subjects: subjects,
                  selectedSubject: _subjectFilter,
                  selectedDate: _selectedDate,
                  onSubjectChanged: (v) => setState(() => _subjectFilter = v),
                  onDateChanged: (v) => setState(() => _selectedDate = v),
                ),
                const SizedBox(height: AppSpacing.md),
                if (filtered.isEmpty)
                  const EmptyState(
                    title: 'No groups',
                    message: 'No classes match this subject filter.',
                    icon: Icons.filter_alt_off_outlined,
                  )
                else
                  for (final report in filtered) ...[
                    _GroupProgressTable(report: report),
                    const SizedBox(height: AppSpacing.md),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.subjects,
    required this.selectedSubject,
    required this.selectedDate,
    required this.onSubjectChanged,
    required this.onDateChanged,
  });

  final List<String> subjects;
  final String? selectedSubject;
  final DateTime? selectedDate;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<DateTime?> onDateChanged;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    onDateChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    return Row(
      children: [
        Expanded(
          child: _FilterCard(
            label: 'SUBJECT',
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                isExpanded: true,
                value: selectedSubject,
                hint: Row(
                  children: [
                    const Text('🎨', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text('All Subjects', style: TextStyle(color: muted))),
                  ],
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Subjects'),
                  ),
                  for (final subject in subjects)
                    DropdownMenuItem<String?>(value: subject, child: Text(subject)),
                ],
                onChanged: onSubjectChanged,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _FilterCard(
            label: 'DATE',
            child: InkWell(
              onTap: () => _pickDate(context),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      selectedDate == null
                          ? 'mm/dd/yyyy'
                          : '${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.year}',
                      style: TextStyle(color: muted),
                    ),
                  ),
                  Icon(Icons.calendar_month_outlined, size: 18, color: muted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.semantic.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _GroupProgressTable extends ConsumerStatefulWidget {
  const _GroupProgressTable({required this.report});

  final GroupProgressReport report;

  @override
  ConsumerState<_GroupProgressTable> createState() => _GroupProgressTableState();
}

class _GroupProgressTableState extends ConsumerState<_GroupProgressTable> {
  /// null = All Lessons (Aggregate)
  String? _selectedLessonId;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    final groupName = widget.report.group['groupName'] as String? ?? 'Group';
    final subjectName = widget.report.group['subjectName'] as String? ?? '—';
    final groupId = widget.report.group['id']?.toString() ?? '';
    final lessonsAsync = ref.watch(progressLessonOptionsProvider(subjectName));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('📁', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(groupName, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(subjectName, style: TextStyle(color: muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      '${widget.report.students.length} students',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                lessonsAsync.when(
                  loading: () => _LessonDropdownShell(
                    child: Text('Loading topics…', style: TextStyle(color: muted, fontSize: 13)),
                  ),
                  error: (e, _) => _LessonDropdownShell(
                    child: Text('Topics unavailable', style: TextStyle(color: muted, fontSize: 13)),
                  ),
                  data: (lessons) {
                    if (lessons.isEmpty) {
                      return _LessonDropdownShell(
                        child: Text(
                          'No topics in CMS',
                          style: TextStyle(color: muted, fontSize: 13),
                        ),
                      );
                    }
                    final selected =
                        _selectedLessonId != null && lessons.any((l) => l.id == _selectedLessonId)
                            ? _selectedLessonId
                            : null;
                    return _LessonDropdownShell(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          isDense: true,
                          value: selected,
                          hint: const Text('All Lessons (Aggregate)', style: TextStyle(fontSize: 13)),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Lessons (Aggregate)'),
                            ),
                            for (final lesson in lessons)
                              DropdownMenuItem<String?>(
                                value: lesson.id,
                                child: Text(lesson.label),
                              ),
                          ],
                          onChanged: (value) => setState(() => _selectedLessonId = value),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_selectedLessonId == null)
            _AggregateRows(students: widget.report.students)
          else if (groupId.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text('Missing group id.', style: TextStyle(color: muted)),
            )
          else
            _LessonRows(groupId: groupId, lessonId: _selectedLessonId!),
        ],
      ),
    );
  }
}

class _LessonDropdownShell extends StatelessWidget {
  const _LessonDropdownShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: context.semantic.border),
        borderRadius: AppRadius.card,
      ),
      child: child,
    );
  }
}

class _AggregateRows extends StatelessWidget {
  const _AggregateRows({required this.students});

  final List<StudentProgressSummary> students;

  int _wordExamPercent(StudentProgressSummary student) {
    if (student.lessonsPassed <= 0) return 0;
    return (student.lessonsPassed * 20).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(flex: 4, child: Text('Student Name', style: _header(muted))),
              Expanded(flex: 2, child: Text('Word Practice', textAlign: TextAlign.center, style: _header(muted))),
              Expanded(flex: 2, child: Text('Word Exam', textAlign: TextAlign.center, style: _header(muted))),
              Expanded(flex: 2, child: Text('Sentence Practice', textAlign: TextAlign.center, style: _header(muted))),
            ],
          ),
        ),
        if (students.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text('No students in this group.', style: TextStyle(color: muted)),
          )
        else
          for (final student in students)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(flex: 4, child: _StudentName(student.name, student.profileImage)),
                      Expanded(flex: 2, child: Center(child: _PercentPill(student.wordsAccuracy))),
                      Expanded(flex: 2, child: Center(child: _PercentPill(_wordExamPercent(student)))),
                      Expanded(flex: 2, child: Center(child: _PercentPill(student.sentencesAccuracy))),
                    ],
                  ),
                ),
                if (student != students.last) const Divider(height: 1),
              ],
            ),
      ],
    );
  }

  TextStyle _header(Color muted) => TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12);
}

class _LessonRows extends ConsumerWidget {
  const _LessonRows({required this.groupId, required this.lessonId});

  final String groupId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = context.semantic.textMuted;
    final async = ref.watch(groupLessonProgressProvider((groupId: groupId, lessonId: lessonId)));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: LoadingState(kind: LoadingSkeletonKind.card),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Text(_friendlyError(e), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => ref.invalidate(
                groupLessonProgressProvider((groupId: groupId, lessonId: lessonId)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (report) {
        final students = report.students;
        final isSentence = (report.lesson['type'] as String?) == 'sentences';
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text('Student Name', style: _header(muted))),
                  Expanded(
                    flex: 2,
                    child: Text(
                      isSentence ? 'Sentence Practice' : 'Word Practice',
                      textAlign: TextAlign.center,
                      style: _header(muted),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      isSentence ? 'Accuracy' : 'Word Exam',
                      textAlign: TextAlign.center,
                      style: _header(muted),
                    ),
                  ),
                  Expanded(flex: 2, child: Text('Status', textAlign: TextAlign.center, style: _header(muted))),
                ],
              ),
            ),
            if (students.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text('No students in this group.', style: TextStyle(color: muted)),
              )
            else
              for (final student in students)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Expanded(flex: 4, child: _StudentName(student.name, student.profileImage)),
                          Expanded(
                            flex: 2,
                            child: Center(child: _PercentPill(_practicePercent(student))),
                          ),
                          Expanded(flex: 2, child: Center(child: _PercentPill(student.bestExamScore))),
                          Expanded(flex: 2, child: Center(child: _StatusChip(student.status))),
                        ],
                      ),
                    ),
                    if (student != students.last) const Divider(height: 1),
                  ],
                ),
          ],
        );
      },
    );
  }

  int _practicePercent(GroupLessonStudentProgress student) {
    if (student.practiceAttempts <= 0) return 0;
    return ((student.practiceCorrect / student.practiceAttempts) * 100).round().clamp(0, 100);
  }

  TextStyle _header(Color muted) => TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12);
}

class _StudentName extends StatelessWidget {
  const _StudentName(this.name, this.profileImage);

  final String name;
  final String? profileImage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        PersonAvatar(name: name, profileImage: profileImage, radius: 16, isStudent: true),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _PercentPill extends StatelessWidget {
  const _PercentPill(this.value);

  final int value;

  Color get _bg {
    if (value == 0) return const Color(0xFFFCE7F3);
    if (value < 30) return const Color(0xFFFECDD3);
    if (value < 50) return const Color(0xFFFFEDD5);
    if (value < 70) return const Color(0xFFFEF3C7);
    return const Color(0xFFDCFCE7);
  }

  Color get _fg {
    if (value == 0) return const Color(0xFFBE123C);
    if (value < 30) return const Color(0xFFB91C1C);
    if (value < 50) return const Color(0xFFC2410C);
    if (value < 70) return const Color(0xFFB45309);
    return const Color(0xFF15803D);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text('$value%', style: TextStyle(color: _fg, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'passed' => 'Passed',
      'available' => 'Open',
      _ => 'Locked',
    };
    final Color bg;
    final Color fg;
    switch (status) {
      case 'passed':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
      case 'available':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
      default:
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}
