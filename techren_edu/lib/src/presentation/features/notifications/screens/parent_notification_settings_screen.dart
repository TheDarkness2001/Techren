import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/go_back_icon_button.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
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
  ConsumerState<ParentNotificationSettingsScreen> createState() => _ParentNotificationSettingsScreenState();
}

class _ParentNotificationSettingsScreenState extends ConsumerState<ParentNotificationSettingsScreen> {
  String? _selectedStudentId;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = widget.navItems.indexWhere((r) => widget.selectedRoute.startsWith(r.route));
    final teachersAsync = ref.watch(studentsProvider(const PageMeta(limit: 50)));

    return AdaptiveScaffold(
      title: 'Parent Alerts',
      selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
      selectedRoute: widget.selectedRoute,
      items: widget.navItems,
      onDestinationSelected: (i) => context.go(widget.navItems[i].route),
      actions: [
        GoBackIconButton(fallbackRoute: '/parent'),
      ],
      body: teachersAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (result) {
          Person? selected;
          for (final s in result.items) {
            if (s.id == _selectedStudentId) {
              selected = s;
              break;
            }
          }
          selected ??= result.items.isNotEmpty ? result.items.first : null;
          if (selected != null && _selectedStudentId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => setState(() => _selectedStudentId = selected!.id));
          }

          if (selected == null) {
            return const Center(child: Text('No students found'));
          }

          final settingsAsync = ref.watch(parentNotificationSettingsProvider(selected.id));

          return Column(
            children: [
              Padding(
                padding: AppSpacing.pagePadding,
                child: DropdownButtonFormField<Person>(
                  value: selected,
                  decoration: const InputDecoration(labelText: 'Student'),
                  items: result.items.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                  onChanged: (s) => setState(() => _selectedStudentId = s?.id),
                ),
              ),
              Expanded(
                child: settingsAsync.when(
                  loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
                  error: (e, _) => Center(child: Text(e.toString())),
                  data: (settings) => _SettingsForm(
                    studentId: selected!.id,
                    settings: settings,
                    onSaved: () => ref.invalidate(parentNotificationSettingsProvider(selected!.id)),
                  ),
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
    required this.settings,
    required this.onSaved,
  });

  final String studentId;
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.listGutter,
      children: [
        SwitchListTile(
          title: const Text('Push notifications'),
          subtitle: const Text('Send FCM alerts to registered devices'),
          value: pushEnabled,
          onChanged: (v) => setState(() => pushEnabled = v),
        ),
        const Divider(),
        Text('Event types', style: Theme.of(context).textTheme.titleMedium),
        SwitchListTile(title: const Text('Feedback'), value: feedback, onChanged: (v) => setState(() => feedback = v)),
        SwitchListTile(title: const Text('Attendance'), value: attendance, onChanged: (v) => setState(() => attendance = v)),
        SwitchListTile(title: const Text('Payments'), value: payment, onChanged: (v) => setState(() => payment = v)),
        SwitchListTile(title: const Text('Exams'), value: exam, onChanged: (v) => setState(() => exam = v)),
        const Divider(),
        Text('Quiet hours', style: Theme.of(context).textTheme.titleMedium),
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
        const SizedBox(height: AppSpacing.md),
        FilledButton(onPressed: _save, child: const Text('Save settings')),
      ],
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
