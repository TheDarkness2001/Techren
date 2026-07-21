import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Centers and caps page width on ultra-wide screens (Phase F.6).
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
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}
