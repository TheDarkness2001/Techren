import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/scheduling.dart';

const _dayFullNames = {
  'Mon': 'Monday',
  'Tue': 'Tuesday',
  'Wed': 'Wednesday',
  'Thu': 'Thursday',
  'Fri': 'Friday',
  'Sat': 'Saturday',
  'Sun': 'Sunday',
};

const _timeColWidth = 76.0;
const _minDayColWidth = 112.0;
const _dividerWidth = 1.0;

/// Weekly timetable grid — days across top, hourly rows, fills available width.
class TimetableWeekGrid extends StatelessWidget {
  const TimetableWeekGrid({
    super.key,
    required this.data,
    this.startHour = 7,
    this.endHour = 18,
    this.weekStart,
  });

  final TimetableData data;
  final int startHour;
  final int endHour;
  final DateTime? weekStart;

  DateTime get _monday {
    final anchor = weekStart ?? DateTime.now();
    return DateTime(anchor.year, anchor.month, anchor.day).subtract(Duration(days: anchor.weekday - 1));
  }

  List<String> get _timeSlots => [
        for (var hour = startHour; hour <= endHour; hour++) '${hour.toString().padLeft(2, '0')}:00',
      ];

  TimetableEntry? _entryForSlot(String day, String slot) {
    final slotHour = _hourFromTime(slot);
    final entries = data.grid[day] ?? [];
    for (final entry in entries) {
      if (_hourFromTime(entry.startTime) == slotHour) return entry;
    }
    return null;
  }

  static int _hourFromTime(String time) {
    final parts = time.split(':');
    return int.tryParse(parts.first) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    final border = context.semantic.border;
    final monday = _monday;
    final dayCount = TimetableData.days.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = _timeColWidth + dayCount * (_minDayColWidth + _dividerWidth);
        final tableWidth = math.max(
          constraints.maxWidth.isFinite ? constraints.maxWidth : minWidth,
          minWidth,
        );
        final dayWidth = (tableWidth - _timeColWidth - dayCount * _dividerWidth) / dayCount;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: border),
            boxShadow: AppShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  _HeaderRow(monday: monday, dayWidth: dayWidth, border: border),
                  for (final slot in _timeSlots)
                    _TimeRow(
                      slot: slot,
                      muted: muted,
                      border: border,
                      dayWidth: dayWidth,
                      entries: {
                        for (final day in TimetableData.days) day: _entryForSlot(day, slot),
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.monday,
    required this.dayWidth,
    required this.border,
  });

  final DateTime monday;
  final double dayWidth;
  final Color border;

  Color _dayColor(String day) {
    if (day == 'Sat') return const Color(0xFF2563EB);
    if (day == 'Sun') return const Color(0xFFDC2626);
    return AppColors.textPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _timeColWidth,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Time',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          for (var i = 0; i < TimetableData.days.length; i++) ...[
            Container(width: _dividerWidth, height: 60, color: border),
            SizedBox(
              width: dayWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
                child: Column(
                  children: [
                    Text(
                      _dayFullNames[TimetableData.days[i]]!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _dayColor(TimetableData.days[i]),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.micro),
                    Text(
                      _formatDate(monday.add(Duration(days: i))),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day} ${_monthShort(date.month)}';

  String _monthShort(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.slot,
    required this.muted,
    required this.border,
    required this.dayWidth,
    required this.entries,
  });

  final String slot;
  final Color muted;
  final Color border;
  final double dayWidth;
  final Map<String, TimetableEntry?> entries;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: _timeColWidth,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(slot, style: TextStyle(fontSize: 12, color: muted)),
              ),
            ),
            for (final day in TimetableData.days) ...[
              Container(width: _dividerWidth, color: border),
              SizedBox(
                width: dayWidth,
                height: 64,
                child: _Cell(entry: entries[day]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.entry});

  final TimetableEntry? entry;

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();

    final title = (entry!.subject?.trim().isNotEmpty == true)
        ? entry!.subject!.trim()
        : entry!.className;
    final subtitle = (entry!.subject?.trim().isNotEmpty == true &&
            entry!.className.trim().isNotEmpty &&
            entry!.className.trim().toLowerCase() != entry!.subject!.trim().toLowerCase())
        ? entry!.className.trim()
        : null;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: context.semantic.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (entry!.endTime.isNotEmpty)
            Text(
              '${entry!.startTime} – ${entry!.endTime}',
              style: TextStyle(fontSize: 10, color: context.semantic.textMuted),
            ),
        ],
      ),
    );
  }
}

TimetableData filterTimetableForTeacher(TimetableData data, {String? teacherId, String? teacherName}) {
  if (teacherId == null && teacherName == null) return data;

  final filtered = <String, List<TimetableEntry>>{};
  var total = 0;
  for (final day in TimetableData.days) {
    final items = (data.grid[day] ?? []).where((entry) {
      if (teacherId != null) {
        final entryId = entry.teacherId;
        if (entryId != null && entryId == teacherId) return true;
      }
      if (teacherName != null && entry.teacherName != null) {
        return entry.teacherName!.toLowerCase() == teacherName.toLowerCase();
      }
      return false;
    }).toList();
    filtered[day] = items;
    total += items.length;
  }
  return TimetableData(role: data.role, grid: filtered, total: total);
}
