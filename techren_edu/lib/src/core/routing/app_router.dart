import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/app_user.dart';
import '../../presentation/features/auth/screens/login_screen.dart';
import '../../presentation/features/auth/screens/splash_screen.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/settings_provider.dart';
import '../../presentation/shells/staff_shell.dart';
import '../../presentation/shells/student_shell.dart';
import '../../presentation/shells/teacher_shell.dart';
import '../../presentation/features/words/screens/words_hub_screen.dart';
import '../../presentation/features/words/screens/words_leaderboard_screen.dart';
import '../../presentation/features/sentences/screens/sentences_hub_screen.dart';
import '../../presentation/features/sentences/screens/sentences_leaderboard_screen.dart';
import '../../presentation/features/listening/screens/listening_hub_screen.dart';
import '../../presentation/features/listening/screens/listening_leaderboard_screen.dart';
import '../../presentation/features/video/screens/video_hub_screen.dart';
import '../../presentation/features/competition/screens/competition_hub_screen.dart';
import '../../presentation/features/competition/screens/student_competition_screen.dart';
import '../../presentation/features/staff_finance/screens/staff_finance_hub_screen.dart';
import '../../presentation/features/notifications/screens/notifications_screen.dart';
import '../../presentation/features/gamification/screens/gamification_hub_screen.dart';
import '../../presentation/shells/parent_shell.dart';
import '../../presentation/features/wallet/screens/wallet_screen.dart';
import '../../presentation/features/upload/screens/content_import_screen.dart';
import '../../presentation/features/learning_cms/screens/learning_cms_screen.dart';
import 'inactive_student_guard.dart';
import 'app_page_transitions.dart';
import 'staff_route_guard.dart';
import 'staff_shell_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Keep a single GoRouter instance. Auth/settings changes only refresh redirects.
  final refresh = _RouterRefreshListenable(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final settings = ref.read(platformSettingsProvider).valueOrNull;
      final status = authState.status;
      final path = state.uri.path;
      final isAuthRoute = path == '/login' || path == '/splash';

      if (status == AuthStatus.unknown) {
        return path == '/splash' ? null : '/splash';
      }

      if (status == AuthStatus.unauthenticated) {
        return isAuthRoute && path == '/login' ? null : '/login';
      }

      if (isAuthRoute) {
        return _homeForUser(authState.user!);
      }

      final inactiveRedirect = _inactiveStudentRouteGuard(authState.user!, path);
      if (inactiveRedirect != null) return inactiveRedirect;

      final rolePerms = settings?.rolePermissions[authState.user!.role?.name] ?? {};
      final staffRedirect = staffRouteGuard(authState.user!, path, rolePerms);
      if (staffRedirect != null) return staffRedirect;

      return _guardRoute(authState.user!, path);
    },
    routes: [
      AppPageTransitions.route(path: '/splash', builder: (_, __) => const SplashScreen()),
      AppPageTransitions.route(path: '/login', builder: (_, __) => const LoginScreen()),
      AppPageTransitions.route(path: '/student/dashboard', builder: (_, __) => const StudentDashboardScreen()),
      AppPageTransitions.route(path: '/student/learn', builder: (_, __) => const StudentLearnScreen()),
      // Legacy path used by older builds / mistaken /learning links.
      AppPageTransitions.route(
        path: '/student/learning/:subjectId',
        redirect: (_, state) => '/student/learn/${state.pathParameters['subjectId']}',
      ),
      AppPageTransitions.route(
        path: '/student/learn/:subjectId',
        builder: (_, state) => StudentLearningSubjectScreen(
          subjectId: state.pathParameters['subjectId']!,
        ),
      ),
      AppPageTransitions.route(
        path: '/student/words',
        builder: (_, __) => const WordsHubScreen(selectedRoute: '/student/words'),
      ),
      AppPageTransitions.route(path: '/student/words/leaderboard', builder: (_, __) => const WordsLeaderboardScreen()),
      AppPageTransitions.route(path: '/student/sentences', builder: (_, __) => const SentencesHubScreen()),
      AppPageTransitions.route(path: '/student/sentences/leaderboard', builder: (_, __) => const SentencesLeaderboardScreen()),
      AppPageTransitions.route(path: '/student/listening', builder: (_, __) => const ListeningHubScreen()),
      AppPageTransitions.route(path: '/student/listening/leaderboard', builder: (_, __) => const ListeningLeaderboardScreen()),
      AppPageTransitions.route(path: '/student/video', builder: (_, __) => const VideoHubScreen()),
      AppPageTransitions.route(path: '/student/schedule', builder: (_, __) => const StudentScheduleScreen()),
      AppPageTransitions.route(path: '/student/feedback', builder: (_, __) => const StudentFeedbackScreenWrapper()),
      AppPageTransitions.route(path: '/student/exams', builder: (_, __) => const StudentExamsScreenWrapper()),
      AppPageTransitions.route(path: '/student/payments', builder: (_, __) => const StudentPaymentsScreenWrapper()),
      AppPageTransitions.route(
        path: '/student/wallet',
        builder: (_, __) => const StudentWalletScreen(selectedRoute: '/student/wallet'),
      ),
      AppPageTransitions.route(
        path: '/student/competition',
        builder: (_, __) => const StudentCompetitionScreen(selectedRoute: '/student/competition'),
      ),
      AppPageTransitions.route(path: '/student/profile', builder: (_, __) => const StudentProfileScreen()),
      AppPageTransitions.route(
        path: '/student/notifications',
        builder: (_, __) => const NotificationsScreen(selectedRoute: '/student/notifications'),
      ),
      AppPageTransitions.route(
        path: '/student/gamification',
        builder: (_, __) => const GamificationHubScreen(selectedRoute: '/student/gamification'),
      ),
      AppPageTransitions.route(
        path: '/student/progress',
        builder: (_, __) => const StudentProgressScreenWrapper(),
      ),
      AppPageTransitions.route(path: '/teacher/dashboard', builder: (_, __) => const TeacherDashboardScreen()),
      AppPageTransitions.route(path: '/teacher/classes', builder: (_, __) => const TeacherClassesScreen()),
      AppPageTransitions.route(path: '/teacher/attendance', builder: (_, __) => const TeacherAttendanceScreen()),
      AppPageTransitions.route(
        path: '/teacher/competition',
        builder: (_, __) => const CompetitionHubScreen(navItems: teacherNavItems, selectedRoute: '/teacher/competition'),
      ),
      AppPageTransitions.route(
        path: '/teacher/staff-finance',
        builder: (_, __) => const StaffFinanceHubScreen(navItems: teacherNavItems, selectedRoute: '/teacher/staff-finance'),
      ),
      AppPageTransitions.route(path: '/teacher/profile', builder: (_, __) => const TeacherProfileScreen()),
      AppPageTransitions.route(
        path: '/teacher/learning-cms',
        builder: (_, __) => const LearningCmsScreen(
          navItems: teacherNavItems,
          selectedRoute: '/teacher/learning-cms',
          importRoute: '/teacher/content-import',
        ),
      ),
      AppPageTransitions.route(
        path: '/teacher/content-import',
        builder: (_, __) => const ContentImportScreen(navItems: teacherNavItems, selectedRoute: '/teacher/content-import'),
      ),
      AppPageTransitions.route(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardScreen()),
      AppPageTransitions.route(path: '/admin/people', builder: (_, __) => const AdminPeopleScreen()),
      AppPageTransitions.route(path: '/admin/schedule', redirect: (_, __) => '/admin/schedule/timetable'),
      AppPageTransitions.route(
        path: '/admin/schedule/groups',
        builder: (_, __) => const AdminScheduleScreen(selectedRoute: '/admin/schedule/groups'),
      ),
      AppPageTransitions.route(
        path: '/admin/schedule/schedules',
        redirect: (_, __) => '/admin/schedule/groups',
      ),
      AppPageTransitions.route(
        path: '/admin/schedule/timetable',
        builder: (_, __) => const AdminScheduleScreen(selectedRoute: '/admin/schedule/timetable'),
      ),
      AppPageTransitions.route(path: '/admin/more', builder: (_, __) => const AdminMoreScreen()),
      ...buildSharedStaffOpsRoutes(prefix: '/admin', navItems: adminNavItems),
      AppPageTransitions.route(path: '/founder/dashboard', builder: (_, __) => const FounderDashboardScreen()),
      AppPageTransitions.route(path: '/founder/branches', builder: (_, __) => const FounderBranchesScreen()),
      AppPageTransitions.route(path: '/founder/people', builder: (_, __) => const FounderPeopleScreen()),
      AppPageTransitions.route(path: '/founder/schedule', redirect: (_, __) => '/founder/schedule/timetable'),
      AppPageTransitions.route(
        path: '/founder/schedule/groups',
        builder: (_, __) => const FounderScheduleScreen(selectedRoute: '/founder/schedule/groups'),
      ),
      AppPageTransitions.route(
        path: '/founder/schedule/schedules',
        redirect: (_, __) => '/founder/schedule/groups',
      ),
      AppPageTransitions.route(
        path: '/founder/schedule/timetable',
        builder: (_, __) => const FounderScheduleScreen(selectedRoute: '/founder/schedule/timetable'),
      ),
      AppPageTransitions.route(path: '/founder/more', builder: (_, __) => const FounderMoreScreen()),
      ...buildSharedStaffOpsRoutes(prefix: '/founder', navItems: founderNavItems),
      AppPageTransitions.route(path: '/parent/home', builder: (_, __) => const ParentHomeScreen()),
      AppPageTransitions.route(
        path: '/parent/child/:studentId',
        redirect: (_, state) => '/parent/child/${state.pathParameters['studentId']}/overview',
      ),
      AppPageTransitions.route(
        path: '/parent/child/:studentId/overview',
        builder: (_, state) => ParentChildOverviewScreen(studentId: state.pathParameters['studentId']!),
      ),
      AppPageTransitions.route(
        path: '/parent/child/:studentId/feedback',
        builder: (_, state) => ParentChildFeedbackScreen(studentId: state.pathParameters['studentId']!),
      ),
      AppPageTransitions.route(
        path: '/parent/child/:studentId/attendance',
        builder: (_, state) => ParentChildAttendanceScreen(studentId: state.pathParameters['studentId']!),
      ),
      AppPageTransitions.route(
        path: '/parent/child/:studentId/exams',
        builder: (_, state) => ParentChildExamsScreen(studentId: state.pathParameters['studentId']!),
      ),
    ],
  );
});

String _homeForUser(AppUser user) {
  if (user.isParent) return '/parent/home';
  if (user.isStudent) return '/student/dashboard';
  if (user.isFounder) return '/founder/dashboard';
  if (user.usesAdminShell) return '/admin/dashboard';
  if (user.isTeacher) return '/teacher/dashboard';
  return '/admin/dashboard';
}

String? _inactiveStudentRouteGuard(AppUser user, String path) {
  if (user.isInactiveStudent && isRouteBlockedForInactiveStudent(path)) {
    return inactiveStudentDashboardRoute;
  }
  return null;
}

String? _guardRoute(AppUser user, String path) {
  if (user.isParent && !path.startsWith('/parent')) return '/parent/home';
  if (user.isStudent && !path.startsWith('/student')) return '/student/dashboard';
  if (user.isFounder && !path.startsWith('/founder')) return '/founder/dashboard';
  if (user.usesAdminShell && !path.startsWith('/admin')) {
    return '/admin/dashboard';
  }
  if (user.isTeacher && !path.startsWith('/teacher')) return '/teacher/dashboard';
  return null;
}

class _RouterRefreshListenable extends ChangeNotifier {
  _RouterRefreshListenable(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    _ref.listen(platformSettingsProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
