// Inactive student route policy — see docs/06-NAVIGATION-FLOWS.md §6.

const inactiveStudentDashboardRoute = '/student/dashboard';

const _blockedPrefixes = [
  '/student/learn',
  '/student/learning',
  '/student/words',
  '/student/sentences',
  '/student/listening',
  '/student/video',
  '/student/typing',
  '/student/competition',
  '/student/wallet',
  '/student/exams',
  '/student/feedback',
  '/student/schedule',
  '/student/gamification',
  '/student/quiz',
];

bool isRouteBlockedForInactiveStudent(String path) {
  if (path == '/student/progress' || path.startsWith('/student/progress/')) {
    return true;
  }
  return _blockedPrefixes.any((prefix) => path == prefix || path.startsWith('$prefix/'));
}
