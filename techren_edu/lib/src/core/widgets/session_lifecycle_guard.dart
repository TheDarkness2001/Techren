import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/task_integrity_provider.dart';

/// Watches app lifecycle for idle timeout and task anti-cheat logout.
class SessionLifecycleGuard extends ConsumerStatefulWidget {
  const SessionLifecycleGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SessionLifecycleGuard> createState() => _SessionLifecycleGuardState();
}

class _SessionLifecycleGuardState extends ConsumerState<SessionLifecycleGuard>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final auth = ref.read(authProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        auth.onAppResumed();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (ref.read(taskIntegrityProvider)) {
          auth.logoutDueToTaskLeave();
        } else {
          auth.onAppBackgrounded();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
