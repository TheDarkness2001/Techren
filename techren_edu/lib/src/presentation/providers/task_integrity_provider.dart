import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When true, leaving the app (background) forces an immediate logout.
class TaskIntegrityNotifier extends StateNotifier<bool> {
  TaskIntegrityNotifier() : super(false);

  void beginTask() => state = true;

  void endTask() => state = false;
}

final taskIntegrityProvider =
    StateNotifierProvider<TaskIntegrityNotifier, bool>((ref) => TaskIntegrityNotifier());
