import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/go_back_icon_button.dart';
import '../../../../domain/entities/notification.dart';
import '../../../../domain/entities/paginated_result.dart';
import '../../../../domain/entities/person.dart';
import '../../../providers/identity_provider.dart';
import '../../../providers/notification_provider.dart';

class ParentNotificationSettingsScreen extends ConsumerStatefulWidget {
  const ParentNotificationSettingsScreen({
    super.key,
    required this.navItems,
    required this.selectedRoute,
  });

  final List<NavItem> navItems;
  final String selectedRoute;

  @override
  ConsumerState<ParentNotificationSettingsScreen> createState() =>
      _ParentNotificationSettingsScreenState();
}

class _ParentNotificationSettingsScreenState
    extends ConsumerState<ParentNotificationSettingsScreen> {
  String? _selectedStudentId;

  @override
  Widget build(BuildContext context) {
    final selectedIndex =
        widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));
    // Active students only — inactive accounts never receive alerts/messages.
    final studentsAsync = ref.watch(
      studentsProvider(const PageMeta(limit: 100, status: 'active')),
    );

    return AdaptiveScaffold(
      title: 'Parent Alerts',
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        GoBackIconButton(fallbackRoute: '/parent'),
      ],
      body: studentsAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => ErrorState(
          message: 'Could not load students.',
          onRetry: () => ref.invalidate(
            studentsProvider(const PageMeta(limit: 100, status: 'active')),
          ),
        ),
        data: (result) {
          final students = result.items.where((s) => s.isActive).toList();
          if (students.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No active students found.\nInactive students do not receive parent alerts.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          Person selected = students.firstWhere(
            (s) => s.id == _selectedStudentId,
            orElse: () => students.first,
          );
          if (_selectedStudentId != selected.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedStudentId = selected.id);
            });
          }

          final settingsAsync = ref.watch(parentNotificationSettingsProvider(selected.id));

          return ListView(
            padding: AppSpacing.pagePaddingWide,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: DropdownButtonFormField<String>(
                    value: selected.id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Student',
                      helperText: 'Only active students can receive alerts',
                    ),
                    items: [
                      for (final s in students)
                        DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (id) {
                      if (id != null) setState(() => _selectedStudentId = id);
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              settingsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => ErrorState(
                  message: 'Could not load alert settings for this student.',
                  onRetry: () =>
                      ref.invalidate(parentNotificationSettingsProvider(selected.id)),
                ),
                data: (settings) => _SettingsForm(
                  studentId: selected.id,
                  studentName: selected.name,
                  settings: settings,
                  onSaved: () =>
                      ref.invalidate(parentNotificationSettingsProvider(selected.id)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({
    required this.studentId,
    required this.studentName,
    required this.settings,
    required this.onSaved,
  });

  final String studentId;
  final String studentName;
  final ParentNotificationSettings settings;
  final VoidCallback onSaved;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late bool pushEnabled;
  late bool feedback;
  late bool attendance;
  late bool payment;
  late bool exam;
  late String quietStart;
  late String quietEnd;

  @override
  void initState() {
    super.initState();
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(covariant _SettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studentId != widget.studentId) {
      _syncFromWidget();
    }
  }

  void _syncFromWidget() {
    pushEnabled = widget.settings.channels.push;
    feedback = widget.settings.events.feedback;
    attendance = widget.settings.events.attendance;
    payment = widget.settings.events.payment;
    exam = widget.settings.events.exam;
    quietStart = widget.settings.quietHoursStart;
    quietEnd = widget.settings.quietHoursEnd;
  }

  Future<void> _save() async {
    final updated = ParentNotificationSettings(
      studentId: widget.studentId,
      channels: NotificationChannels(push: pushEnabled, inApp: true),
      events: NotificationEvents(
        feedback: feedback,
        attendance: attendance,
        payment: payment,
        exam: exam,
      ),
      quietHoursStart: quietStart,
      quietHoursEnd: quietEnd,
      timezone: widget.settings.timezone,
    );

    try {
      await ref.read(notificationApiProvider).updateParentSettings(widget.studentId, updated);
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save settings. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text('Alerts for ${widget.studentName}'),
              subtitle: const Text('Inactive students never receive alerts or messages.'),
            ),
            SwitchListTile(
              title: const Text('Push notifications'),
              subtitle: const Text('Send FCM alerts to registered devices'),
              value: pushEnabled,
              onChanged: (v) => setState(() => pushEnabled = v),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Event types', style: Theme.of(context).textTheme.titleMedium),
            ),
            SwitchListTile(
              title: const Text('Feedback'),
              value: feedback,
              onChanged: (v) => setState(() => feedback = v),
            ),
            SwitchListTile(
              title: const Text('Attendance'),
              value: attendance,
              onChanged: (v) => setState(() => attendance = v),
            ),
            SwitchListTile(
              title: const Text('Payments'),
              value: payment,
              onChanged: (v) => setState(() => payment = v),
            ),
            SwitchListTile(
              title: const Text('Exams'),
              value: exam,
              onChanged: (v) => setState(() => exam = v),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Quiet hours', style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              title: const Text('Start'),
              subtitle: Text(quietStart),
              trailing: const Icon(Icons.bedtime_outlined),
            ),
            Slider(
              value: _hourToSlider(quietStart),
              min: 0,
              max: 23,
              divisions: 23,
              label: quietStart,
              onChanged: (v) => setState(() => quietStart = _sliderToHour(v)),
            ),
            ListTile(
              title: const Text('End'),
              subtitle: Text(quietEnd),
              trailing: const Icon(Icons.wb_sunny_outlined),
            ),
            Slider(
              value: _hourToSlider(quietEnd),
              min: 0,
              max: 23,
              divisions: 23,
              label: quietEnd,
              onChanged: (v) => setState(() => quietEnd = _sliderToHour(v)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(onPressed: _save, child: const Text('Save settings')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _hourToSlider(String time) {
    final parts = time.split(':');
    return double.tryParse(parts.first) ?? 22;
  }

  String _sliderToHour(double value) {
    return '${value.round().toString().padLeft(2, '0')}:00';
  }
}
