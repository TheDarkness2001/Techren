import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Vertical form stack with consistent gaps between fields.
/// Use instead of bare [Column] for stacked TextFields / dropdowns.
class AppFormColumn extends StatelessWidget {
  const AppFormColumn({
    super.key,
    required this.children,
    this.spacing = AppSpacing.md,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.min,
  });

  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          children[i],
        ],
      ],
    );
  }
}
