import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/routing/student_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/adaptive_scaffold.dart';
import '../../../providers/gamification_provider.dart';
import '../../../providers/progress_provider.dart';
import '../../gamification/widgets/practice_recommendation_banner.dart';
import '../../../../domain/entities/student_progress.dart';
import '../widgets/learn_module_card.dart';

class LearnHubScreen extends ConsumerWidget {
  const LearnHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final navItems = studentNavItemsOf(context);
    final progressAsync = ref.watch(studentProgressOverviewProvider);

    return AdaptiveScaffold(
      title: l10n.navLearn,
      selectedIndex: 1,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(practiceRecommendationProvider);
          ref.invalidate(studentProgressOverviewProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const PracticeRecommendationBanner(),
            const SizedBox(height: AppSpacing.sm),
            progressAsync.when(
              loading: () => _moduleList(context, progress: null),
              error: (_, __) => _moduleList(context, progress: null),
              data: (overview) => _moduleList(context, progress: overview.modules),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleList(BuildContext context, {ModuleProgressSummary? progress}) {
    final modules = progress;
    return Column(
      children: [
        LearnModuleCard(
          module: 'words',
          title: 'Words',
          subtitle: 'Vocabulary practice & class exams',
          icon: Icons.spellcheck_outlined,
          accentColor: AppColors.primary,
          progressPercent: modules?.words.accuracy,
          onTap: () => navigateStudentRoute(context, '/student/words'),
        ),
        const SizedBox(height: AppSpacing.sm),
        LearnModuleCard(
          module: 'sentences',
          title: 'Sentences',
          subtitle: 'Translation with grammar feedback',
          icon: Icons.format_quote_outlined,
          accentColor: AppColors.secondary,
          progressPercent: modules?.sentences.accuracy,
          onTap: () => navigateStudentRoute(context, '/student/sentences'),
        ),
        const SizedBox(height: AppSpacing.sm),
        LearnModuleCard(
          module: 'listening',
          title: 'Listening',
          subtitle: 'Audio transcription practice',
          icon: Icons.headphones_outlined,
          accentColor: const Color(0xFF7C3AED),
          progressPercent: modules?.listening.avgBestAccuracy,
          onTap: () => navigateStudentRoute(context, '/student/listening'),
        ),
        const SizedBox(height: AppSpacing.sm),
        LearnModuleCard(
          module: 'video',
          title: 'Video Lessons',
          subtitle: 'Watch videos & topic tests',
          icon: Icons.play_circle_outline,
          accentColor: AppColors.tertiary,
          progressPercent: modules?.video.avgWatchPercent,
          onTap: () => navigateStudentRoute(context, '/student/video'),
        ),
      ],
    );
  }
}
