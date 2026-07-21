import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/person_avatar.dart';
import '../../../../domain/entities/scheduling.dart';
import 'timetable_week_grid.dart';

class TimetableGrid extends StatelessWidget {
  const TimetableGrid({super.key, required this.data, this.title});

  final TimetableData data;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.pagePaddingWide,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        TimetableWeekGrid(data: data),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class ScheduleCard extends StatefulWidget {
  const ScheduleCard({super.key, required this.schedule});

  final ClassSchedule schedule;

  @override
  State<ScheduleCard> createState() => _ScheduleCardState();
}

class _ScheduleCardState extends State<ScheduleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    final schedule = widget.schedule;

    return Semantics(
      label: '${schedule.className} schedule. ${schedule.daysLabel}. ${schedule.startTime} to ${schedule.endTime}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.card,
            border: Border.all(
              color: _hovered ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 3))]
                : null,
          ),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.schedule_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        schedule.className,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Chip(
                      label: Text('${schedule.studentCount} students'),
                      visualDensity: VisualDensity.compact,
                      padding: AppSpacing.chipPadding,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _MetaRow(icon: Icons.access_time, label: '${schedule.startTime} – ${schedule.endTime}', muted: muted),
                const SizedBox(height: AppSpacing.xxs),
                _MetaRow(icon: Icons.calendar_today_outlined, label: schedule.daysLabel, muted: muted),
                if (schedule.teacherName != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  _MetaRow(icon: Icons.person_outline, label: schedule.teacherName!, muted: muted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GroupCard extends StatefulWidget {
  const GroupCard({
    super.key,
    required this.view,
    this.onEdit,
  });

  final UnifiedGroupView view;
  final VoidCallback? onEdit;

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    final warning = context.semantic.warning;
    final view = widget.view;
    final hasSchedule = view.schedule != null;
    final students = view.group.students;

    return Semantics(
      label: '${view.group.groupName} group. ${view.group.studentCount} students',
      button: widget.onEdit != null,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onEdit,
            borderRadius: AppRadius.card,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: AppRadius.card,
                border: Border.all(
                  color: _hovered ? AppColors.secondary.withValues(alpha: 0.35) : AppColors.border,
                ),
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                view.group.groupName,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (view.group.subjectName != null) ...[
                                const SizedBox(height: AppSpacing.micro),
                                Text(
                                  view.group.subjectName!,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.onEdit != null)
                          TextButton(onPressed: widget.onEdit, child: const Text('Edit')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: students.isEmpty
                              ? Text(
                                  'No students yet',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                                )
                              : _StudentAvatarStack(students: students, totalCount: view.group.studentCount),
                        ),
                        Text(
                          '${view.group.studentCount} ${view.group.studentCount == 1 ? 'student' : 'students'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (hasSchedule) ...[
                      _MetaRow(
                        icon: Icons.access_time,
                        label: '${view.schedule!.startTime} – ${view.schedule!.endTime}',
                        muted: muted,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      _MetaRow(icon: Icons.calendar_today_outlined, label: view.schedule!.daysLabel, muted: muted),
                      if (view.schedule!.teacherName != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        _MetaRow(icon: Icons.person_outline, label: view.schedule!.teacherName!, muted: muted),
                      ],
                    ] else
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: warning),
                          const SizedBox(width: AppSpacing.xxs),
                          Text('No schedule linked', style: TextStyle(color: warning, fontSize: 13)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentAvatarStack extends StatelessWidget {
  const _StudentAvatarStack({required this.students, required this.totalCount});

  final List<ExamGroupMember> students;
  final int totalCount;

  static const _maxVisible = 5;
  static const _size = 28.0;
  static const _overlap = 10.0;

  @override
  Widget build(BuildContext context) {
    final visible = students.take(_maxVisible).toList();
    final remaining = totalCount > visible.length ? totalCount - visible.length : 0;
    final width = _size + (visible.length - 1 + (remaining > 0 ? 1 : 0)).clamp(0, 100) * (_size - _overlap);

    return SizedBox(
      height: _size,
      width: width.clamp(_size, 220).toDouble(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * (_size - _overlap),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                ),
                child: PersonAvatar(
                  name: visible[i].name,
                  profileImage: visible[i].profileImage,
                  radius: (_size / 2) - 1,
                  isStudent: true,
                ),
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: visible.length * (_size - _overlap),
              child: Container(
                width: _size,
                height: _size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.surface, width: 2),
                ),
                child: Text(
                  '+$remaining',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label, required this.muted});

  final IconData icon;
  final String label;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: muted),
        const SizedBox(width: AppSpacing.xxs),
        Expanded(child: Text(label, style: TextStyle(color: muted, fontSize: 13))),
      ],
    );
  }
}
