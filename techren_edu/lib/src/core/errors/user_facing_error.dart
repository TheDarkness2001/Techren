import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_provider.dart';
import '../network/dio_client.dart';
import 'app_exception.dart';

/// Short, actionable copy instead of raw DioException dumps.
class UserFacingError {
  const UserFacingError({
    required this.title,
    required this.message,
    this.isSession = false,
  });

  final String title;
  final String message;
  final bool isSession;

  static UserFacingError from(Object error, {DioClient? dio}) {
    if (error is AppException) {
      final session = error.code == 'UNAUTHORIZED' ||
          error.message.toLowerCase().contains('sign in');
      return UserFacingError(
        title: session ? 'Session expired' : 'Something went wrong',
        message: error.message,
        isSession: session,
      );
    }

    if (error is DioException) {
      if (dio != null) {
        return from(dio.mapError(error));
      }
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map && data['error'] is Map) {
        final msg = (data['error'] as Map)['message']?.toString().trim();
        if (msg != null && msg.isNotEmpty && status != 401) {
          return UserFacingError(title: 'Could not load', message: msg);
        }
      }
      if (status == 401) {
        return const UserFacingError(
          title: 'Session expired',
          message: 'Please sign in again to continue.',
          isSession: true,
        );
      }
      if (status == 403) {
        return const UserFacingError(
          title: 'No access',
          message: 'You do not have permission for this. Ask your school if you need access.',
        );
      }
      if (status != null && status >= 500) {
        return const UserFacingError(
          title: 'Server busy',
          message: 'Please wait a moment and try again.',
        );
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const UserFacingError(
            title: 'Connection timed out',
            message: 'Check your internet and try again.',
          );
        case DioExceptionType.connectionError:
          return const UserFacingError(
            title: 'No connection',
            message: 'Cannot reach the server. Check Wi‑Fi or mobile data, then try again.',
          );
        default:
          break;
      }
    }

    final text = error.toString();
    if (text.contains('401') ||
        text.toLowerCase().contains('unauthorized') ||
        text.toLowerCase().contains('sign in')) {
      return const UserFacingError(
        title: 'Session expired',
        message: 'Please sign in again to continue.',
        isSession: true,
      );
    }
    if (text.contains('403') || text.toLowerCase().contains('forbidden')) {
      return const UserFacingError(
        title: 'No access',
        message: 'You do not have permission for this. Ask your school if you need access.',
      );
    }
    if (text.contains('SocketException') ||
        text.toLowerCase().contains('connection') ||
        text.startsWith('DioException')) {
      return const UserFacingError(
        title: 'Could not load',
        message: 'Check your connection and try again.',
      );
    }

    // Avoid dumping stack / Dio internals to students.
    if (text.length > 120 || text.contains('Exception') || text.contains('Error:')) {
      return const UserFacingError(
        title: 'Could not load',
        message: 'Something went wrong. Pull to refresh or try again.',
      );
    }
    return UserFacingError(title: 'Could not load', message: text);
  }
}

/// Empty-state style error with Sign in / Try again.
class UserFacingErrorView extends ConsumerWidget {
  const UserFacingErrorView({
    super.key,
    required this.error,
    this.onRetry,
  });

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = UserFacingError.from(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              info.isSession ? Icons.lock_outline : Icons.cloud_off_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 16),
            Text(info.title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              info.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            if (info.isSession)
              FilledButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                child: const Text('Sign in again'),
              )
            else if (onRetry != null)
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
