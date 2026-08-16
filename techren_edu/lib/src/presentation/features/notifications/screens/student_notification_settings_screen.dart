import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/go_back_icon_button.dart';
import '../../../../core/widgets/send_test_push_button.dart';
import '../../../../domain/entities/notification.dart';
import '../../../providers/notification_provider.dart';

class StudentNotificationSettingsScreen extends ConsumerWidget {
  const StudentNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navItems = studentNavItemsOf(context);
    final settingsAsync = ref.watch(studentNotificationSettingsProvider);

    return AdaptiveScaffold(
      title: 'Notification settings',
      selectedIndex: 4,
      selectedRoute: '/student/profile',
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      actions: [
        GoBackIconButton(fallbackRoute: '/student/profile'),
      ],
      body: settingsAsync.when(
        loading: () => const LoadingState(kind: LoadingSkeletonKind.list),
        error: (e, _) => ErrorState(
          message: 'Could not load notification settings.',
          onRetry: () => ref.invalidate(studentNotificationSettingsProvider),
        ),
        data: (settings) => _StudentSettingsForm(settings: settings),
      ),
    );
  }
}

class _StudentSettingsForm extends ConsumerStatefulWidget {
  const _StudentSettingsForm({required this.settings});

  final StudentNotificationSettings settings;

  @override
  ConsumerState<_StudentSettingsForm> createState() => _StudentSettingsFormState();
}

class _StudentSettingsFormState extends ConsumerState<_StudentSettingsForm> {
  late bool pushEnabled;
  late bool feedback;
  late bool attendance;
  late bool messages;
  late bool news;
  late bool exam;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _StudentSettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.studentId != widget.settings.studentId) {
      _sync();
    }
  }

  void _sync() {
    pushEnabled = widget.settings.channels.push;
    feedback = widget.settings.events.feedback;
    attendance = widget.settings.events.attendance;
    messages = widget.settings.events.messages;
    news = widget.settings.events.news;
    exam = widget.settings.events.exam;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.settings.copyWith(
      channels: NotificationChannels(push: pushEnabled, inApp: widget.settings.channels.inApp),
      events: widget.settings.events.copyWith(
        feedback: feedback,
        attendance: attendance,
        messages: messages,
        news: news,
        exam: exam,
        // Payment mute is stored but server always pushes payment/lock.
        payment: widget.settings.events.payment,
      ),
    );
    try {
      await ref.read(notificationApiProvider).updateMySettings(updated);
      ref.invalidate(studentNotificationSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings saved')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save settings. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.pagePaddingWide,
      children: [
        Text(
          'Choose which categories can send OS push when the app is closed. '
          'Payment reminders and account lock always notify you.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile(
          title: const Text('Push notifications'),
          subtitle: const Text('Master switch for non-critical alerts'),
          value: pushEnabled,
          onChanged: (v) => setState(() => pushEnabled = v),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Feedback'),
          value: feedback,
          onChanged: pushEnabled ? (v) => setState(() => feedback = v) : null,
        ),
        SwitchListTile(
          title: const Text('Attendance'),
          value: attendance,
          onChanged: pushEnabled ? (v) => setState(() => attendance = v) : null,
        ),
        SwitchListTile(
          title: const Text('Messages'),
          value: messages,
          onChanged: pushEnabled ? (v) => setState(() => messages = v) : null,
        ),
        SwitchListTile(
          title: const Text('News'),
          value: news,
          onChanged: pushEnabled ? (v) => setState(() => news = v) : null,
        ),
        SwitchListTile(
          title: const Text('Exams'),
          value: exam,
          onChanged: pushEnabled ? (v) => setState(() => exam = v) : null,
        ),
        SwitchListTile(
          title: const Text('Payments'),
          subtitle: const Text('Always on — reminders and lock cannot be muted'),
          value: true,
          onChanged: null,
        ),
        const SendTestPushButton(),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save settings'),
          ),
        ),
      ],
    );
  }
}
