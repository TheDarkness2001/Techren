import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/task_integrity_provider.dart';

/// Marks the subtree as an active learning task. Leaving the app while this
/// widget is mounted triggers anti-cheat auto-logout.
class TaskIntegrityScope extends ConsumerStatefulWidget {
  const TaskIntegrityScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<TaskIntegrityScope> createState() => _TaskIntegrityScopeState();
}

class _TaskIntegrityScopeState extends ConsumerState<TaskIntegrityScope> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(taskIntegrityProvider.notifier).beginTask();
    });
  }

  @override
  void dispose() {
    ref.read(taskIntegrityProvider.notifier).endTask();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
