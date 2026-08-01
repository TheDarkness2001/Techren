class AppConstants {
  static const String appName = 'TechRen EDU';
  static const String appTagline = 'Learn smarter, anywhere';

  /// Fallback only. Prefer [PackageInfo.version] (from pubspec) for update checks.
  /// Scripts may still pass `--dart-define=APP_VERSION=…` for builds without package_info.
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.9',
  );
  static const double compactBreakpoint = 600;
  static const double expandedBreakpoint = 1024;

  /// Max readable width for page content on ultra-wide displays (Phase F.6).
  static const double maxContentWidth = 1280;
}
