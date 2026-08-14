import 'package:dio/dio.dart';
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
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _parentNameController;
  late final TextEditingController _parentPhoneController;
  late final TextEditingController _parentUsernameController;
  late final TextEditingController _parentPasswordController;
  late final TextEditingController _coursePriceController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _coursePriceFocus = FocusNode();
  final _parentNameFocus = FocusNode();
  final _parentUsernameFocus = FocusNode();
  final _parentPasswordFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late String _parentRelation;
  bool _obscurePassword = true;
  bool _obscureParentPassword = true;
  bool _saving = false;

  /// Server / client errors shown under specific fields (red).
  String? _nameError;
  String? _emailError;
  String? _coursePriceError;
  String? _parentNameError;
  String? _parentUsernameError;
  String? _parentPasswordError;
  String? _passwordError;

  bool get _hasExistingParent =>
      widget.person.parentAccount?.username?.trim().isNotEmpty == true;

  /// User is starting / editing parent portal credentials (not just legacy parent name).
  bool get _parentPortalTouched {
    final username = _parentUsernameController.text.trim();
    final password = _parentPasswordController.text;
    if (_hasExistingParent) return true;
    return username.isNotEmpty || password.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    final person = widget.person;
    final parentAcct = person.parentAccount;
    _nameController = TextEditingController(text: person.name);
    _emailController = TextEditingController(text: person.email ?? '');
    _parentNameController = TextEditingController(text: parentAcct?.name ?? person.parentName ?? '');
    _parentPhoneController = TextEditingController(text: parentAcct?.phone ?? person.parentPhone ?? '');
    _parentUsernameController = TextEditingController(text: parentAcct?.username ?? '');
    _parentPasswordController = TextEditingController();
    _parentRelation = parentAcct?.relation ?? 'mother';
    _coursePriceController = TextEditingController(
      text: (person.coursePrice != null && person.coursePrice! > 0)
          ? person.coursePrice!.toStringAsFixed(
              person.coursePrice! == person.coursePrice!.roundToDouble() ? 0 : 2,
            )
          : '',
    );
    _phoneController = TextEditingController(text: person.phone ?? '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentUsernameController.dispose();
    _parentPasswordController.dispose();
    _coursePriceController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _coursePriceFocus.dispose();
    _parentNameFocus.dispose();
    _parentUsernameFocus.dispose();
    _parentPasswordFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _clearFieldErrors() {
    _nameError = null;
    _emailError = null;
    _coursePriceError = null;
    _parentNameError = null;
    _parentUsernameError = null;
    _parentPasswordError = null;
    _passwordError = null;
  }

  void _focusFirstInvalid() {
    FocusNode? target;
    if (_nameController.text.trim().isEmpty || _nameError != null) {
      target = _nameFocus;
    } else if (_emailController.text.trim().isEmpty ||
        !_emailController.text.trim().contains('@') ||
        _emailError != null) {
      target = _emailFocus;
    } else if (widget.person.isStudent && _coursePriceError != null) {
      target = _coursePriceFocus;
    } else if (widget.person.isStudent && _parentPortalTouched) {
      if (_parentNameController.text.trim().isEmpty || _parentNameError != null) {
        target = _parentNameFocus;
      } else if (_parentUsernameController.text.trim().isEmpty || _parentUsernameError != null) {
        target = _parentUsernameFocus;
      } else if (_parentPasswordError != null ||
          (!_hasExistingParent && _parentPasswordController.text.length < 4)) {
        target = _parentPasswordFocus;
      }
    } else if (_passwordError != null ||
        (_passwordController.text.isNotEmpty && _passwordController.text.length < 8)) {
      target = _passwordFocus;
    }
    target?.requestFocus();
  }

  String? _validateName(String? v) {
    if (_nameError != null) return _nameError;
    if (v == null || v.trim().isEmpty) return 'Name is required';
    return null;
  }

  String? _validateEmail(String? v) {
    if (_emailError != null) return _emailError;
    final email = (v ?? '').trim();
    if (email.isEmpty) return 'Email is required';
    if (!email.contains('@') || !email.contains('.')) return 'Enter a valid email';
    return null;
  }

  String? _validateCoursePrice(String? v) {
    if (_coursePriceError != null) return _coursePriceError;
    final text = (v ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null || parsed < 0) return 'Enter a valid course price';
    return null;
  }

  String? _validateParentName(String? v) {
    if (_parentNameError != null) return _parentNameError;
    if (!_parentPortalTouched) return null;
    if (v == null || v.trim().isEmpty) return 'Parent name is required for portal login';
    return null;
  }

  String? _validateParentUsername(String? v) {
    if (_parentUsernameError != null) return _parentUsernameError;
    if (!_parentPortalTouched) return null;
    final username = (v ?? '').trim().toLowerCase();
    if (username.isEmpty) return 'Parent username is required for portal login';
    if (!RegExp(r'^[a-z0-9._-]{3,40}$').hasMatch(username)) {
      return '3–40 chars: letters, numbers, . _ - only';
    }
    return null;
  }

  String? _validateParentPassword(String? v) {
    if (_parentPasswordError != null) return _parentPasswordError;
    if (!_parentPortalTouched) return null;
    final password = v ?? '';
    if (!_hasExistingParent && password.isEmpty) {
      return 'Parent password is required (min 4 characters)';
    }
    if (password.isNotEmpty && password.length < 4) {
      return 'Parent password must be at least 4 characters';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (_passwordError != null) return _passwordError;
    final password = v ?? '';
    if (password.isNotEmpty && password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  void _applyServerError(Object e) {
    _clearFieldErrors();
    final message = _friendlyError(e).toLowerCase();
    if (message.contains('email')) {
      _emailError = _friendlyError(e);
    } else if (message.contains('parent username') || message.contains('username')) {
      _parentUsernameError = _friendlyError(e);
    } else if (message.contains('parent password') ||
        (message.contains('parent') && message.contains('password'))) {
      _parentPasswordError = _friendlyError(e);
    } else if (message.contains('parent name') || message.contains('parent')) {
      _parentNameError = _friendlyError(e);
    } else if (message.contains('password')) {
      _passwordError = _friendlyError(e);
    } else if (message.contains('course') || message.contains('price')) {
      _coursePriceError = _friendlyError(e);
    } else if (message.contains('name')) {
      _nameError = _friendlyError(e);
    }
  }

  Future<void> _save() async {
    setState(() {
      _clearFieldErrors();
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });

    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) {
      _focusFirstInvalid();
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    double? coursePrice;
    if (widget.person.isStudent) {
      final priceText = _coursePriceController.text.trim();
      coursePrice = priceText.isEmpty ? 0.0 : double.tryParse(priceText);
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(identityApiProvider);
      if (widget.person.isStudent) {
        final parentUsername = _parentUsernameController.text.trim().toLowerCase();
        final parentPassword = _parentPasswordController.text;
        final parentName = _parentNameController.text.trim();
        final parentPhone = _parentPhoneController.text.trim();

        Map<String, dynamic>? parentAccount;
        if (_parentPortalTouched) {
          parentAccount = {
            'name': parentName,
            'username': parentUsername,
            'relation': _parentRelation,
            'phone': parentPhone,
            if (parentPassword.isNotEmpty) 'password': parentPassword,
          };
        }

        await api.updateStudent(
          id: widget.person.id,
          name: name,
          email: email,
          parentName: parentName.isEmpty ? null : parentName,
          parentPhone: parentPhone,
          parentAccount: parentAccount,
          coursePrice: coursePrice,
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
      if (!mounted) return;
      setState(() {
        _applyServerError(e);
        _autovalidateMode = AutovalidateMode.always;
      });
      _formKey.currentState?.validate();
      _focusFirstInvalid();
      // Only snackbar when we couldn't pin it to a field.
      if (_nameError == null &&
          _emailError == null &&
          _coursePriceError == null &&
          _parentNameError == null &&
          _parentUsernameError == null &&
          _parentPasswordError == null &&
          _passwordError == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _friendlyError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] is Map) {
        final err = data['error'] as Map;
        final details = err['details'];
        if (details is List && details.isNotEmpty) {
          final first = details.first;
          if (first is Map) {
            final detailMsg = first['msg'] ?? first['message'];
            if (detailMsg != null && detailMsg.toString().trim().isNotEmpty) {
              return detailMsg.toString();
            }
          }
        }
        final message = err['message']?.toString();
        if (message != null && message.trim().isNotEmpty) return message;
      }
      final status = e.response?.statusCode;
      if (status == 401) return 'Session expired. Please log in again.';
      if (status == 403) return 'You do not have permission to edit this student.';
      if (status == 409) return 'Email or parent username already in use.';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.person.isStudent;

    return AppDialog(
      title: isStudent ? 'Edit student' : 'Edit staff',
      icon: Icons.edit_outlined,
      content: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: SingleChildScrollView(
          child: AppFormColumn(
            children: [
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                decoration: const InputDecoration(labelText: 'Name *'),
                textCapitalization: TextCapitalization.words,
                validator: _validateName,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
              ),
              if (isStudent) ...[
                TextFormField(
                  controller: _coursePriceController,
                  focusNode: _coursePriceFocus,
                  decoration: const InputDecoration(
                    labelText: 'Course price (monthly)',
                    hintText: 'Student monthly fee',
                    prefixText: '\$ ',
                    helperText: 'Used for dues. Leave empty to use the group/subject price.',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _validateCoursePrice,
                  onChanged: (_) {
                    if (_coursePriceError != null) setState(() => _coursePriceError = null);
                  },
                ),
                DropdownButtonFormField<String>(
                  value: _parentRelation,
                  decoration: const InputDecoration(labelText: 'Parent relation'),
                  items: const [
                    DropdownMenuItem(value: 'mother', child: Text('Mother')),
                    DropdownMenuItem(value: 'father', child: Text('Father')),
                    DropdownMenuItem(value: 'guardian', child: Text('Guardian')),
                  ],
                  onChanged: (v) => setState(() => _parentRelation = v ?? 'mother'),
                ),
                TextFormField(
                  controller: _parentNameController,
                  focusNode: _parentNameFocus,
                  decoration: const InputDecoration(labelText: 'Parent name'),
                  textCapitalization: TextCapitalization.words,
                  validator: _validateParentName,
                  onChanged: (_) {
                    if (_parentNameError != null) setState(() => _parentNameError = null);
                    // Re-validate siblings when portal fields change.
                    if (_autovalidateMode != AutovalidateMode.disabled) {
                      _formKey.currentState?.validate();
                    }
                  },
                ),
                TextFormField(
                  controller: _parentPhoneController,
                  decoration: const InputDecoration(labelText: 'Parent phone'),
                  keyboardType: TextInputType.phone,
                ),
                TextFormField(
                  controller: _parentUsernameController,
                  focusNode: _parentUsernameFocus,
                  decoration: const InputDecoration(
                    labelText: 'Parent username',
                    hintText: 'Memorable login for parent portal',
                    helperText: 'Optional — only needed for parent portal login',
                  ),
                  validator: _validateParentUsername,
                  onChanged: (_) {
                    if (_parentUsernameError != null) setState(() => _parentUsernameError = null);
                    if (_autovalidateMode != AutovalidateMode.disabled) {
                      _formKey.currentState?.validate();
                    }
                  },
                ),
                TextFormField(
                  controller: _parentPasswordController,
                  focusNode: _parentPasswordFocus,
                  obscureText: _obscureParentPassword,
                  validator: _validateParentPassword,
                  onChanged: (_) {
                    if (_parentPasswordError != null) setState(() => _parentPasswordError = null);
                    if (_autovalidateMode != AutovalidateMode.disabled) {
                      _formKey.currentState?.validate();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Parent password',
                    helperText: _hasExistingParent
                        ? 'Leave blank to keep current parent password'
                        : 'Required only when creating a new parent login',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureParentPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureParentPassword = !_obscureParentPassword),
                    ),
                  ),
                ),
              ] else
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
                validator: _validatePassword,
                onChanged: (_) {
                  if (_passwordError != null) setState(() => _passwordError = null);
                },
                decoration: InputDecoration(
                  labelText: isStudent ? 'New student password' : 'New password',
                  helperText: 'Leave blank to keep current password',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
            ],
          ),
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
