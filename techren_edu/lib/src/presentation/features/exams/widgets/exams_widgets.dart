import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../domain/entities/finance.dart';
import '../../../../domain/entities/scheduling.dart';
import '../../../providers/finance_provider.dart';
import '../../../providers/scheduling_provider.dart';

/// Subtitle + Archived / Add New Exam actions (reference exams header).
class ExamsPageHeader extends StatelessWidget {
  const ExamsPageHeader({
    super.key,
    required this.showArchived,
    required this.onToggleArchived,
    required this.onAddExam,
  });

  final bool showArchived;
  final VoidCallback onToggleArchived;
  final VoidCallback onAddExam;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 640;
        final actions = Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.end,
          children: [
            FilledButton.icon(
              onPressed: onToggleArchived,
              icon: const Icon(Icons.inventory_2_outlined, size: 18),
              label: Text(showArchived ? 'Active Exams' : 'Archived'),
              style: FilledButton.styleFrom(
                backgroundColor: showArchived ? AppColors.primary : AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
            ),
            FilledButton.icon(
              onPressed: onAddExam,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New Exam'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
            ),
          ],
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Manage Exams',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: AppSpacing.md),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Manage Exams',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).hintColor),
              ),
            ),
            actions,
          ],
        );
      },
    );
  }
}

/// Reference empty state — centered card with CTA.
class ExamsEmptyStateCard extends StatelessWidget {
  const ExamsEmptyStateCard({
    super.key,
    required this.showArchived,
    required this.onAddExam,
  });

  final bool showArchived;
  final VoidCallback onAddExam;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📝', style: TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.md),
          Text(
            showArchived ? 'No archived exams' : 'No exams found for your classes.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            showArchived ? 'Completed exams will appear here once archived.' : 'Start by creating your first exam',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.semantic.textMuted),
            textAlign: TextAlign.center,
          ),
          if (!showArchived) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onAddExam,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New Exam'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Exam summary card for the roster grid.
class ExamManagementCard extends StatelessWidget {
  const ExamManagementCard({
    super.key,
    required this.exam,
    required this.onTap,
  });

  final ExamEntry exam;
  final VoidCallback onTap;

  Color _statusColor() {
    return switch (exam.status) {
      'completed' || 'archived' => AppColors.success,
      'ongoing' => AppColors.warning,
      'cancelled' => AppColors.danger,
      _ => AppColors.info,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = '${exam.examDate.toLocal().toString().split(' ').first} · ${exam.startTime}';

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(color: context.semantic.border),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exam.examName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusBadge(label: exam.status, color: _statusColor()),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(icon: Icons.menu_book_outlined, label: 'Subject', value: exam.subject),
              _InfoRow(icon: Icons.class_outlined, label: 'Class', value: exam.className),
              _InfoRow(icon: Icons.calendar_today_outlined, label: 'Date', value: dateLabel),
              _InfoRow(
                icon: Icons.grade_outlined,
                label: 'Marks',
                value: '${exam.passingMarks}/${exam.totalMarks} to pass',
              ),
              if (exam.teacherName != null)
                _InfoRow(icon: Icons.person_outline, label: 'Teacher', value: exam.teacherName!),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${exam.results.length} student${exam.results.length == 1 ? '' : 's'} enrolled',
                style: TextStyle(color: context.semantic.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          Expanded(child: Text(value, style: TextStyle(color: context.semantic.textMuted, fontSize: 13))),
        ],
      ),
    );
  }
}

Future<ExamEntry?> showCreateExamDialog(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final groups = await ref.read(examGroupsProvider.future);
  if (!context.mounted) return null;
  if (groups.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('Create a group first under Groups')));
    return null;
  }

  ExamGroup? selected = groups.first;
  final nameCtrl = TextEditingController(text: 'Mid-Term Exam');
  final totalCtrl = TextEditingController(text: '100');
  final passCtrl = TextEditingController(text: '40');

  return showAppDialog<ExamEntry>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AppDialog(
        title: 'Add New Exam',
        icon: Icons.quiz_outlined,
        content: SingleChildScrollView(
          child: AppFormColumn(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Exam name')),
              DropdownButtonFormField<ExamGroup>(
                value: selected,
                decoration: const InputDecoration(labelText: 'Group'),
                items: groups
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text('${g.groupName} (${g.studentCount} students)'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selected = v),
              ),
              if (selected != null)
                Text(
                  selected!.studentCount == 0
                      ? 'This group has no students yet. Add students to the group first.'
                      : 'Students in this group will be enrolled so you can enter marks right away.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              TextField(
                controller: totalCtrl,
                decoration: const InputDecoration(labelText: 'Total marks'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: passCtrl,
                decoration: const InputDecoration(labelText: 'Passing marks'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context)),
          AppDialogActions.confirm(
            context,
            label: 'Create',
            onPressed: () async {
              if (selected == null) return;
              if (selected!.studentCount == 0) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Add students to the group before creating the exam')),
                );
                return;
              }
              try {
                final exam = await ref.read(financeApiProvider).createExam({
                  'examName': nameCtrl.text.trim().isEmpty ? 'Mid-Term Exam' : nameCtrl.text.trim(),
                  'subject': selected!.subjectName ?? selected!.groupName,
                  'class': selected!.groupName,
                  'subjectGroup': selected!.id,
                  if (selected!.linkedScheduleId != null) 'scheduleId': selected!.linkedScheduleId,
                  'examDate': DateTime.now().toIso8601String(),
                  'startTime': '09:00',
                  'duration': 90,
                  'totalMarks': int.tryParse(totalCtrl.text) ?? 100,
                  'passingMarks': int.tryParse(passCtrl.text) ?? 40,
                });
                if (context.mounted) Navigator.pop(context, exam);
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
          ),
        ],
      ),
    ),
  );
}

void showExamDetailSheet(BuildContext context, WidgetRef ref, ExamEntry exam, ExamsQuery query) {
  showAppBottomSheet<void>(
    context: context,
    initialChildSize: 0.6,
    minChildSize: 0.35,
    maxChildSize: 0.92,
    builder: (context) => _ExamDetailSheet(
      exam: exam,
      query: query,
    ),
  );
}

class _ExamDetailSheet extends ConsumerStatefulWidget {
  const _ExamDetailSheet({
    required this.exam,
    required this.query,
  });

  final ExamEntry exam;
  final ExamsQuery query;

  @override
  ConsumerState<_ExamDetailSheet> createState() => _ExamDetailSheetState();
}

class _ExamDetailSheetState extends ConsumerState<_ExamDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;

    return AppBottomSheet(
      title: exam.examName,
      subtitle: '${exam.subject} · ${exam.className}',
      children: [
        Text('Results', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        if (exam.results.isEmpty)
          Text('No students enrolled yet.', style: TextStyle(color: context.semantic.textMuted))
        else
          ...exam.results.map(
            (result) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(result.studentName ?? result.studentCode ?? 'Student'),
              subtitle: Text('${result.marksObtained}/${exam.totalMarks} ${result.grade}'),
              trailing: result.passed
                  ? const Icon(Icons.check_circle, color: AppColors.success)
                  : const Icon(Icons.cancel, color: AppColors.danger),
              onTap: () => _enterMarks(result),
            ),
          ),
      ],
    );
  }

  Future<void> _enterMarks(ExamResult result) async {
    var marks = result.marksObtained.toDouble();
    final saved = await showAppDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AppDialog(
          title: 'Marks — ${result.studentName ?? ''}',
          icon: Icons.grade_outlined,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: marks,
                min: 0,
                max: widget.exam.totalMarks.toDouble(),
                divisions: widget.exam.totalMarks,
                label: marks.round().toString(),
                onChanged: (v) => setState(() => marks = v),
              ),
              Text('${marks.round()} / ${widget.exam.totalMarks}'),
            ],
          ),
          actions: [
            AppDialogActions.cancel(context, onPressed: () => Navigator.pop(context)),
            AppDialogActions.confirm(
              context,
              label: 'Save',
              onPressed: () async {
                await ref.read(financeApiProvider).updateExamResult(
                      examId: widget.exam.id,
                      studentId: result.studentId,
                      marksObtained: marks.round(),
                    );
                if (context.mounted) Navigator.pop(context, true);
              },
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      ref.invalidate(examsProvider(widget.query));
      Navigator.pop(context);
      showExamDetailSheet(context, ref, widget.exam, widget.query);
    }
  }
}
