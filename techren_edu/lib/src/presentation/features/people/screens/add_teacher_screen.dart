import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/identity_provider.dart';
import '../../../providers/learning_provider.dart';
import '../../../providers/staff_branch_provider.dart';
import '../widgets/people_form_widgets.dart';

class AddTeacherScreen extends ConsumerStatefulWidget {
  const AddTeacherScreen({super.key, required this.prefix});

  final String prefix;

  @override
  ConsumerState<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends ConsumerState<AddTeacherScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _department = TextEditingController();

  String _role = 'teacher';
  String _status = 'active';
  String? _branchId;
  final Set<String> _subjects = {};
  bool _obscure = true;
  bool _saving = false;
  Uint8List? _photoBytes;
  String? _photoName;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _department.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _photoBytes = file.bytes;
      _photoName = file.name;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if (name.isEmpty || email.isEmpty || password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, email, and password (min 8 chars) are required')),
      );
      return;
    }
    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one subject')),
      );
      return;
    }

    final user = ref.read(authProvider).user;
    final branchFilter = ref.read(staffBranchFilterProvider);
    final branchId = user?.isFounder == true
        ? (_branchId ?? (branchFilter == 'all' ? null : branchFilter))
        : user?.branchId;

    if (user?.isFounder == true && (branchId == null || branchId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a branch')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(identityApiProvider);
      final created = await api.createTeacher(
        name: name,
        email: email,
        password: password,
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        role: _role,
        subjects: _subjects.toList(),
        department: _department.text.trim().isEmpty ? null : _department.text.trim(),
        status: _status,
        branchId: branchId,
      );
      if (_photoBytes != null && _photoName != null) {
        await api.uploadTeacherPhoto(created.id, bytes: _photoBytes, fileName: _photoName!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Teacher ${created.displayId ?? created.name} created')),
      );
      context.go('${widget.prefix}/people/teachers');
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
    final user = ref.watch(authProvider).user;
    final canPickRole = user?.isFounder == true || user?.isManager == true || user?.isAdmin == true;
    final branchesAsync = ref.watch(branchesProvider(const PageMeta(limit: 100)));
    final subjectsAsync = ref.watch(learningSubjectsProvider((page: 1, search: '')));
    final subjectNames = subjectsAsync.valueOrNull?.items.map((s) => s.name).toList() ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Teacher'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('${widget.prefix}/people/teachers'),
        ),
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          PeopleFormSection(
            title: 'Staff details',
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.photo_outlined),
                    label: Text(_photoName ?? 'Choose photo'),
                  ),
                ),
              ],
            ),
          ),
          PeopleFormSection(
            title: 'Subjects *',
            subtitle: 'Tap subjects to assign (not comma-separated)',
            child: subjectsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(e.toString()),
              data: (_) {
                if (subjectNames.isEmpty) {
                  return TextField(
                    decoration: const InputDecoration(
                      labelText: 'Subjects (comma separated)',
                      hintText: 'e.g. English, IT, Computer',
                    ),
                    onChanged: (v) {
                      _subjects
                        ..clear()
                        ..addAll(
                          v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
                        );
                    },
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final name in subjectNames)
                      FilterChip(
                        label: Text(name),
                        selected: _subjects.contains(name),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _subjects.add(name);
                          } else {
                            _subjects.remove(name);
                          }
                        }),
                      ),
                  ],
                );
              },
            ),
          ),
          PeopleFormSection(
            title: 'Role & branch',
            child: Column(
              children: [
                PeopleFormRow(
                  left: TextField(
                    controller: _department,
                    decoration: const InputDecoration(labelText: 'Department'),
                  ),
                  right: TextField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PeopleFormRow(
                  left: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                      DropdownMenuItem(value: 'on-leave', child: Text('On leave')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'active'),
                  ),
                  right: DropdownButtonFormField<String>(
                    value: _role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: [
                      const DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                      if (canPickRole) ...[
                        const DropdownMenuItem(value: 'manager', child: Text('Manager')),
                        const DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        const DropdownMenuItem(value: 'sales', child: Text('Sales')),
                        const DropdownMenuItem(value: 'receptionist', child: Text('Receptionist')),
                      ],
                    ],
                    onChanged: (v) => setState(() => _role = v ?? 'teacher'),
                  ),
                ),
                if (user?.isFounder == true) ...[
                  const SizedBox(height: AppSpacing.md),
                  branchesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(e.toString()),
                    data: (page) => DropdownButtonFormField<String>(
                      value: _branchId,
                      decoration: const InputDecoration(labelText: 'Branch *'),
                      items: [
                        for (final b in page.items)
                          DropdownMenuItem(value: b.id, child: Text(b.name)),
                      ],
                      onChanged: (v) => setState(() => _branchId = v),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _saving ? null : () => context.go('${widget.prefix}/people/teachers'),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
