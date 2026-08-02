import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Side inset (per side) when the staff content panel is wider than [maxWidth].
/// Applied by [AppScrollBehavior] so scrollbars stay on the panel’s right edge.
class PageContentInsets extends InheritedWidget {
  const PageContentInsets({
    super.key,
    required this.inset,
    required super.child,
  });

  final double inset;

  static double maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PageContentInsets>()?.inset ?? 0;
  }

  @override
  bool updateShouldNotify(PageContentInsets oldWidget) => inset != oldWidget.inset;
}

/// Full-width page host. Caps readable width via [PageContentInsets] (consumed by
/// scroll behavior) so desktop scrollbars are not trapped inside a centered box.
class PageContentContainer extends StatelessWidget {
  const PageContentContainer({
    super.key,
    required this.child,
    this.maxWidth = AppConstants.maxContentWidth,
    this.semanticLabel = 'Page content',
  });

  final Widget child;
  final double maxWidth;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      container: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inset = math.max(0.0, (constraints.maxWidth - maxWidth) / 2);
          return PageContentInsets(
            inset: inset,
            child: SizedBox(width: constraints.maxWidth, child: child),
          );
        },
      ),
    );
  }
}
