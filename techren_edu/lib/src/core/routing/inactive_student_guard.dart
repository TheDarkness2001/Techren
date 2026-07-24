// Inactive student route policy — see docs/06-NAVIGATION-FLOWS.md §6.

const inactiveStudentDashboardRoute = '/student/dashboard';

const _learningRoutePrefixes = [
  '/student/learn',
  '/student/learning',
  '/student/words',
  '/student/sentences',
  '/student/listening',
  '/student/video',
];

bool isRouteBlockedForInactiveStudent(String path) {
  if (path == '/student/progress' || path.startsWith('/student/progress/')) {
    return true;
  }
  return _learningRoutePrefixes.any((prefix) => path == prefix || path.startsWith('$prefix/'));
}
