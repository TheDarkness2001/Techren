import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../../domain/entities/person.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/identity_provider.dart';
import '../../../providers/learning_provider.dart';
import '../../../providers/staff_branch_provider.dart';
import '../widgets/people_form_widgets.dart';

class AddStudentScreen extends ConsumerStatefulWidget {
  const AddStudentScreen({super.key, required this.prefix});

  final String prefix;

  @override
  ConsumerState<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends ConsumerState<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _studentId = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _parentName = TextEditingController();
  final _parentPhone = TextEditingController();
  final _parentUsername = TextEditingController();
  final _parentPassword = TextEditingController();
  final _address = TextEditingController();
  final _medical = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _studentIdFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _branchFocus = FocusNode();
  final _parentNameFocus = FocusNode();
  final _parentUsernameFocus = FocusNode();
  final _parentPasswordFocus = FocusNode();

  DateTime? _dob;
  String _gender = '';
  String _bloodGroup = '';
  String _status = 'active';
  String _parentRelation = 'mother';
  String? _branchId;
  bool _obscure = true;
  bool _obscureParentPassword = true;
  bool _saving = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  final List<({TextEditingController subject, TextEditingController amount})> _fees = [
    (subject: TextEditingController(), amount: TextEditingController()),
  ];

  Uint8List? _photoBytes;
  String? _photoName;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _studentId.dispose();
    _phone.dispose();
    _password.dispose();
    _parentName.dispose();
    _parentPhone.dispose();
    _parentUsername.dispose();
    _parentPassword.dispose();
    _address.dispose();
    _medical.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _studentIdFocus.dispose();
    _passwordFocus.dispose();
    _branchFocus.dispose();
    _parentNameFocus.dispose();
    _parentUsernameFocus.dispose();
    _parentPasswordFocus.dispose();
    for (final row in _fees) {
      row.subject.dispose();
      row.amount.dispose();
    }
    super.dispose();
  }

  bool get _parentPortalStarted =>
      _parentUsername.text.trim().isNotEmpty ||
      _parentPassword.text.isNotEmpty ||
      _parentName.text.trim().isNotEmpty;

  void _focusFirstInvalid() {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    final user = ref.read(authProvider).user;
    final needsBranch = user?.isFounder == true && (_branchId == null || _branchId!.isEmpty);

    FocusNode? target;
    if (name.isEmpty) {
      target = _nameFocus;
    } else if (email.isEmpty || !email.contains('@')) {
      target = _emailFocus;
    } else if (_studentId.text.trim().isEmpty) {
      target = _studentIdFocus;
    } else if (needsBranch) {
      target = _branchFocus;
    } else if (password.length < 8) {
      target = _passwordFocus;
    } else if (_parentPortalStarted) {
      if (_parentName.text.trim().isEmpty) {
        target = _parentNameFocus;
      } else if (_parentUsername.text.trim().isEmpty) {
        target = _parentUsernameFocus;
      } else if (_parentPassword.text.length < 4) {
        target = _parentPasswordFocus;
      }
    }
    target?.requestFocus();
  }

  Future<void> _pickPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    setState(() {
      _photoBytes = file.bytes;
      _photoName = file.name;
    });
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 12),
      firstDate: DateTime(1980),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null) return;
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    if (!form.validate()) {
      _focusFirstInvalid();
      return;
    }

    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    final fees = <SubjectFee>[];
    for (final row in _fees) {
      final subject = row.subject.text.trim();
      if (subject.isEmpty) continue;
      final amount = double.tryParse(row.amount.text.trim()) ?? 0;
      fees.add(SubjectFee(subject: subject, amount: amount));
    }
    final coursePrice = fees.fold<double>(0, (s, f) => s + f.amount);

    final user = ref.read(authProvider).user;
    final branchFilter = ref.read(staffBranchFilterProvider);
    final branchId = user?.isFounder == true
        ? (_branchId ?? (branchFilter == 'all' ? null : branchFilter))
        : user?.branchId;

    setState(() => _saving = true);
    try {
      final api = ref.read(identityApiProvider);
      final parentUsername = _parentUsername.text.trim();
      final parentPassword = _parentPassword.text;
      Map<String, dynamic>? parentAccount;
      if (_parentPortalStarted) {
        parentAccount = {
          'name': _parentName.text.trim(),
          'username': parentUsername,
          'password': parentPassword,
          'relation': _parentRelation,
          'phone': _parentPhone.text.trim(),
        };
      }

      final created = await api.createStudent(
        name: name,
        email: email,
        password: password,
        studentId: _studentId.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        parentName: _parentName.text.trim().isEmpty ? null : _parentName.text.trim(),
        parentPhone: _parentPhone.text.trim().isEmpty ? null : _parentPhone.text.trim(),
        parentAccount: parentAccount,
        coursePrice: coursePrice > 0 ? coursePrice : null,
        subjectFees: fees.isEmpty ? null : fees,
        dateOfBirth: _dob,
        gender: _gender.isEmpty ? null : _gender,
        bloodGroup: _bloodGroup.isEmpty ? null : _bloodGroup,
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        medicalConditions: _medical.text.trim().isEmpty ? null : _medical.text.trim(),
        status: _status,
        branchId: branchId,
      );

      if (_photoBytes != null && _photoName != null) {
        await api.uploadStudentPhoto(
          created.id,
          bytes: _photoBytes,
          fileName: _photoName!,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Student ${created.displayId ?? created.name} created')),
      );
      context.go('${widget.prefix}/people/students');
    } on DioException catch (e) {
      if (mounted) {
        final msg = ref.read(dioClientProvider).mapError(e).message;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
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
    final branchesAsync = ref.watch(branchesProvider(const PageMeta(limit: 100)));
    final subjectsAsync = ref.watch(learningSubjectsProvider((page: 1, search: '')));
    final subjectNames = subjectsAsync.valueOrNull?.items.map((s) => s.name).toList() ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Student'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('${widget.prefix}/people/students'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton.tonal(
              onPressed: () => context.go('${widget.prefix}/people/students'),
              child: const Text('← Back'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: [
          PeopleFormSection(
            title: 'Name Actions',
            child: Column(
              children: [
                PeopleFormRow(
                  left: TextFormField(
                    controller: _name,
                    focusNode: _nameFocus,
                    decoration: const InputDecoration(labelText: 'Full name *'),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Full name is required';
                      return null;
                    },
                  ),
                  right: TextFormField(
                    controller: _studentId,
                    focusNode: _studentIdFocus,
                    decoration: const InputDecoration(
                      labelText: 'Student ID *',
                      hintText: 'e.g. #0045 or STU-2026-01',
                      helperText: 'You choose this ID — shown in People lists',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Student ID is required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PeopleFormRow(
                  left: TextFormField(
                    controller: _email,
                    focusNode: _emailFocus,
                    decoration: const InputDecoration(labelText: 'Email *'),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Email is required';
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  right: TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PeopleFormRow(
                  left: user?.isFounder == true
                      ? branchesAsync.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text(e.toString()),
                          data: (page) => DropdownButtonFormField<String>(
                            value: _branchId,
                            focusNode: _branchFocus,
                            decoration: const InputDecoration(labelText: 'Branch *'),
                            items: [
                              for (final b in page.items)
                                DropdownMenuItem(value: b.id, child: Text(b.name)),
                            ],
                            onChanged: (v) => setState(() => _branchId = v),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Select a branch';
                              return null;
                            },
                          ),
                        )
                      : DropdownButtonFormField<String>(
                          value: _status,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('Active')),
                            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                            DropdownMenuItem(value: 'graduated', child: Text('Graduated')),
                          ],
                          onChanged: (v) => setState(() => _status = v ?? 'active'),
                        ),
                  right: user?.isFounder == true
                      ? DropdownButtonFormField<String>(
                          value: _status,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('Active')),
                            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                            DropdownMenuItem(value: 'graduated', child: Text('Graduated')),
                          ],
                          onChanged: (v) => setState(() => _status = v ?? 'active'),
                        )
                      : const SizedBox.shrink(),
                ),
                if (subjectNames.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Subjects: ${subjectNames.join(', ')}',
                    style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          PeopleFormSection(
            title: 'Profile',
            child: Column(
              children: [
                PeopleFormRow(
                  left: InkWell(
                    onTap: _pickDob,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _dob == null
                            ? 'mm/dd/yyyy'
                            : '${_dob!.month.toString().padLeft(2, '0')}/'
                                '${_dob!.day.toString().padLeft(2, '0')}/'
                                '${_dob!.year}',
                        style: TextStyle(
                          color: _dob == null ? Theme.of(context).hintColor : null,
                        ),
                      ),
                    ),
                  ),
                  right: DropdownButtonFormField<String>(
                    value: _gender.isEmpty ? null : _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _gender = v ?? ''),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PeopleFormRow(
                  left: DropdownButtonFormField<String>(
                    value: _bloodGroup.isEmpty ? null : _bloodGroup,
                    decoration: const InputDecoration(labelText: 'Blood Group'),
                    items: [
                      for (final g in ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'])
                        DropdownMenuItem(value: g, child: Text(g)),
                    ],
                    onChanged: (v) => setState(() => _bloodGroup = v ?? ''),
                  ),
                  right: const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _address,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _medical,
                  decoration: const InputDecoration(
                    labelText: 'Medical Conditions',
                    hintText: 'No data found',
                  ),
                  maxLines: 2,
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
                Text(
                  'Photo: JPG, PNG, GIF — Max 5MB',
                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                ),
              ],
            ),
          ),
          PeopleFormSection(
            title: 'Student Credentials',
            child: Column(
              children: [
                TextFormField(
                  controller: _password,
                  focusNode: _passwordFocus,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Student password *',
                    helperText: 'Student logs in with email + this password. Min 8 characters.',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
              ],
            ),
          ),
          PeopleFormSection(
            title: 'Parent portal login',
            subtitle: 'Optional. Username + password for the parent app (not the student email).',
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _parentRelation,
                  decoration: const InputDecoration(labelText: 'Relation'),
                  items: const [
                    DropdownMenuItem(value: 'mother', child: Text('Mother')),
                    DropdownMenuItem(value: 'father', child: Text('Father')),
                    DropdownMenuItem(value: 'guardian', child: Text('Guardian')),
                  ],
                  onChanged: (v) => setState(() => _parentRelation = v ?? 'mother'),
                ),
                const SizedBox(height: AppSpacing.md),
                PeopleFormRow(
                  left: TextFormField(
                    controller: _parentName,
                    focusNode: _parentNameFocus,
                    decoration: const InputDecoration(labelText: 'Parent name'),
                    onChanged: (_) {
                      if (_autovalidateMode != AutovalidateMode.disabled) setState(() {});
                    },
                    validator: (v) {
                      if (!_parentPortalStarted) return null;
                      if (v == null || v.trim().isEmpty) return 'Parent name is required';
                      return null;
                    },
                  ),
                  right: TextFormField(
                    controller: _parentPhone,
                    decoration: const InputDecoration(labelText: 'Parent phone'),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PeopleFormRow(
                  left: TextFormField(
                    controller: _parentUsername,
                    focusNode: _parentUsernameFocus,
                    decoration: const InputDecoration(
                      labelText: 'Parent username',
                      hintText: 'e.g. madina_mom',
                    ),
                    onChanged: (_) {
                      if (_autovalidateMode != AutovalidateMode.disabled) setState(() {});
                    },
                    validator: (v) {
                      if (!_parentPortalStarted) return null;
                      if (v == null || v.trim().isEmpty) return 'Parent username is required';
                      return null;
                    },
                  ),
                  right: TextFormField(
                    controller: _parentPassword,
                    focusNode: _parentPasswordFocus,
                    obscureText: _obscureParentPassword,
                    onChanged: (_) {
                      if (_autovalidateMode != AutovalidateMode.disabled) setState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Parent password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureParentPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscureParentPassword = !_obscureParentPassword),
                      ),
                    ),
                    validator: (v) {
                      if (!_parentPortalStarted) return null;
                      if (v == null || v.isEmpty) return 'Parent password is required';
                      if (v.length < 4) return 'Min 4 characters';
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          PeopleFormSection(
            title: 'Payments',
            subtitle: 'Subjects Amount',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _fees.length; i++) ...[
                  PeopleFormRow(
                    left: subjectNames.isEmpty
                        ? TextField(
                            controller: _fees[i].subject,
                            decoration: const InputDecoration(
                              labelText: 'Subject',
                              hintText: 'e.g.: Mathematics',
                            ),
                          )
                        : DropdownButtonFormField<String>(
                            value: _fees[i].subject.text.isEmpty ? null : _fees[i].subject.text,
                            decoration: const InputDecoration(labelText: 'Subject'),
                            items: [
                              for (final name in subjectNames)
                                DropdownMenuItem(value: name, child: Text(name)),
                            ],
                            onChanged: (v) {
                              _fees[i].subject.text = v ?? '';
                              setState(() {});
                            },
                          ),
                    right: TextField(
                      controller: _fees[i].amount,
                      decoration: const InputDecoration(
                        labelText: 'Amount (\$)',
                        hintText: 'e.g.: 150',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () => setState(() {
                      _fees.add((
                        subject: TextEditingController(),
                        amount: TextEditingController(),
                      ));
                    }),
                    icon: const Icon(Icons.add),
                    label: const Text('+ Add Subject'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _saving ? null : () => context.go('${widget.prefix}/people/students'),
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
                          : const Text('Add Student'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (subjectsAsync.isLoading) const LinearProgressIndicator(),
        ],
        ),
      ),
    );
  }
}
