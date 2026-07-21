import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';

/// Theme-aware surface/border helpers — use instead of hardcoded [AppColors.surface].
extension AppThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  Color get cardColor => colors.surface;

  Color get cardBorder => semantic.border;

  Color get cardMuted => semantic.textMuted;

  Color get fillContainer => semantic.surfaceContainer;
}
