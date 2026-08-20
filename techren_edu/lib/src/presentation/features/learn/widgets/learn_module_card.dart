import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/learning_playground.dart';
import '../../gamification/widgets/practice_recommendation_banner.dart';

/// Learn hub module tile in the Words playground style.
class LearnModuleCard extends StatelessWidget {
  const LearnModuleCard({
    super.key,
    required this.module,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.progressPercent,
  });

  final String module;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final int? progressPercent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semantic;
    final progress = ((progressPercent ?? 0).clamp(0, 100)) / 100;
    final compact = MediaQuery.sizeOf(context).height < 820 || MediaQuery.sizeOf(context).width < 1100;
    final planetSize = compact ? 36.0 : 48.0;
    final pad = compact ? AppSpacing.sm : AppSpacing.md;

    return PracticeRecommendationHighlight(
      module: module,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.cardLarge,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: EdgeInsets.all(pad),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: AppRadius.cardLarge,
              border: Border.all(color: semantic.border),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.12),
                  blurRadius: compact ? 10 : 18,
                  offset: Offset(0, compact ? 4 : 8),
                ),
              ],
            ),
            child: Row(
              children: [
                PlaygroundPlanet(color: accentColor, size: planetSize),
                SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: (compact
                                ? Theme.of(context).textTheme.titleSmall
                                : Theme.of(context).textTheme.titleMedium)
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.micro),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: semantic.textMuted)),
                      SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: compact ? 4 : 6,
                          backgroundColor: semantic.surfaceContainer,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.arrow_forward_rounded, size: compact ? 20 : 24, color: semantic.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
