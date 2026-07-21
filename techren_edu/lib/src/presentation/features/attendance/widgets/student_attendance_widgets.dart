import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/attendance.dart';

enum AttendanceClassFilter { today, all }

/// Tabs + date picker bar (reference attendance UI).
class AttendanceControlBar extends StatelessWidget {
  const AttendanceControlBar({
    super.key,
    required this.filter,
    required this.selectedDate,
    required this.onFilterChanged,
    required this.onDateChanged,
  });

  final AttendanceClassFilter filter;
  final DateTime selectedDate;
  final ValueChanged<AttendanceClassFilter> onFilterChanged;
  final ValueChanged<DateTime> onDateChanged;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) onDateChanged(picked);
  }

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 640;
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    _FilterChip(
                      label: 'All Classes',
                      icon: Icons.menu_book_outlined,
                      selected: filter == AttendanceClassFilter.all,
                      onTap: () => onFilterChanged(AttendanceClassFilter.all),
                    ),
                    _FilterChip(
                      label: "Today's Classes",
                      icon: Icons.calendar_today_outlined,
                      selected: filter == AttendanceClassFilter.today,
                      onTap: () => onFilterChanged(AttendanceClassFilter.today),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(context),
                    icon: const Icon(Icons.calendar_month_outlined, size: 18),
                    label: Text('Date: ${_formatDate(selectedDate)}'),
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              _FilterChip(
                label: 'All Classes',
                icon: Icons.menu_book_outlined,
                selected: filter == AttendanceClassFilter.all,
                onTap: () => onFilterChanged(AttendanceClassFilter.all),
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: "Today's Classes",
                icon: Icons.calendar_today_outlined,
                selected: filter == AttendanceClassFilter.today,
                onTap: () => onFilterChanged(AttendanceClassFilter.today),
              ),
              const Spacer(),
              const Text('Date:', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _pickDate(context),
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: Text(_formatDate(selectedDate)),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
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
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: selected ? AppColors.primary : null),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 1),
        backgroundColor: selected ? AppColors.primaryContainer.withValues(alpha: 0.35) : Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      ),
    );
  }
}

/// Class card with left accent, info rows, and expandable student list.
class ClassAttendancePanel extends StatefulWidget {
  const ClassAttendancePanel({
    super.key,
    required this.session,
    required this.expanded,
    required this.onToggle,
    required this.onSaveStudent,
    this.onFeedback,
  });

  final TodayClassSession session;
  final bool expanded;
  final VoidCallback onToggle;
  final Future<void> Function(String studentId, String status, String? notes) onSaveStudent;
  final void Function(StudentAttendanceRow student)? onFeedback;

  @override
  State<ClassAttendancePanel> createState() => _ClassAttendancePanelState();
}

class _ClassAttendancePanelState extends State<ClassAttendancePanel> {
  @override
  Widget build(BuildContext context) {
    final schedule = widget.session.schedule;
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        levelLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                const SizedBox(height: AppSpacing.sm),
                _InfoLine(icon: Icons.menu_book_outlined, label: 'Subject', value: 'English'),
                _InfoLine(
                  icon: Icons.access_time,
                  label: 'Time',
                  value: '${schedule.startTime} - ${schedule.endTime}',
                ),
                _InfoLine(
                  icon: Icons.groups_outlined,
                  label: 'Students',
                  value: '${schedule.studentCount}',
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: widget.onToggle,
                    child: Text(widget.expanded ? 'Close' : 'Mark Attendance'),
                  ),
                ),
              ],
            ),
          ),
          if (widget.expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Students List', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  if (!widget.session.isWithinWindow)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        'Outside class window — admin override may apply.',
                        style: TextStyle(color: context.semantic.warning, fontSize: 12),
                      ),
                    ),
                  for (final student in widget.session.students)
                    StudentAttendanceCard(
                      student: student,
                      onSave: (status, notes) => widget.onSaveStudent(student.id, status, notes),
                      onFeedback: widget.onFeedback == null ? null : () => widget.onFeedback!(student),
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
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

/// Single student attendance row — status toggles, notes, save.
class StudentAttendanceCard extends StatefulWidget {
  const StudentAttendanceCard({
    super.key,
    required this.student,
    required this.onSave,
    this.onFeedback,
  });

  final StudentAttendanceRow student;
  final Future<void> Function(String status, String? notes) onSave;
  final VoidCallback? onFeedback;

  @override
  State<StudentAttendanceCard> createState() => _StudentAttendanceCardState();
}

class _StudentAttendanceCardState extends State<StudentAttendanceCard> {
  late String _status;
  final _notesController = TextEditingController();
  bool _saving = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _status = widget.student.attendanceStatus ?? 'present';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_status, _notesController.text.trim().isEmpty ? null : _notesController.text.trim());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.student.studentId != null ? '#${widget.student.studentId}' : '';

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppRadius.card,
          border: Border.all(color: _focused ? AppColors.primary : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.student.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                if (code.isNotEmpty)
                  Text(code, style: TextStyle(color: context.semantic.textMuted, fontSize: 12)),
                if (widget.onFeedback != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    icon: const Icon(Icons.rate_review_outlined, size: 18),
                    tooltip: 'Feedback',
                    onPressed: widget.onFeedback,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: _StatusButton(label: 'Present', value: 'present', groupValue: _status, onSelect: (v) => setState(() => _status = v))),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: _StatusButton(label: 'Absent', value: 'absent', groupValue: _status, onSelect: (v) => setState(() => _status = v))),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: _StatusButton(label: 'Late', value: 'late', groupValue: _status, onSelect: (v) => setState(() => _status = v))),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(hintText: 'Notes', isDense: true),
              onTap: () => setState(() => _focused = true),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: context.semantic.success,
                foregroundColor: Colors.white,
              ),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelect,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final selected = groupValue == value;
    final semantic = context.semantic;
    final scheme = Theme.of(context).colorScheme;

    final (Color accent, Color container, Color onContainer) = switch (value) {
      'present' => (semantic.success, semantic.successContainer, semantic.onSuccessContainer),
      'absent' => (semantic.danger, semantic.dangerContainer, semantic.onDangerContainer),
      'late' => (semantic.warning, semantic.warningContainer, semantic.onWarningContainer),
      _ => (scheme.primary, scheme.primaryContainer, scheme.onPrimaryContainer),
    };

    return OutlinedButton(
      onPressed: () => onSelect(value),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? onContainer : scheme.onSurfaceVariant,
        backgroundColor: selected ? container : semantic.surfaceContainer,
        side: BorderSide(color: selected ? accent : semantic.border),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
