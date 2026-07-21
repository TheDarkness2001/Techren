import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/person_avatar.dart';
import '../../../../domain/entities/attendance.dart';

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String formatFeedbackLongDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}, ${date.year}';

String formatFeedbackShortDate(DateTime date) =>
    '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';

String feedbackApiDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

enum FeedbackClassFilter { today, all }

/// Filter bar — All / Today's Classes tabs + teacher dropdown.
class FeedbackControlBar extends StatelessWidget {
  const FeedbackControlBar({
    super.key,
    required this.filter,
    required this.selectedTeacherId,
    required this.teachers,
    required this.onFilterChanged,
    required this.onTeacherChanged,
    this.teachersLoading = false,
    this.teachersError,
    this.onRetryTeachers,
  });

  final FeedbackClassFilter filter;
  final String selectedTeacherId;
  final List<({String id, String name})> teachers;
  final ValueChanged<FeedbackClassFilter> onFilterChanged;
  final ValueChanged<String> onTeacherChanged;
  final bool teachersLoading;
  final String? teachersError;
  final VoidCallback? onRetryTeachers;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;
    final validIds = {'all', ...teachers.map((t) => t.id)};
    final safeTeacherId = validIds.contains(selectedTeacherId) ? selectedTeacherId : 'all';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: semantic.border),
        boxShadow: AppShadows.card,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 720;
          final tabs = Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _FilterChip(
                label: 'All Classes',
                icon: Icons.assignment_outlined,
                selected: filter == FeedbackClassFilter.all,
                onTap: () => onFilterChanged(FeedbackClassFilter.all),
              ),
              _FilterChip(
                label: "Today's Classes",
                icon: Icons.calendar_today_outlined,
                selected: filter == FeedbackClassFilter.today,
                onTap: () => onFilterChanged(FeedbackClassFilter.today),
              ),
            ],
          );

          final teacherFilter = teachersLoading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline, size: 18, color: scheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Loading teachers…',
                      style: TextStyle(fontWeight: FontWeight.w600, color: semantic.textMuted),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                )
              : teachersError != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 18, color: scheme.error),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            'Could not load teachers',
                            style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(onPressed: onRetryTeachers, child: const Text('Retry')),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(Icons.person_outline, size: 18, color: scheme.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Teacher',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: safeTeacherId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            borderRadius: AppRadius.card,
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('All Teachers')),
                              for (final teacher in teachers)
                                DropdownMenuItem(
                                  value: teacher.id,
                                  child: Text(teacher.name, overflow: TextOverflow.ellipsis),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) onTeacherChanged(value);
                            },
                          ),
                        ),
                      ],
                    );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tabs,
                const SizedBox(height: AppSpacing.sm),
                teacherFilter,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              tabs,
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: teacherFilter),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: selected ? scheme.primary : scheme.onSurfaceVariant),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        side: BorderSide(color: selected ? scheme.primary : semantic.border, width: selected ? 1.5 : 1),
        backgroundColor: selected ? scheme.primaryContainer : semantic.surfaceContainer,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),
    );
  }
}

/// Class card with student feedback rows.
class ClassFeedbackPanel extends StatelessWidget {
  const ClassFeedbackPanel({
    super.key,
    required this.session,
    required this.onAddFeedback,
  });

  final TodayClassSession session;
  final void Function(StudentAttendanceRow student) onAddFeedback;

  @override
  Widget build(BuildContext context) {
    final schedule = session.schedule;
    final subject = schedule.subjectName ?? 'General';
    final levelLabel = schedule.className;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3)),
            ),
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        subject,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: AppSpacing.chipPadding,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        levelLabel,
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                _InfoLine(icon: Icons.person_outline, label: 'Teacher', value: schedule.teacherName ?? '—'),
                _InfoLine(
                  icon: Icons.access_time,
                  label: 'Time',
                  value: '${schedule.startTime} - ${schedule.endTime}',
                ),
                _InfoLine(icon: Icons.meeting_room_outlined, label: 'Room', value: schedule.room ?? '—'),
                _InfoLine(
                  icon: Icons.groups_outlined,
                  label: 'Students',
                  value: '${schedule.studentCount}',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Give Feedback:', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                if (session.students.isEmpty)
                  Text('No students enrolled.', style: TextStyle(color: context.semantic.textMuted, fontSize: 13))
                else
                  for (final student in session.students)
                    _StudentFeedbackRow(
                      student: student,
                      onAdd: () => onAddFeedback(student),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: AppSpacing.sm),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          Expanded(child: Text(value, style: TextStyle(color: muted, fontSize: 13))),
        ],
      ),
    );
  }
}

class _StudentFeedbackRow extends StatelessWidget {
  const _StudentFeedbackRow({required this.student, required this.onAdd});

  final StudentAttendanceRow student;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final code = student.studentId != null ? 'ID: #${student.studentId}' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          PersonAvatar(
            name: student.name,
            profileImage: student.profileImage,
            radius: 16,
            isStudent: true,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (code.isNotEmpty)
                  Text(code, style: TextStyle(color: context.semantic.textMuted, fontSize: 11)),
              ],
            ),
          ),
          if (student.hasFeedback)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.micro),
              decoration: BoxDecoration(
                color: context.semantic.successContainer,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'Added',
                style: TextStyle(
                  color: context.semantic.onSuccessContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.micro),
              ),
              child: const Text('+ Add'),
            ),
        ],
      ),
    );
  }
}

/// Performance slider with readable contrast in light and dark themes.
class GradientMetricSlider extends StatelessWidget {
  const GradientMetricSlider({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;

  Color _valueColor(AppSemanticColors semantic) {
    if (value < 40) return semantic.danger;
    if (value < 70) return semantic.warning;
    return semantic.success;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;
    final accent = _valueColor(semantic);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: accent),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                '$label: ${value.round()}%',
                style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 8,
            activeTrackColor: accent,
            inactiveTrackColor: semantic.surfaceContainer,
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.16),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%', style: TextStyle(color: semantic.textMuted, fontSize: 11)),
              Text('50%', style: TextStyle(color: semantic.textMuted, fontSize: 11)),
              Text('100%', style: TextStyle(color: semantic.textMuted, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}

Future<bool?> showAddDailyFeedbackDialog({
  required BuildContext context,
  required TodayClassSession session,
  required StudentAttendanceRow student,
  required Future<void> Function({
    required int homework,
    required int behavior,
    required int participation,
    required bool isExamDay,
    int? examPercentage,
    required DateTime feedbackDate,
    String? notes,
  }) onSubmit,
}) {
  return showAppDialog<bool>(
    context: context,
    builder: (context) => _AddDailyFeedbackDialog(
      session: session,
      student: student,
      onSubmit: onSubmit,
    ),
  );
}

class _AddDailyFeedbackDialog extends StatefulWidget {
  const _AddDailyFeedbackDialog({
    required this.session,
    required this.student,
    required this.onSubmit,
  });

  final TodayClassSession session;
  final StudentAttendanceRow student;
  final Future<void> Function({
    required int homework,
    required int behavior,
    required int participation,
    required bool isExamDay,
    int? examPercentage,
    required DateTime feedbackDate,
    String? notes,
  }) onSubmit;

  @override
  State<_AddDailyFeedbackDialog> createState() => _AddDailyFeedbackDialogState();
}

class _AddDailyFeedbackDialogState extends State<_AddDailyFeedbackDialog> {
  double _homework = 80;
  double _behavior = 80;
  double _participation = 80;
  bool _isExamDay = false;
  double _examScore = 0;
  DateTime _feedbackDate = DateTime.now();
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _feedbackDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _feedbackDate = picked);
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        homework: _homework.round(),
        behavior: _behavior.round(),
        participation: _participation.round(),
        isExamDay: _isExamDay,
        examPercentage: _isExamDay ? _examScore.round() : null,
        feedbackDate: _feedbackDate,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final classLabel = widget.session.schedule.className;

    return Dialog(
      insetPadding: AppSpacing.dialogInset,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Add Daily Feedback', style: Theme.of(context).textTheme.titleLarge),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: AppRadius.card,
                        border: Border(
                          left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 4),
                        ),
                      ),
                      child: Text(
                        'Class: $classLabel',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Feedback Date *', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: Text(formatFeedbackShortDate(_feedbackDate)),
                      style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Select the date when the class took place.',
                      style: TextStyle(color: context.semantic.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: context.semantic.surfaceContainer,
                        borderRadius: AppRadius.card,
                        border: Border.all(color: context.semantic.border),
                      ),
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          'Exam day',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          'Include an exam score for this feedback',
                          style: TextStyle(color: context.semantic.textMuted, fontSize: 12),
                        ),
                        value: _isExamDay,
                        onChanged: (v) => setState(() => _isExamDay = v ?? false),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GradientMetricSlider(
                      label: 'Homework',
                      icon: Icons.menu_book_outlined,
                      value: _homework,
                      onChanged: (v) => setState(() => _homework = v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GradientMetricSlider(
                      label: 'Behavior',
                      icon: Icons.sentiment_satisfied_alt_outlined,
                      value: _behavior,
                      onChanged: (v) => setState(() => _behavior = v),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GradientMetricSlider(
                      label: 'Participation',
                      icon: Icons.person_outline,
                      value: _participation,
                      onChanged: (v) => setState(() => _participation = v),
                    ),
                    if (_isExamDay) ...[
                      const SizedBox(height: AppSpacing.md),
                      GradientMetricSlider(
                        label: 'Exam %',
                        icon: Icons.quiz_outlined,
                        value: _examScore,
                        onChanged: (v) => setState(() => _examScore = v),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Submit Feedback'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
