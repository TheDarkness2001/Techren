import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/notification.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/finance_provider.dart';
import '../../presentation/providers/notification_provider.dart';
import '../routing/app_router.dart';
import '../theme/app_spacing.dart';

/// Telegram-style slide-down toast for student in-app notifications
/// (attendance, daily feedback, payment reminders) while anywhere in the app.
class StudentInAppToastOverlay extends ConsumerStatefulWidget {
  const StudentInAppToastOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StudentInAppToastOverlay> createState() => _StudentInAppToastOverlayState();
}

class _StudentInAppToastOverlayState extends ConsumerState<StudentInAppToastOverlay>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _seenKey = 'student_in_app_toast_seen_ids';
  static const _duesToastDayKey = 'student_dues_toast_day';
  static const _pollInterval = Duration(seconds: 12);
  static const _displayDuration = Duration(seconds: 7);

  Timer? _pollTimer;
  Timer? _hideTimer;
  final Set<String> _seenIds = {};
  final List<AppNotification> _queue = [];
  AppNotification? _current;
  late final AnimationController _anim;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _slide = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
    _loadSeen().then((_) => _startPolling());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _hideTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _poll();
    }
  }

  Future<void> _loadSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_seenKey) ?? [];
    _seenIds.addAll(stored);
  }

  Future<void> _persistSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = _seenIds.toList().reversed.take(200).toList().reversed.toList();
    await prefs.setStringList(_seenKey, trimmed);
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
    _poll();
  }

  bool get _isStudent {
    final user = ref.read(authProvider).user;
    return user != null && user.userType == UserType.student;
  }

  Future<void> _poll() async {
    if (!mounted || !_isStudent) return;
    try {
      await _maybeEnqueueDuesToast();

      final inbox = await ref.read(notificationApiProvider).getNotifications(
            page: 1,
            unreadOnly: true,
          );
      final fresh = inbox.notifications.where((n) {
        if (_seenIds.contains(n.id)) return false;
        if (_queue.any((q) => q.id == n.id)) return false;
        if (_current?.id == n.id) return false;
        return _isPopupWorthy(n);
      }).toList()
        ..sort((a, b) {
          final aAt = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bAt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aAt.compareTo(bAt);
        });

      // Keep the bell badge in sync whenever we poll.
      ref.invalidate(unreadNotificationCountProvider);

      if (fresh.isEmpty) return;
      _queue.addAll(fresh);
      if (_current == null) {
        _showNext();
      }
    } catch (_) {
      // Ignore transient network errors while polling.
    }
  }

  /// Show a Telegram-style payment popup when dues remain unpaid (once per day).
  Future<void> _maybeEnqueueDuesToast() async {
    final user = ref.read(authProvider).user;
    if (user == null || user.userType != UserType.student) return;

    final now = DateTime.now();
    final dayKey = '${now.year}-${now.month}-${now.day}:${user.id}';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_duesToastDayKey) == dayKey) return;

    // Only nag during the 1–10 payment window (or if already locked).
    final day = now.day;
    if (day > 10 && !user.isInactiveStudent) return;

    final dues = await ref.read(financeApiProvider).getMyDues();
    if (dues.isPaid || dues.amountRemaining <= 0) {
      await prefs.setString(_duesToastDayKey, dayKey);
      return;
    }

    final syntheticId = 'dues-$dayKey';
    if (_seenIds.contains(syntheticId) || _queue.any((q) => q.id == syntheticId)) return;

    final amount = dues.amountRemaining.round().toString();
    final note = AppNotification(
      id: syntheticId,
      userId: user.id,
      userType: 'student',
      studentId: user.id,
      title: user.isInactiveStudent ? 'App locked — payment required' : 'Payment due',
      body: user.isInactiveStudent
          ? 'Your account is locked until the unpaid balance ($amount UZS) is cleared. Open Payments or contact administration.'
          : 'You still owe $amount UZS this month. Please pay by the 10th or the app will be locked.',
      eventType: 'payment_due',
      channel: 'in_app',
      date: dayKey.split(':').first,
      data: {'kind': 'payment', 'amountRemaining': dues.amountRemaining},
      createdAt: now,
    );

    await prefs.setString(_duesToastDayKey, dayKey);
    _queue.add(note);
    if (_current == null) {
      _showNext();
    }
  }

  bool _isPopupWorthy(AppNotification n) {
    final type = n.eventType.toLowerCase();
    final kind = (n.data?['kind'] as String?)?.toLowerCase() ?? '';
    return type.contains('attendance') ||
        type.contains('feedback') ||
        type.contains('payment') ||
        type.contains('chat') ||
        type.contains('message') ||
        kind == 'attendance' ||
        kind == 'daily_feedback' ||
        kind == 'payment';
  }

  Future<void> _showNext() async {
    if (!mounted || _queue.isEmpty) {
      setState(() => _current = null);
      return;
    }
    final next = _queue.removeAt(0);
    _seenIds.add(next.id);
    unawaited(_persistSeen());
    setState(() => _current = next);
    await _anim.forward(from: 0);
    _hideTimer?.cancel();
    _hideTimer = Timer(_displayDuration, _dismissCurrent);
  }

  Future<void> _dismissCurrent() async {
    _hideTimer?.cancel();
    if (!mounted) return;
    await _anim.reverse();
    if (!mounted) return;
    setState(() => _current = null);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (mounted) _showNext();
  }

  Future<void> _onTap() async {
    final note = _current;
    if (note == null) return;
    if (!note.id.startsWith('dues-')) {
      try {
        await ref.read(notificationApiProvider).markRead(note.id);
        invalidateNotificationState(ref);
      } catch (_) {}
    }
    if (!mounted) return;
    ref.read(routerProvider).go(_routeFor(note));
    await _dismissCurrent();
  }

  String _routeFor(AppNotification n) {
    final type = n.eventType.toLowerCase();
    if (type.contains('chat') || type.contains('message')) return '/student/messages';
    if (type.contains('feedback')) return '/student/feedback';
    if (type.contains('attendance')) return '/student/schedule';
    if (type.contains('payment')) return '/student/payments';
    return '/student/notifications';
  }

  IconData _iconFor(AppNotification n) {
    final type = n.eventType.toLowerCase();
    if (type.contains('payment')) return Icons.payments_outlined;
    if (type.contains('attendance')) return Icons.fact_check_outlined;
    if (type.contains('feedback')) return Icons.rate_review_outlined;
    if (type.contains('chat') || type.contains('message')) return Icons.chat_bubble_outline;
    return Icons.notifications_active_outlined;
  }

  Color _accentFor(AppNotification n, ColorScheme scheme) {
    final type = n.eventType.toLowerCase();
    if (type.contains('payment')) return scheme.error;
    if (type.contains('attendance')) return scheme.tertiary;
    if (type.contains('feedback')) return scheme.primary;
    return scheme.secondary;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.user?.userType == UserType.student) {
        _poll();
      } else {
        _queue.clear();
        _current = null;
      }
    });

    final note = _current;
    return Stack(
      children: [
        widget.child,
        if (note != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: SlideTransition(
                position: _slide,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(14),
                    color: Theme.of(context).colorScheme.surface,
                    shadowColor: Colors.black54,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: _accentFor(note, Theme.of(context).colorScheme)
                                  .withValues(alpha: 0.15),
                              child: Icon(
                                _iconFor(note),
                                size: 20,
                                color: _accentFor(note, Theme.of(context).colorScheme),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    note.body,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: _dismissCurrent,
                              icon: const Icon(Icons.close, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
