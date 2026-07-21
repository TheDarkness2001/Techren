import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../../domain/entities/person.dart';
import '../../../providers/identity_provider.dart';

Future<bool?> showPersonEditDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Person person,
}) {
  return showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => _PersonEditDialog(person: person),
  );
}

class _PersonEditDialog extends ConsumerStatefulWidget {
  const _PersonEditDialog({required this.person});

  final Person person;

  @override
  ConsumerState<_PersonEditDialog> createState() => _PersonEditDialogState();
}

class _PersonEditDialogState extends ConsumerState<_PersonEditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _parentNameController;
  late final TextEditingController _parentPhoneController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final person = widget.person;
    _nameController = TextEditingController(text: person.name);
    _emailController = TextEditingController(text: person.email ?? '');
    _parentNameController = TextEditingController(text: person.parentName ?? '');
    _parentPhoneController = TextEditingController(text: person.parentPhone ?? '');
    _phoneController = TextEditingController(text: person.phone ?? '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email are required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(identityApiProvider);
      final password = _passwordController.text;
      if (widget.person.isStudent) {
        await api.updateStudent(
          id: widget.person.id,
          name: name,
          email: email,
          parentName: _parentNameController.text.trim(),
          parentPhone: _parentPhoneController.text.trim(),
          password: password.isEmpty ? null : password,
        );
      } else {
        await api.updateTeacher(
          id: widget.person.id,
          name: name,
          email: email,
          phone: _phoneController.text.trim(),
          password: password.isEmpty ? null : password,
        );
      }
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
    final isStudent = widget.person.isStudent;

    return AppDialog(
      title: isStudent ? 'Edit student' : 'Edit teacher',
      icon: Icons.edit_outlined,
      content: SingleChildScrollView(
        child: AppFormColumn(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textCapitalization: TextCapitalization.words,
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            if (isStudent) ...[
              TextField(
                controller: _parentNameController,
                decoration: const InputDecoration(labelText: 'Parent name'),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: _parentPhoneController,
                decoration: const InputDecoration(labelText: 'Parent phone'),
                keyboardType: TextInputType.phone,
              ),
            ] else
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'New password',
                helperText: 'Leave blank to keep current password',
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        AppDialogActions.cancel(context, onPressed: _saving ? null : () => Navigator.pop(context, false)),
        AppDialogActions.confirm(
          context,
          label: 'Save',
          loading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
