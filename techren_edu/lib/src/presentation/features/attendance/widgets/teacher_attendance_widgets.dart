import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/media_url.dart';
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

String formatTeacherAttendanceLongDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]}, ${_months[date.month - 1]} ${date.day}, ${date.year}';

String formatTeacherAttendanceShortDate(DateTime date) =>
    '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';

String teacherAttendanceApiDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Date + role filter bar for teacher attendance roster.
class TeacherAttendanceFilterBar extends StatelessWidget {
  const TeacherAttendanceFilterBar({
    super.key,
    required this.selectedDate,
    required this.selectedRole,
    required this.onDateChanged,
    required this.onRoleChanged,
  });

  final DateTime selectedDate;
  final String selectedRole;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String> onRoleChanged;

  static const roleOptions = <String, String>{
    'all': 'All',
    'manager': 'Manager',
    'teacher': 'Teacher',
  };

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
          final dateField = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Date:', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _pickDate(context),
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: Text(formatTeacherAttendanceShortDate(selectedDate)),
              ),
            ],
          );
          final roleField = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Role:', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: AppSpacing.sm),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedRole,
                  borderRadius: AppRadius.card,
                  items: [
                    for (final entry in roleOptions.entries)
                      DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                  ],
                  onChanged: (value) {
                    if (value != null) onRoleChanged(value);
                  },
                ),
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dateField,
                const SizedBox(height: AppSpacing.sm),
                roleField,
              ],
            );
          }

          return Row(
            children: [
              dateField,
              const Spacer(),
              roleField,
            ],
          );
        },
      ),
    );
  }
}

/// Teacher card — avatar, contact rows, status toggles, notes, save.
class TeacherAttendanceCard extends StatefulWidget {
  const TeacherAttendanceCard({
    super.key,
    required this.teacher,
    required this.onSave,
  });

  final TeacherRosterRow teacher;
  final Future<void> Function(String status, String? notes) onSave;

  @override
  State<TeacherAttendanceCard> createState() => _TeacherAttendanceCardState();
}

class _TeacherAttendanceCardState extends State<TeacherAttendanceCard> {
  late String _status;
  final _notesController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.teacher.dailyStatus ?? 'present';
    _notesController.text = widget.teacher.notes ?? '';
  }

  @override
  void didUpdateWidget(covariant TeacherAttendanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teacher.id != widget.teacher.id) {
      _status = widget.teacher.dailyStatus ?? 'present';
      _notesController.text = widget.teacher.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _status,
        _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacher = widget.teacher;
    final subjects = teacher.subjects.isEmpty ? '—' : teacher.subjects.join(', ');

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
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                _TeacherAvatar(name: teacher.name, profileImage: teacher.profileImage),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _RoleBadge(role: teacher.role),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                _ContactLine(icon: Icons.mail_outline, value: teacher.email ?? '—'),
                _ContactLine(icon: Icons.phone_outlined, value: teacher.phone ?? '—'),
                _ContactLine(icon: Icons.person_outline, value: subjects),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Status', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _TeacherStatusButton(
                        label: 'Present',
                        value: 'present',
                        groupValue: _status,
                        onSelect: (v) => setState(() => _status = v),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _TeacherStatusButton(
                        label: 'Absent',
                        value: 'absent',
                        groupValue: _status,
                        onSelect: (v) => setState(() => _status = v),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _TeacherStatusButton(
                        label: 'Late',
                        value: 'late',
                        groupValue: _status,
                        onSelect: (v) => setState(() => _status = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(hintText: 'Notes', isDense: true),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherAvatar extends StatelessWidget {
  const _TeacherAvatar({required this.name, this.profileImage});

  final String name;
  final String? profileImage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final imageUrl = resolveMediaUrl(profileImage);
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.primary, width: 2),
      ),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: scheme.primaryContainer,
        backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        child: imageUrl.isEmpty
            ? Text(
                initial,
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              )
            : null,
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({this.role});

  final String? role;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;

    final label = switch (role) {
      'founder' => 'Founder',
      'manager' => 'Manager',
      'teacher' => 'Teacher',
      _ => role ?? 'Staff',
    };

    final (bg, fg) = switch (role) {
      'founder' => isDark
          ? (semantic.successContainer, semantic.onSuccessContainer)
          : (const Color(0xFFD1FAE5), const Color(0xFF047857)),
      'manager' => isDark
          ? (scheme.secondaryContainer, scheme.onSecondaryContainer)
          : (const Color(0xFFEDE9FE), const Color(0xFF6D28D9)),
      'teacher' => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _ => isDark
          ? (semantic.surfaceContainer, scheme.onSurfaceVariant)
          : (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = context.semantic.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: muted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherStatusButton extends StatelessWidget {
  const _TeacherStatusButton({
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
