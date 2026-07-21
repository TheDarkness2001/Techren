import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_durations.dart';

/// Shared route transitions — fade + slight slide for premium page changes (Phase E).
abstract final class AppPageTransitions {
  static CustomTransitionPage<void> fadeSlide({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: key,
      transitionDuration: AppDurations.normal,
      reverseTransitionDuration: AppDurations.fast,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: AppCurves.enter));

        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: AppCurves.standard),
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
    );
  }

  /// Wraps a [GoRoute] builder with the shared fade-slide page transition.
  /// Use [redirect] instead of [builder] for redirect-only routes.
  static GoRoute route({
    required String path,
    Widget Function(BuildContext context, GoRouterState state)? builder,
    String? Function(BuildContext context, GoRouterState state)? redirect,
    List<RouteBase> routes = const [],
  }) {
    if (redirect != null) {
      return GoRoute(path: path, redirect: redirect, routes: routes);
    }
    return GoRoute(
      path: path,
      pageBuilder: (context, state) => fadeSlide(
        key: state.pageKey,
        child: builder!(context, state),
      ),
      routes: routes,
    );
  }
}
