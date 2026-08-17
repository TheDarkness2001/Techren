import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/format_money.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../domain/entities/person.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/identity_provider.dart';
import '../../../providers/ielts_provider.dart';
import '../../../providers/settings_provider.dart';
import 'person_edit_dialog.dart';
import 'profile_photo_picker.dart';

Future<void> showPersonDetailSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Person person,
  required VoidCallback onChanged,
  bool canManageStatus = false,
}) {
  final user = ref.read(authProvider).user;
  final rolePerms = ref.read(platformSettingsProvider).valueOrNull?.rolePermissions[user?.role?.name] ?? {};
  final canManage = user?.hasPermission('canManageStudents', rolePerms) ?? false;

  return showAppBottomSheet<void>(
    context: context,
    initialChildSize: 0.78,
    minChildSize: 0.45,
    maxChildSize: 0.92,
    builder: (sheetContext) {
      final muted = sheetContext.semantic.textMuted;

      return AppBottomSheet(
        title: person.name,
        subtitle: person.isStudent
            ? (person.email ?? person.displayId ?? '')
            : '${person.role ?? 'staff'} · ${person.email ?? ''}',
        footer: AppBottomSheetActions(
          primary: canManage
              ? FilledButton.icon(
                  onPressed: () async {
                    final saved = await showPersonEditDialog(
                      context: sheetContext,
                      ref: ref,
                      person: person,
                    );
                    if (saved == true) {
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                      onChanged();
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(person.isStudent ? 'Edit student' : 'Edit staff'),
                )
              : null,
          secondary: canManageStatus
              ? OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    final api = ref.read(identityApiProvider);
                    final status = person.isActive ? 'inactive' : 'active';
                    if (person.isStudent) {
                      await api.setStudentStatus(person.id, status);
                    } else {
                      await api.setTeacherStatus(person.id, status);
                    }
                    onChanged();
                  },
                  child: Text(
                    person.isActive
                        ? 'Deactivate ${person.isStudent ? 'student' : 'staff'}'
                        : 'Activate ${person.isStudent ? 'student' : 'staff'}',
                  ),
                )
              : null,
        ),
        children: [
          Center(
            child: ProfilePhotoPicker(
              personId: person.id,
              name: person.name,
              profileImage: person.profileImage,
              isStudent: person.isStudent,
              isActive: person.isActive,
              radius: 56,
              canEdit: canManage,
              onUpdated: (_) => onChanged(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(child: AppSheetStatusChip(label: person.isActive ? 'Active' : 'Inactive', active: person.isActive)),
          if (person.isTeacher && person.phone != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Phone: ${person.phone}', style: Theme.of(sheetContext).textTheme.bodyMedium),
          ],
          if (person.isStudent && (person.parentName != null || person.parentPhone != null)) ...[
            const SizedBox(height: AppSpacing.md),
            if (person.parentName != null)
              Text('Parent: ${person.parentName}', style: Theme.of(sheetContext).textTheme.bodyMedium),
            if (person.parentPhone != null)
              Text(person.parentPhone!, style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(color: muted)),
          ],
          if (person.isStudent) ...[
            if (person.subjectFees.any((f) => f.amount > 0)) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final fee in person.subjectFees.where((f) => f.amount > 0))
                Text(
                  '${fee.subject}: ${formatUzs(fee.amount)} / month',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
              if (person.subjectFees.where((f) => f.amount > 0).length > 1)
                Text(
                  'Total: ${formatUzs(person.subjectFees.fold<double>(0, (s, f) => s + f.amount))} / month',
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
            ] else if ((person.coursePrice ?? 0) > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Course price: ${formatUzs(person.coursePrice!)} / month',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
            ],
          ],
          if (person.isStudent && (user?.isFounder ?? false)) ...[
            const SizedBox(height: AppSpacing.lg),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('IELTS Preparation access'),
              subtitle: Text(
                person.ieltsAccess == true ? 'Unlocked' : 'Locked',
                style: TextStyle(color: muted),
              ),
              value: person.ieltsAccess == true,
              onChanged: (enabled) async {
                await ref.read(ieltsApiProvider).setStudentAccess(person.id, enabled);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                onChanged();
              },
            ),
          ],
          if ((user?.isFounder ?? false) && person.role != 'founder') ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () async {
                final l10n = sheetContext.l10n;
                final ok = await showAppConfirmDialog(
                  context: sheetContext,
                  title: l10n.deletePerson,
                  message: person.isStudent
                      ? l10n.deleteStudentConfirm(person.name)
                      : l10n.deleteStaffConfirm(person.name),
                  confirmLabel: l10n.deletePerson,
                  destructive: true,
                );
                if (!ok) return;
                try {
                  final api = ref.read(identityApiProvider);
                  if (person.isStudent) {
                    await api.deleteStudent(person.id);
                  } else {
                    await api.deleteTeacher(person.id);
                  }
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  onChanged();
                } catch (e) {
                  if (sheetContext.mounted) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              icon: const Icon(Icons.delete_forever_outlined),
              label: Text(sheetContext.l10n.deletePerson),
            ),
          ],
        ],
      );
    },
  );
}
