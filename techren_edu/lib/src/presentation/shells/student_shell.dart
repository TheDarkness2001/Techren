import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/routing/student_navigation.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/adaptive_scaffold.dart';
import '../../core/widgets/appearance_controls.dart';
import '../../core/widgets/notification_icon_button.dart';
import '../features/attendance/screens/student_feedback_screen.dart';
import '../features/dashboard/widgets/role_dashboard_body.dart';
import '../features/finance/screens/student_finance_screens.dart';
import '../features/learning/screens/learning_subjects_hub_screen.dart';
import '../features/learning/screens/learning_subject_dashboard_screen.dart';
import '../features/people/widgets/profile_photo_picker.dart';
import '../features/progress/screens/progress_screens.dart';
import '../features/scheduling/screens/schedule_hub_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/identity_provider.dart';
import '../providers/settings_provider.dart';

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final navItems = studentNavItemsFor(l10n);
    final dashboard = ref.watch(dashboardProvider);

    return AdaptiveScaffold(
      title: l10n.navHome,
      selectedIndex: 0,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      actions: [
        const NotificationIconButton(route: '/student/notifications'),
        IconButton(
          icon: const Icon(Icons.military_tech_outlined),
          tooltip: l10n.xpAchievements,
          onPressed: () => context.go('/student/gamification'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _InactiveStudentBanner(),
          Expanded(child: RoleDashboardBody(dashboardAsync: dashboard)),
        ],
      ),
    );
  }
}

class StudentLearnScreen extends StatelessWidget {
  const StudentLearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navItems = studentNavItemsOf(context);
    return LearningSubjectsHubScreen(
      navItems: navItems,
      selectedRoute: '/student/learn',
      isStudent: true,
    );
  }
}

class StudentLearningSubjectScreen extends StatelessWidget {
  const StudentLearningSubjectScreen({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) {
    final navItems = studentNavItemsOf(context);
    return LearningSubjectDashboardScreen(
      navItems: navItems,
      selectedRoute: '/student/learn',
      subjectId: subjectId,
      isStudent: true,
    );
  }
}

class StudentScheduleScreen extends StatelessWidget {
  const StudentScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TimetableScreen(
      type: 'student',
      title: l10n.mySchedule,
      selectedRoute: '/student/schedule',
      selectedIndex: 2,
    );
  }
}

class StudentProgressScreenWrapper extends StatelessWidget {
  const StudentProgressScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentProgressScreen(
      selectedRoute: '/student/progress',
      selectedIndex: 3,
    );
  }
}

class StudentFeedbackScreenWrapper extends StatelessWidget {
  const StudentFeedbackScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentFeedbackScreen(
      selectedRoute: '/student/feedback',
      selectedIndex: 4,
    );
  }
}

class StudentExamsScreenWrapper extends StatelessWidget {
  const StudentExamsScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentExamsScreen(
      selectedRoute: '/student/exams',
      selectedIndex: 4,
    );
  }
}

class StudentPaymentsScreenWrapper extends StatelessWidget {
  const StudentPaymentsScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentPaymentsScreen(
      selectedRoute: '/student/payments',
      selectedIndex: 4,
    );
  }
}

class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final navItems = studentNavItemsFor(l10n);
    final user = ref.watch(authProvider).user;
    final walletEnabled = ref.watch(walletEnabledProvider);

    return AdaptiveScaffold(
      title: l10n.navProfile,
      selectedIndex: 4,
      items: navItems,
      onDestinationSelected: (i) => onStudentNavSelected(context, navItems, i),
      body: ListView(
        padding: AppSpacing.pagePaddingWide,
        children: [
          if (user != null)
            Center(
              child: ProfilePhotoPicker(
                personId: user.id,
                name: user.name,
                profileImage: user.profileImage,
                isStudent: true,
                isActive: !user.isInactiveStudent,
                radius: 48,
                canEdit: false,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(user?.name ?? '', style: Theme.of(context).textTheme.headlineSmall),
          Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.semantic.textMuted)),
          const SizedBox(height: AppSpacing.xs),
          Chip(label: Text(user?.status ?? 'active')),
          const SizedBox(height: AppSpacing.lg),
          const AppearanceControls(),
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            leading: const Icon(Icons.rate_review_outlined),
            title: Text(l10n.teacherFeedback),
            subtitle: Text(l10n.commentsAfterClass),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/student/feedback'),
          ),
          ListTile(
            leading: const Icon(Icons.quiz_outlined),
            title: Text(l10n.myExams),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/student/exams'),
          ),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: Text(l10n.myPayments),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/student/payments'),
          ),
          if (walletEnabled)
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: Text(l10n.myWallet),
              subtitle: Text(l10n.walletSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/student/wallet'),
            ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: Text(l10n.navCompetition),
            subtitle: Text(l10n.competitionSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/student/competition'),
          ),
          ListTile(
            leading: const Icon(Icons.military_tech_outlined),
            title: Text(l10n.xpAchievements),
            subtitle: Text(l10n.gamificationSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/student/gamification'),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.tonalIcon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}

class _InactiveStudentBanner extends ConsumerWidget {
  const _InactiveStudentBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInactive = ref.watch(authProvider).user?.isInactiveStudent ?? false;
    if (!isInactive) return const SizedBox.shrink();

    final warning = Theme.of(context).colorScheme.tertiaryContainer;
    final onWarning = Theme.of(context).colorScheme.onTertiaryContainer;

    return Material(
      color: warning,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: onWarning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                context.l10n.accountInactive,
                style: TextStyle(color: onWarning, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
