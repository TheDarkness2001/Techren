import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../domain/entities/person.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/identity_provider.dart';
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
                  label: Text(person.isStudent ? 'Edit student' : 'Edit teacher'),
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
                        ? 'Deactivate ${person.isStudent ? 'student' : 'teacher'}'
                        : 'Activate ${person.isStudent ? 'student' : 'teacher'}',
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
        ],
      );
    },
  );
}
