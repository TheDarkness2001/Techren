import 'package:flutter/material.dart';

/// 8dp spacing system — every layout margin/padding should use these tokens
/// instead of arbitrary numbers so screens align consistently across the app.
abstract final class AppSpacing {
  static const double unit = 8;

  static const double micro = 2;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  /// Standard page gutter on phone.
  static const double pageHorizontal = md;

  /// Wider gutter on tablet/desktop content areas.
  static const double pageHorizontalWide = lg;

  /// Vertical rhythm between major sections.
  static const double sectionGap = lg;

  /// Gap between related controls in a form row.
  static const double fieldGap = md;

  /// Minimum interactive target (accessibility).
  static const double minTouchTarget = 48;

  /// Top inset before empty-state content in scroll views.
  static const double emptyStateTop = 120;

  static const EdgeInsets pagePadding = EdgeInsets.all(md);
  static const EdgeInsets pagePaddingWide = EdgeInsets.all(lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);
  static const EdgeInsets searchBarPadding = EdgeInsets.fromLTRB(md, sm, md, 0);
  static const EdgeInsets pageHeaderPadding = EdgeInsets.fromLTRB(md, md, md, 0);
  static const EdgeInsets dialogInset = EdgeInsets.symmetric(horizontal: lg, vertical: lg);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(horizontal: sm, vertical: xxs);
  static const EdgeInsets listGutter = EdgeInsets.all(md);
}
