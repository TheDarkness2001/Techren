class AppConstants {
  static const String appName = 'TechRen EDU';
  static const String appTagline = 'Learn smarter, anywhere';

  /// Injected by scripts/build-release-apps.ps1 from pubspec.yaml.
  /// Compared against the server's /downloads/status.json to offer updates.
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );
  static const double compactBreakpoint = 600;
  static const double expandedBreakpoint = 1024;

  /// Max readable width for page content on ultra-wide displays (Phase F.6).
  static const double maxContentWidth = 1280;
}
