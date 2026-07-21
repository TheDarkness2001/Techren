import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum ScreenSize { compact, medium, expanded }

class Responsive {
  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppConstants.expandedBreakpoint) return ScreenSize.expanded;
    if (width >= AppConstants.compactBreakpoint) return ScreenSize.medium;
    return ScreenSize.compact;
  }

  static bool isCompact(BuildContext context) => of(context) == ScreenSize.compact;
  static bool isExpanded(BuildContext context) => of(context) == ScreenSize.expanded;
}
