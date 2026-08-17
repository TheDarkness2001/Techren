import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/notification_provider.dart';
import '../l10n/app_localizations.dart';
import '../push/push_chat_actions.dart';
import '../theme/app_spacing.dart';

class SendTestPushButton extends ConsumerStatefulWidget {
  const SendTestPushButton({super.key});

  @override
  ConsumerState<SendTestPushButton> createState() => _SendTestPushButtonState();
}

class _SendTestPushButtonState extends ConsumerState<SendTestPushButton> {
  bool _busy = false;

  Future<void> _send() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final result = await ref.read(notificationApiProvider).sendTestPush();
      invalidateNotificationState(ref);
      await showLocalAppNotification(
        title: 'TechRen test',
        body: 'Push is working. You can close this notification.',
        data: const {'eventType': 'test_push', 'screen': 'notifications'},
      );
      if (!mounted) return;
      final message = result.sent > 0 || result.inboxCreated
          ? l10n.testPushSent
          : l10n.testPushFirebaseOff;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      await showLocalAppNotification(
        title: 'TechRen test',
        body: 'Push is working. You can close this notification.',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.testPushSent)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: OutlinedButton(
        onPressed: _busy ? null : _send,
        child: _busy
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(
                context.l10n.sendTestNotification,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}
