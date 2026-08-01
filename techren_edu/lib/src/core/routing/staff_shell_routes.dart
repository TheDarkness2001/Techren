import 'package:go_router/go_router.dart';

import '../../presentation/features/competition/screens/competition_hub_screen.dart';
import '../../presentation/features/exams/screens/staff_exams_screen.dart';
import '../../presentation/features/finance/screens/revenue_reports_screen.dart';
import '../../presentation/features/learning/screens/learning_subject_dashboard_screen.dart';
import '../../presentation/features/learning/screens/learning_subjects_hub_screen.dart';
import '../../presentation/features/learning_cms/screens/learning_cms_screen.dart';
import '../../presentation/features/notifications/screens/notifications_screen.dart';
import '../../presentation/features/notifications/screens/parent_notification_settings_screen.dart';
import '../../presentation/features/progress/screens/progress_screens.dart';
import '../../presentation/features/recycle_bin/screens/recycle_bin_screen.dart';
import '../../presentation/features/sentences/screens/staff_sentences_hub_screen.dart';
import '../../presentation/features/settings/screens/platform_settings_screen.dart';
import '../../presentation/features/staff_finance/screens/staff_finance_hub_screen.dart';
import '../../presentation/features/staff_ops/screens/staff_ops_screens.dart';
import '../../presentation/features/upload/screens/content_import_screen.dart';
import '../../presentation/features/wallet/screens/wallet_screen.dart';
import '../../presentation/features/words/screens/staff_words_hub_screen.dart';
import '../../presentation/features/ielts/screens/ielts_hub_screen.dart';
import '../../presentation/features/ielts/screens/ielts_exam_player_screen.dart';
import '../../presentation/features/ielts/screens/ielts_results_screen.dart';
import '../../presentation/features/ielts/screens/ielts_manage_screen.dart';
import '../../presentation/features/ielts/screens/ielts_exam_editor_screen.dart';
import '../../presentation/features/ielts/screens/ielts_access_screen.dart';
import '../../presentation/features/ielts/screens/ielts_sources_screen.dart';
import '../../presentation/features/ielts/screens/ielts_bank_screen.dart';
import '../../presentation/features/ielts/screens/ielts_analytics_screen.dart';
import '../../presentation/features/quiz/screens/quiz_hub_screen.dart';
import '../../presentation/features/quiz/screens/quiz_manage_screen.dart';
import '../../presentation/features/quiz/screens/quiz_player_screen.dart';
import '../../presentation/features/video/screens/video_learning_hub_screen.dart';
import '../widgets/adaptive_scaffold.dart';
import 'app_page_transitions.dart';

/// Shared admin/founder ops routes — same screens, different path prefix + nav.
List<GoRoute> buildSharedStaffOpsRoutes({
  required String prefix,
  required List<NavItem> navItems,
}) {
  String r(String suffix) => '$prefix$suffix';

  return [
    AppPageTransitions.route(
      path: r('/attendance'),
      redirect: (_, __) => r('/attendance/students'),
    ),
    AppPageTransitions.route(
      path: r('/attendance/students'),
      builder: (_, __) => StaffStudentAttendanceScreen(
        navItems: navItems,
        selectedRoute: r('/attendance/students'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/attendance/teachers'),
      builder: (_, __) => StaffTeacherAttendanceScreen(
        navItems: navItems,
        selectedRoute: r('/attendance/teachers'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/feedback'),
      builder: (_, __) => StaffFeedbackScreen(navItems: navItems, selectedRoute: r('/feedback')),
    ),
    AppPageTransitions.route(
      path: r('/exams'),
      builder: (_, __) => StaffExamsScreen(navItems: navItems, selectedRoute: r('/exams')),
    ),
    AppPageTransitions.route(
      path: r('/competition'),
      builder: (_, __) => CompetitionHubScreen(
        navItems: navItems,
        selectedRoute: r('/competition'),
        canDistributeBonuses: true,
      ),
    ),
    AppPageTransitions.route(
      path: r('/staff-finance'),
      builder: (_, __) => StaffFinanceHubScreen(
        navItems: navItems,
        selectedRoute: r('/staff-finance'),
        canManage: true,
      ),
    ),
    AppPageTransitions.route(
      path: r('/recycle-bin'),
      builder: (_, __) => RecycleBinScreen(navItems: navItems, selectedRoute: r('/recycle-bin')),
    ),
    AppPageTransitions.route(
      path: r('/notifications'),
      builder: (_, __) => NotificationsScreen(navItems: navItems, selectedRoute: r('/notifications')),
    ),
    AppPageTransitions.route(
      path: r('/parent-notification-settings'),
      builder: (_, __) => ParentNotificationSettingsScreen(
        navItems: navItems,
        selectedRoute: r('/parent-notification-settings'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/wallet'),
      builder: (_, __) => AdminWalletScreen(navItems: navItems, selectedRoute: r('/wallet')),
    ),
    AppPageTransitions.route(
      path: r('/content-import'),
      builder: (_, __) => ContentImportScreen(navItems: navItems, selectedRoute: r('/content-import')),
    ),
    AppPageTransitions.route(
      path: r('/settings'),
      builder: (_, __) => PlatformSettingsScreen(navItems: navItems, selectedRoute: r('/settings')),
    ),
    AppPageTransitions.route(
      path: r('/progress'),
      builder: (_, __) => AdminProgressScreen(navItems: navItems, selectedRoute: r('/progress')),
    ),
    AppPageTransitions.route(
      path: r('/progress/student/:studentId'),
      builder: (_, state) => StaffStudentProgressScreen(
        studentId: state.pathParameters['studentId']!,
        navItems: navItems,
        selectedRoute: r('/progress'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/sentences'),
      builder: (_, __) => StaffSentencesHubScreen(navItems: navItems, selectedRoute: r('/sentences')),
    ),
    AppPageTransitions.route(
      path: r('/words'),
      builder: (_, __) => StaffWordsHubScreen(navItems: navItems, selectedRoute: r('/words')),
    ),
    AppPageTransitions.route(
      path: r('/learning'),
      builder: (_, __) => LearningSubjectsHubScreen(navItems: navItems, selectedRoute: r('/learning')),
    ),
    // Deep subject routes before `/learning/:subjectId` for reliable matching.
    AppPageTransitions.route(
      path: r('/learning/:subjectId/ielts/manage'),
      builder: (_, state) => IeltsManageScreen(
        subjectId: state.pathParameters['subjectId']!,
        routePrefix: prefix,
        navItems: navItems,
        selectedRoute: r('/learning'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/ielts/manage/:examId'),
      builder: (_, state) => IeltsExamEditorScreen(
        subjectId: state.pathParameters['subjectId']!,
        examId: state.pathParameters['examId']!,
        routePrefix: prefix,
        navItems: navItems,
        selectedRoute: r('/learning'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/ielts'),
      builder: (_, state) => IeltsHubScreen(
        subjectId: state.pathParameters['subjectId']!,
        isStudent: false,
        routePrefix: prefix,
        navItems: navItems,
        selectedRoute: r('/learning'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/video'),
      builder: (_, state) => VideoLearningHubScreen(
        subjectId: state.pathParameters['subjectId']!,
        isStudent: false,
        routePrefix: prefix,
        navItems: navItems,
        selectedRoute: r('/learning'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/ielts/exams'),
      builder: (_, state) => IeltsExamListScreen(
        subjectId: state.pathParameters['subjectId']!,
        isStudent: false,
        routePrefix: prefix,
        navItems: navItems,
        selectedRoute: r('/learning'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/ielts/listening'),
      builder: (_, state) => IeltsExamListScreen(
        subjectId: state.pathParameters['subjectId']!,
        mode: 'listening',
        isStudent: false,
        routePrefix: prefix,
        navItems: navItems,
        selectedRoute: r('/learning'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/ielts/reading'),
      builder: (_, state) => IeltsExamListScreen(
        subjectId: state.pathParameters['subjectId']!,
        mode: 'reading',
        isStudent: false,
        routePrefix: prefix,
        navItems: navItems,
        selectedRoute: r('/learning'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/ielts/writing'),
      builder: (_, state) => IeltsExamListScreen(
        subjectId: state.pathParameters['subjectId']!,
        mode: 'writing',
        isStudent: false,
        routePrefix: prefix,
        navItems: navItems,
        selectedRoute: r('/learning'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/ielts/history'),
      builder: (_, state) => IeltsHistoryScreen(
        subjectId: state.pathParameters['subjectId']!,
        routePrefix: prefix,
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/ielts/access'),
      builder: (_, state) => IeltsAccessScreen(
        subjectId: state.pathParameters['subjectId'],
        routePrefix: prefix,
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/ielts/sources'),
      builder: (_, state) => IeltsSourcesScreen(
        subjectId: state.pathParameters['subjectId']!,
        routePrefix: prefix,
        navItems: navItems,
        selectedRoute: r('/learning'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/ielts/bank'),
      builder: (_, state) => IeltsBankScreen(
        subjectId: state.pathParameters['subjectId']!,
        routePrefix: prefix,
        navItems: navItems,
        selectedRoute: r('/learning'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/ielts/analytics'),
      builder: (_, state) => IeltsAnalyticsScreen(
        subjectId: state.pathParameters['subjectId']!,
        isStudent: false,
        routePrefix: prefix,
        navItems: navItems,
        selectedRoute: r('/learning'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/ielts/writing-review'),
      builder: (_, state) => IeltsWritingReviewScreen(
        subjectId: state.pathParameters['subjectId']!,
        routePrefix: prefix,
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/ielts/play/:examId'),
      builder: (_, state) => IeltsExamPlayerScreen(
        subjectId: state.pathParameters['subjectId']!,
        examId: state.pathParameters['examId']!,
        routePrefix: prefix,
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/ielts/results/:attemptId'),
      builder: (_, state) => IeltsResultsScreen(
        subjectId: state.pathParameters['subjectId']!,
        attemptId: state.pathParameters['attemptId']!,
        routePrefix: prefix,
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/quiz'),
      builder: (_, state) => QuizHubScreen(
        subjectId: state.pathParameters['subjectId']!,
        isStudent: false,
        routePrefix: prefix,
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/quiz/manage'),
      builder: (_, state) => QuizManageScreen(
        subjectId: state.pathParameters['subjectId']!,
        routePrefix: prefix,
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/quiz/manage/:quizId'),
      builder: (_, state) => QuizManageScreen(
        subjectId: state.pathParameters['subjectId']!,
        routePrefix: prefix,
        quizId: state.pathParameters['quizId'],
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/quiz/play/:quizId'),
      builder: (_, state) => QuizPlayerScreen(
        subjectId: state.pathParameters['subjectId']!,
        quizId: state.pathParameters['quizId']!,
        isStudent: false,
        routePrefix: prefix,
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId/quiz/results/:attemptId'),
      builder: (_, state) => QuizResultsScreen(
        subjectId: state.pathParameters['subjectId']!,
        attemptId: state.pathParameters['attemptId']!,
        routePrefix: prefix,
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning/:subjectId'),
      builder: (_, state) => LearningSubjectDashboardScreen(
        navItems: navItems,
        selectedRoute: r('/learning'),
        subjectId: state.pathParameters['subjectId']!,
      ),
    ),
    AppPageTransitions.route(
      path: r('/learning-cms'),
      builder: (_, __) => LearningCmsScreen(
        navItems: navItems,
        selectedRoute: r('/learning-cms'),
        importRoute: r('/content-import'),
      ),
    ),
    AppPageTransitions.route(
      path: r('/revenue-reports'),
      builder: (_, __) => RevenueReportsScreen(navItems: navItems, selectedRoute: r('/revenue-reports')),
    ),
  ];
}
