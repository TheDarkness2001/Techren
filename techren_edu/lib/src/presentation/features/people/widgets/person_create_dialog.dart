import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/app_form.dart';
import '../../../providers/identity_provider.dart';

Future<bool?> showPersonCreateDialog({
  required BuildContext context,
  required WidgetRef ref,
  required bool isTeacher,
}) {
  return showAppDialog<bool>(
    context: context,
    builder: (dialogContext) => _PersonCreateDialog(isTeacher: isTeacher),
  );
}

class _PersonCreateDialog extends ConsumerStatefulWidget {
  const _PersonCreateDialog({required this.isTeacher});

  final bool isTeacher;

  @override
  ConsumerState<_PersonCreateDialog> createState() => _PersonCreateDialogState();
}

class _PersonCreateDialogState extends ConsumerState<_PersonCreateDialog> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, email, and password (min 6 chars) are required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(identityApiProvider);
      if (widget.isTeacher) {
        await api.createTeacher(
          name: name,
          email: email,
          password: password,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        );
      } else {
        await api.createStudent(
          name: name,
          email: email,
          password: password,
          parentName: _parentNameController.text.trim().isEmpty ? null : _parentNameController.text.trim(),
          parentPhone: _parentPhoneController.text.trim().isEmpty ? null : _parentPhoneController.text.trim(),
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
    final isTeacher = widget.isTeacher;

    return AppDialog(
      title: isTeacher ? 'Add teacher' : 'Add student',
      icon: isTeacher ? Icons.person_add_outlined : Icons.school_outlined,
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
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (isTeacher)
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
                keyboardType: TextInputType.phone,
              )
            else ...[
              TextField(
                controller: _parentNameController,
                decoration: const InputDecoration(labelText: 'Parent name (optional)'),
                textCapitalization: TextCapitalization.words,
              ),
              TextField(
                controller: _parentPhoneController,
                decoration: const InputDecoration(labelText: 'Parent phone (optional)'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ],
        ),
      ),
      actions: [
        AppDialogActions.cancel(context, onPressed: _saving ? null : () => Navigator.pop(context, false)),
        AppDialogActions.confirm(
          context,
          label: 'Create',
          loading: _saving,
          onPressed: _saving ? null : _create,
        ),
      ],
    );
  }
}
