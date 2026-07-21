import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';
import 'skeleton_loaders.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final muted = context.semantic.textMuted;
    return Semantics(
      label: '$title. $message',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(hidden: true, child: Icon(icon, size: 64, color: AppColors.primary.withValues(alpha: 0.5))),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
            ),
            if (action != null) ...[const SizedBox(height: AppSpacing.lg), action!],
          ],
        ),
      ),
      ),
    );
  }
}

enum LoadingSkeletonKind { spinner, list, table, dashboard, card }

/// Loading placeholder — spinner or shimmer skeleton (Phase D).
class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.message = 'Loading...',
    this.kind = LoadingSkeletonKind.spinner,
  });

  final String message;
  final LoadingSkeletonKind kind;

  @override
  Widget build(BuildContext context) {
    if (kind == LoadingSkeletonKind.list) {
      return Semantics(excludeSemantics: true, label: message, child: const ListSkeleton());
    }
    if (kind == LoadingSkeletonKind.table) {
      return Semantics(excludeSemantics: true, label: message, child: const TableSkeleton());
    }
    if (kind == LoadingSkeletonKind.dashboard) {
      return Semantics(excludeSemantics: true, label: message, child: const DashboardSkeleton());
    }
    if (kind == LoadingSkeletonKind.card) {
      return Semantics(excludeSemantics: true, label: message, child: const CardSkeleton());
    }

    return Semantics(
      label: message,
      liveRegion: true,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: compact ? 56 : 72,
          height: compact ? 56 : 72,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.school_rounded, size: compact ? 32 : 40, color: scheme.primary),
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          AppConstants.appTagline,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.semantic.textMuted,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Shared error panel for AsyncValue / hub failures (audit M15).
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  factory ErrorState.fromError(Object error, {VoidCallback? onRetry}) {
    final message = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    return ErrorState(message: message, onRetry: onRetry);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: '$title. $message',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: scheme.error.withValues(alpha: 0.85)),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.semantic.textMuted,
                    ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.tonalIcon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

