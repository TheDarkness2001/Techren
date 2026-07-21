import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/gamification.dart';
import '../../../providers/gamification_provider.dart';
import '../../../providers/settings_provider.dart';

String studentRouteForRecommendedModule(String module) {
  switch (module) {
    case 'sentences':
      return '/student/sentences';
    case 'listening':
      return '/student/listening';
    case 'video':
      return '/student/video';
    case 'words':
    default:
      return '/student/words';
  }
}

void openRecommendedModule(BuildContext context, PracticeRecommendation recommendation) {
  context.go(studentRouteForRecommendedModule(recommendation.recommendedModule));
}

class PracticeRecommendationBanner extends ConsumerWidget {
  const PracticeRecommendationBanner({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(platformSettingsProvider).valueOrNull?.featureFlags.gamificationEnabled ?? true;
    if (!enabled) return const SizedBox.shrink();

    final recommendationAsync = ref.watch(practiceRecommendationProvider);

    return recommendationAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (recommendation) => Padding(
        padding: compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
        child: PracticeRecommendationCard(
          recommendation: recommendation,
          onTap: () => openRecommendedModule(context, recommendation),
        ),
      ),
    );
  }
}

class PracticeRecommendationCard extends StatelessWidget {
  const PracticeRecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
  });

  final PracticeRecommendation recommendation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryContainer.withValues(alpha: 0.35),
      child: ListTile(
        leading: Icon(_iconForModule(recommendation.recommendedModule), color: AppColors.primary),
        title: Text('Practice: ${recommendation.title}'),
        subtitle: Text(recommendation.reason),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  IconData _iconForModule(String module) {
    switch (module) {
      case 'sentences':
        return Icons.translate;
      case 'listening':
        return Icons.headphones;
      case 'video':
        return Icons.play_circle_outline;
      case 'words':
      default:
        return Icons.abc;
    }
  }
}

class PracticeRecommendationHighlight extends ConsumerWidget {
  const PracticeRecommendationHighlight({
    super.key,
    required this.module,
    required this.child,
  });

  final String module;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(platformSettingsProvider).valueOrNull?.featureFlags.gamificationEnabled ?? true;
    if (!enabled) return child;

    final recommendationAsync = ref.watch(practiceRecommendationProvider);
    final isRecommended = recommendationAsync.maybeWhen(
      data: (rec) => rec.recommendedModule == module,
      orElse: () => false,
    );

    if (!isRecommended) return child;

    return Stack(
      children: [
        child,
        Positioned(
          top: 8,
          right: 8,
          child: Chip(
            label: const Text('Suggested', style: TextStyle(fontSize: 11)),
            backgroundColor: AppColors.primaryContainer,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
