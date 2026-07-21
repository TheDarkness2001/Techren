import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_radius.dart';
import '../theme/app_semantic_colors.dart';
import '../theme/app_spacing.dart';

class _ShimmerPalette {
  _ShimmerPalette(BuildContext context)
      : base = Theme.of(context).colorScheme.surfaceContainerHighest,
        highlight = Theme.of(context).colorScheme.surface,
        border = context.semantic.border,
        accent = Theme.of(context).colorScheme.surfaceContainerHigh;
  final Color base;
  final Color highlight;
  final Color border;
  final Color accent;
}

/// Shimmer skeleton loaders — Phase D replaces bare spinners for premium loading UX.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, required this.width, required this.height, this.radius = AppRadius.sm});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = _ShimmerPalette(context);
    return Shimmer.fromColors(
      baseColor: palette.base,
      highlightColor: palette.highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: palette.base,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      excludeSemantics: true,
      label: 'Loading content',
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, __) => const _ListSkeletonTile(),
      ),
    );
  }
}

class _ListSkeletonTile extends StatelessWidget {
  const _ListSkeletonTile();

  @override
  Widget build(BuildContext context) {
    final palette = _ShimmerPalette(context);
    return Shimmer.fromColors(
      baseColor: palette.base,
      highlightColor: palette.highlight,
      child: Container(
        height: 72,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: palette.base,
          borderRadius: AppRadius.card,
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.accent,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 12, width: 140, color: palette.accent),
                  const SizedBox(height: AppSpacing.xs),
                  Container(height: 10, width: 200, color: palette.accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TableSkeleton extends StatelessWidget {
  const TableSkeleton({super.key, this.rows = 8, this.columns = 5});

  final int rows;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final palette = _ShimmerPalette(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: palette.base,
            highlightColor: palette.highlight,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: palette.base,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.separated(
              itemCount: rows,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
              itemBuilder: (_, __) => Shimmer.fromColors(
                baseColor: palette.base,
                highlightColor: palette.highlight,
                child: Row(
                  children: [
                    for (var i = 0; i < columns; i++)
                      Expanded(
                        child: Container(
                          height: 36,
                          margin: EdgeInsets.only(right: i < columns - 1 ? AppSpacing.sm : 0),
                          color: palette.accent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key, this.height = 120});

  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = _ShimmerPalette(context);
    return Shimmer.fromColors(
      baseColor: palette.base,
      highlightColor: palette.highlight,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: palette.base,
          borderRadius: AppRadius.card,
          border: Border.all(color: palette.border),
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 280, height: 28, radius: AppRadius.sm),
          const SizedBox(height: AppSpacing.xs),
          const ShimmerBox(width: 360, height: 16, radius: AppRadius.sm),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 800 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 2.4,
                children: List.generate(columns * 2, (_) => const ShimmerBox(width: double.infinity, height: 88)),
              );
            },
          ),
        ],
      ),
    );
  }
}
