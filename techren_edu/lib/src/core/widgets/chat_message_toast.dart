import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_user.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/communications_provider.dart';
import '../routing/app_router.dart';
import '../theme/app_spacing.dart';
import '../utils/media_url.dart';

/// Telegram-style slide-down toast for new chat messages while not in that thread.
class ChatMessageToastOverlay extends ConsumerStatefulWidget {
  const ChatMessageToastOverlay({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ChatMessageToastOverlay> createState() => _ChatMessageToastOverlayState();
}

class _ChatMessageToastOverlayState extends ConsumerState<ChatMessageToastOverlay>
    with SingleTickerProviderStateMixin {
  static const _displayDuration = Duration(seconds: 5);

  Timer? _hideTimer;
  ChatToastEvent? _current;
  late final AnimationController _anim;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _slide = Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _show(ChatToastEvent event) async {
    _hideTimer?.cancel();
    setState(() => _current = event);
    await _anim.forward(from: 0);
    _hideTimer = Timer(_displayDuration, _dismiss);
  }

  Future<void> _dismiss() async {
    _hideTimer?.cancel();
    if (!mounted) return;
    await _anim.reverse();
    if (!mounted) return;
    setState(() => _current = null);
  }

  void _onTap() {
    final event = _current;
    if (event == null) return;
    final user = ref.read(authProvider).user;
    if (user == null) return;

    ref.read(pendingOpenConversationIdProvider.notifier).state = event.conversationId;
    final router = ref.read(routerProvider);
    if (user.userType == UserType.student) {
      router.go('/student/messages');
    } else if (user.isFounder) {
      router.go('/founder/messages');
    } else if (user.usesAdminShell) {
      router.go('/admin/messages');
    } else if (user.isTeacher) {
      router.go('/teacher/messages');
    }
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure realtime socket is connected for toast delivery.
    ref.watch(communicationsRealtimeProvider);

    ref.listen<ChatToastEvent?>(chatToastEventProvider, (prev, next) {
      if (next == null || next.id == prev?.id) return;
      _show(next);
    });

    final note = _current;
    final avatarUrl = resolveMediaUrl(note?.avatarUrl);

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
                    elevation: 10,
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
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                              child: avatarUrl.isEmpty
                                  ? Text(
                                      note.title.isNotEmpty ? note.title[0].toUpperCase() : '?',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    )
                                  : null,
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
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: _dismiss,
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
