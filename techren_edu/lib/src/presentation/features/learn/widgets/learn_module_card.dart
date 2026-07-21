import 'package:flutter/material.dart';

import '../../../../core/widgets/app_hub_card.dart';
import '../../gamification/widgets/practice_recommendation_banner.dart';

/// Learn hub module tile — wraps [AppHubCard] with gamification highlight (Phase F.1).
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
    return PracticeRecommendationHighlight(
      module: module,
      child: AppHubCard(
        title: title,
        subtitle: subtitle,
        accentColor: accentColor,
        icon: icon,
        progressPercent: progressPercent,
        onTap: onTap,
      ),
    );
  }
}
