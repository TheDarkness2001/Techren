import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/communications_provider.dart';

class MessagesIconButton extends ConsumerWidget {
  const MessagesIconButton({
    super.key,
    required this.route,
    this.tooltip = 'Messages',
    this.iconColor,
  });

  final String route;
  final String tooltip;
  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(communicationsUnreadProvider);
    final count = countAsync.valueOrNull ?? 0;

    return Semantics(
      label: count > 0 ? '$tooltip, $count unread' : tooltip,
      button: true,
      child: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: IconButton(
          icon: Icon(Icons.chat_bubble_outline, color: iconColor),
          tooltip: tooltip,
          onPressed: () => context.go(route),
        ),
      ),
    );
  }
}
