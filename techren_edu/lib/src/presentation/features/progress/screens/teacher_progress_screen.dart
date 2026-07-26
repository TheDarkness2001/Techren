import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/person_avatar.dart';
import '../../../../domain/entities/learning_cms.dart';
import '../../../../domain/entities/student_progress.dart';
import '../../../../domain/entities/words.dart';
import '../../../providers/learning_cms_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../../shells/teacher_shell.dart';

String _friendlyError(Object error) {
  final text = error.toString();
  if (text.contains('403') || text.contains('FORBIDDEN') || text.contains('permission')) {
    return 'You do not have access to student progress yet. Ask an admin to enable student viewing for teachers, then try again.';
  }
  if (text.contains('404') || text.contains('NOT_FOUND')) {
    return 'Progress for this lesson is not available yet. Wait for the server update, then try again.';
  }
  if (text.contains('branch')) {
    return 'Your account has no branch assigned. Ask an admin to fix that, then try again.';
  }
  if (text.contains('connection') || text.contains('SocketException') || text.contains('CONNECTION')) {
    return 'Cannot reach the server. Check your connection and try again.';
  }
  return 'Could not load progress. Please try again.';
}

/// Teacher view: pick a class, then a lesson/topic, then see that lesson’s results only.
class TeacherProgressScreen extends ConsumerStatefulWidget {
  const TeacherProgressScreen({super.key});

  @override
  ConsumerState<TeacherProgressScreen> createState() => _TeacherProgressScreenState();
}

class _TeacherProgressScreenState extends ConsumerState<TeacherProgressScreen> {
  String? _groupId;
  String? _languageId;
  String? _levelId;
  String? _lessonId;

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
              message: 'When you are assigned to a class group, you can review lesson progress here.',
              icon: Icons.groups_outlined,
            );
          }

          final groups = [
            for (final report in reports)
              (
                id: report.group['id']?.toString() ?? '',
                name: report.group['groupName'] as String? ?? 'Group',
                subject: report.group['subjectName'] as String? ?? '',
              ),
          ].where((g) => g.id.isNotEmpty).toList();

          final selectedGroupId = _groupId != null && groups.any((g) => g.id == _groupId)
              ? _groupId
              : groups.first.id;
          final selectedGroup = groups.firstWhere((g) => g.id == selectedGroupId);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(teacherMyGroupsProgressProvider);
              if (_lessonId != null && selectedGroupId != null) {
                ref.invalidate(groupLessonProgressProvider((groupId: selectedGroupId, lessonId: _lessonId!)));
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSpacing.pagePaddingWide,
              children: [
                Text(
                  'Choose a class and lesson to see that topic’s results only.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.semantic.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                _SelectorCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedGroupId,
                        decoration: const InputDecoration(
                          labelText: 'Class / group',
                          prefixIcon: Icon(Icons.groups_outlined),
                        ),
                        items: [
                          for (final group in groups)
                            DropdownMenuItem(
                              value: group.id,
                              child: Text(
                                group.subject.isEmpty ? group.name : '${group.name} · ${group.subject}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() {
                          _groupId = value;
                          _languageId = null;
                          _levelId = null;
                          _lessonId = null;
                        }),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _LanguagePicker(
                        preferredSubject: selectedGroup.subject,
                        languageId: _languageId,
                        onChanged: (id) => setState(() {
                          _languageId = id;
                          _levelId = null;
                          _lessonId = null;
                        }),
                      ),
                      if (_languageId != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _LevelPicker(
                          languageId: _languageId!,
                          levelId: _levelId,
                          onChanged: (id) => setState(() {
                            _levelId = id;
                            _lessonId = null;
                          }),
                        ),
                      ],
                      if (_levelId != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _LessonPicker(
                          levelId: _levelId!,
                          lessonId: _lessonId,
                          onChanged: (id) => setState(() => _lessonId = id),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_lessonId == null)
                  const EmptyState(
                    title: 'Select a lesson',
                    message: 'Pick language, level, and lesson/topic to view this class’s results.',
                    icon: Icons.menu_book_outlined,
                  )
                else
                  _LessonResultsPanel(groupId: selectedGroupId!, lessonId: _lessonId!),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SelectorCard extends StatelessWidget {
  const _SelectorCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker({
    required this.preferredSubject,
    required this.languageId,
    required this.onChanged,
  });

  final String preferredSubject;
  final String? languageId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagesAsync = ref.watch(cmsLanguagesProvider);
    return languagesAsync.when(
      loading: () => const ListTile(
        dense: true,
        leading: Icon(Icons.translate_outlined),
        title: Text('Loading languages…'),
      ),
      error: (e, _) => Text(_friendlyError(e)),
      data: (languages) {
        if (languages.isEmpty) {
          return const Text('No word languages found. Add content in Learning CMS first.');
        }

        final preferred = preferredSubject.trim().toLowerCase();
        var ordered = List<LearningLanguage>.from(languages);
        if (preferred.isNotEmpty) {
          ordered.sort((a, b) {
            final aMatch = a.name.trim().toLowerCase() == preferred ? 0 : 1;
            final bMatch = b.name.trim().toLowerCase() == preferred ? 0 : 1;
            if (aMatch != bMatch) return aMatch.compareTo(bMatch);
            return a.name.compareTo(b.name);
          });
        }

        final value = languageId != null && ordered.any((l) => l.id == languageId)
            ? languageId
            : null;

        return DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            labelText: 'Language',
            prefixIcon: Icon(Icons.translate_outlined),
          ),
          hint: const Text('Select language'),
          items: [
            for (final language in ordered)
              DropdownMenuItem(value: language.id, child: Text(language.name)),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

class _LevelPicker extends ConsumerWidget {
  const _LevelPicker({
    required this.languageId,
    required this.levelId,
    required this.onChanged,
  });

  final String languageId;
  final String? levelId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(cmsLevelsProvider(languageId));
    return levelsAsync.when(
      loading: () => const ListTile(
        dense: true,
        leading: Icon(Icons.layers_outlined),
        title: Text('Loading levels…'),
      ),
      error: (e, _) => Text(_friendlyError(e)),
      data: (levels) {
        if (levels.isEmpty) {
          return const Text('No levels in this language yet.');
        }
        final value = levelId != null && levels.any((l) => l.id == levelId) ? levelId : null;
        return DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            labelText: 'Level',
            prefixIcon: Icon(Icons.layers_outlined),
          ),
          hint: const Text('Select level'),
          items: [
            for (final level in levels) DropdownMenuItem(value: level.id, child: Text(level.name)),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

class _LessonPicker extends ConsumerWidget {
  const _LessonPicker({
    required this.levelId,
    required this.lessonId,
    required this.onChanged,
  });

  final String levelId;
  final String? lessonId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(cmsLessonsProvider(levelId));
    return lessonsAsync.when(
      loading: () => const ListTile(
        dense: true,
        leading: Icon(Icons.topic_outlined),
        title: Text('Loading lessons…'),
      ),
      error: (e, _) => Text(_friendlyError(e)),
      data: (lessons) {
        if (lessons.isEmpty) {
          return const Text('No lessons/topics in this level yet.');
        }
        final sorted = List<CmsLesson>.from(lessons)..sort((a, b) => a.order.compareTo(b.order));
        final value = lessonId != null && sorted.any((l) => l.id == lessonId) ? lessonId : null;
        return DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(
            labelText: 'Lesson / topic',
            prefixIcon: Icon(Icons.topic_outlined),
          ),
          hint: const Text('Select lesson'),
          items: [
            for (final lesson in sorted)
              DropdownMenuItem(
                value: lesson.id,
                child: Text(
                  lesson.wordCount > 0 ? '${lesson.name} (${lesson.wordCount} words)' : lesson.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

class _LessonResultsPanel extends ConsumerWidget {
  const _LessonResultsPanel({
    required this.groupId,
    required this.lessonId,
  });

  final String groupId;
  final String lessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(groupLessonProgressProvider((groupId: groupId, lessonId: lessonId)));
    return async.when(
      loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Text(_friendlyError(e), textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => ref.invalidate(
                  groupLessonProgressProvider((groupId: groupId, lessonId: lessonId)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (report) {
        final muted = context.semantic.textMuted;
        final lessonName = report.lesson['name'] as String? ?? 'Lesson';
        final groupName = report.group['groupName'] as String? ?? 'Group';
        final subjectName = report.group['subjectName'] as String?;
        final passed = report.students.where((s) => s.status == 'passed').length;
        final started = report.students.where((s) => s.hasStarted).length;

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(lessonName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subjectName == null || subjectName.isEmpty
                      ? groupName
                      : '$groupName · $subjectName',
                  style: TextStyle(color: muted, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _StatChip(label: 'Students', value: '${report.students.length}'),
                    _StatChip(label: 'Started', value: '$started'),
                    _StatChip(label: 'Passed', value: '$passed'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (report.students.isEmpty)
                  Text('No students in this class.', style: TextStyle(color: muted))
                else ...[
                  Row(
                    children: [
                      Expanded(flex: 4, child: Text('Student', style: _headerStyle(muted))),
                      Expanded(flex: 2, child: Text('Exam', textAlign: TextAlign.center, style: _headerStyle(muted))),
                      Expanded(flex: 2, child: Text('Status', textAlign: TextAlign.center, style: _headerStyle(muted))),
                      Expanded(flex: 2, child: Text('Practice', textAlign: TextAlign.center, style: _headerStyle(muted))),
                    ],
                  ),
                  const Divider(height: AppSpacing.lg),
                  for (final student in report.students) ...[
                    _LessonStudentRow(student: student),
                    if (student != report.students.last) const Divider(height: 1),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  TextStyle _headerStyle(Color muted) => TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 12);
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

class _LessonStudentRow extends StatelessWidget {
  const _LessonStudentRow({required this.student});

  final GroupLessonStudentProgress student;

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
          Expanded(flex: 2, child: Center(child: _PercentPill(student.bestExamScore))),
          Expanded(flex: 2, child: Center(child: _StatusChip(student.status))),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                '${student.practiceAttempts}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'passed' => 'Passed',
      'available' => 'In progress',
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 11)),
    );
  }
}
