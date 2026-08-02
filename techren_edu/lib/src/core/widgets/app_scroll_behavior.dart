import 'package:flutter/material.dart';

import 'page_content_container.dart';

/// Desktop scrollbars dock to the panel edge and reserve a gutter so the thumb
/// does not paint over cards / banners.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  static const double scrollbarGutter = 12;

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    final vertical =
        details.direction == AxisDirection.down || details.direction == AxisDirection.up;

    if (!vertical) {
      return Scrollbar(controller: details.controller, child: child);
    }

    final sideInset = PageContentInsets.maybeOf(context);
    return Scrollbar(
      controller: details.controller,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: Padding(
          padding: EdgeInsets.only(
            left: sideInset,
            right: sideInset + scrollbarGutter,
          ),
          child: child,
        ),
      ),
    );
  }
}
