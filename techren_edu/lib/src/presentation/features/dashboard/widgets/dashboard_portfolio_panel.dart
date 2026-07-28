import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';

/// Compact staff/founder home portfolio banner (branding — not a ranking).
class DashboardPortfolioPanel extends StatelessWidget {
  const DashboardPortfolioPanel({super.key, required this.roleLabel});

  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        border: Border.all(color: context.semantic.border),
        boxShadow: AppShadows.card,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            scheme.surface,
            const Color(0xFF38BDF8).withValues(alpha: 0.10),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1220),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/branding/logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.apartment_outlined,
                size: 28,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TechRen EDU',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$roleLabel portfolio',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.semantic.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
