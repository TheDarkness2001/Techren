import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dedup IDs for FCM + in-app toast + socket so one event does not triple-fire.
final pushDedupIdsProvider = StateProvider<Set<String>>((ref) => <String>{});

class PendingNotificationNav {
  const PendingNotificationNav({
    required this.screen,
    this.conversationId,
    this.notificationId,
    this.extra = const {},
  });

  final String screen;
  final String? conversationId;
  final String? notificationId;
  final Map<String, String> extra;
}

final pendingNotificationNavProvider = StateProvider<PendingNotificationNav?>((ref) => null);

/// Returns false if [id] was already claimed (duplicate). Empty ids always pass.
bool claimPushDedupId(dynamic ref, String id) {
  if (id.isEmpty) return true;
  final seen = ref.read(pushDedupIdsProvider) as Set<String>;
  if (seen.contains(id)) return false;
  final next = {...seen, id};
  if (next.length > 300) {
    ref.read(pushDedupIdsProvider.notifier).state = next.skip(next.length - 200).toSet();
  } else {
    ref.read(pushDedupIdsProvider.notifier).state = next;
  }
  return true;
}
