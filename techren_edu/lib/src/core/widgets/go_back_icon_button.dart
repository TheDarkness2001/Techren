import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App-bar back action — pops when possible, otherwise goes to [fallbackRoute].
class GoBackIconButton extends StatelessWidget {
  const GoBackIconButton({
    super.key,
    this.fallbackRoute,
    this.tooltip = 'Go back',
  });

  /// Used when there is nothing to pop (e.g. deep link / replaced route).
  final String? fallbackRoute;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        final fallback = fallbackRoute;
        if (fallback != null && fallback.isNotEmpty) {
          context.go(fallback);
        }
      },
      icon: const Icon(Icons.arrow_back),
    );
  }
}
