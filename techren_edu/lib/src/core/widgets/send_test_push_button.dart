import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/notification_provider.dart';
import '../l10n/app_localizations.dart';
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
      if (!mounted) return;
      final message = !result.firebaseConfigured
          ? l10n.testPushFirebaseOff
          : result.sent > 0
              ? l10n.testPushSent
              : l10n.testPushNoToken;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.testPushFailed)));
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
