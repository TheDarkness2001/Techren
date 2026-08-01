import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';

/// Fallback when status.json omits direct installer URLs (Railway has no big binaries).
const _githubAndroidApk =
    'https://github.com/TheDarkness2001/Techren/releases/latest/download/techren-edu.apk';
const _githubWindowsSetup =
    'https://github.com/TheDarkness2001/Techren/releases/latest/download/TechRenEDU-setup.exe';
const _githubMacosZip =
    'https://github.com/TheDarkness2001/Techren/releases/latest/download/TechRenEDU-macos.zip';
const _githubIosPage =
    'https://github.com/TheDarkness2001/Techren/releases/latest';

const _prefsInstalledUpdateKey = 'app_update_installed_version';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.latestVersion,
    required this.downloadSiteUrl,
    required this.androidApkUrl,
    required this.windowsSetupUrl,
    required this.macosZipUrl,
    required this.iosUpdateUrl,
  });

  final String latestVersion;

  /// Landing page (API host / Railway site).
  final Uri downloadSiteUrl;

  /// Direct APK URL (usually GitHub Releases).
  final Uri androidApkUrl;

  /// Direct Windows setup URL (usually GitHub Releases).
  final Uri windowsSetupUrl;

  /// Direct macOS .app zip URL.
  final Uri macosZipUrl;

  /// TestFlight / App Store / OTA page for iPhone (cannot sideload IPA in-app).
  final Uri iosUpdateUrl;

  /// Platform installer / store page to open when automatic update fails.
  Uri get platformInstallerUrl {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidApkUrl;
      case TargetPlatform.windows:
        return windowsSetupUrl;
      case TargetPlatform.macOS:
        return macosZipUrl;
      case TargetPlatform.iOS:
        return iosUpdateUrl;
      default:
        return downloadSiteUrl;
    }
  }
}

/// scheme://host:port of the API server — the download site is served there too.
Uri _serverOrigin() {
  final api = Uri.parse(ApiConstants.baseUrl);
  return Uri(scheme: api.scheme, host: api.host, port: api.hasPort ? api.port : null);
}

Uri _uriOrFallback(dynamic raw, String fallback) {
  final text = raw?.toString().trim();
  if (text != null && text.isNotEmpty) {
    final parsed = Uri.tryParse(text);
    if (parsed != null && parsed.hasScheme) return parsed;
  }
  return Uri.parse(fallback);
}

/// Strip BOM / leading "v" / whitespace so status.json and PackageInfo compare cleanly.
String normalizeVersion(String raw) {
  var v = raw.trim();
  if (v.isNotEmpty && v.codeUnitAt(0) == 0xFEFF) {
    v = v.substring(1).trim();
  }
  if (v.length > 1 && (v.startsWith('v') || v.startsWith('V'))) {
    v = v.substring(1).trim();
  }
  return v.split('+').first.trim();
}

/// Installed app version from the platform package (pubspec), with dart-define fallback.
Future<String> installedAppVersion() async {
  try {
    final info = await PackageInfo.fromPlatform();
    final v = normalizeVersion(info.version);
    if (v.isNotEmpty) return v;
  } catch (_) {
    // Fall through — e.g. tests / unsupported platform.
  }
  return normalizeVersion(AppConstants.appVersion);
}

/// Call after a successful in-app install so the banner hides even before relaunch.
Future<void> markUpdateInstalled(String version) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefsInstalledUpdateKey, normalizeVersion(version));
}

Future<String?> _markedInstalledVersion() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsInstalledUpdateKey);
    if (raw == null || raw.isEmpty) return null;
    return normalizeVersion(raw);
  } catch (_) {
    return null;
  }
}

/// Resolves to update info when the server has a newer build, otherwise null.
/// Never throws — a failed check silently means "no update".
final appUpdateProvider = FutureProvider<AppUpdateInfo?>((ref) async {
  // The web build always serves the latest version, no installer to update.
  if (kIsWeb) return null;

  final origin = _serverOrigin();
  try {
    final current = await installedAppVersion();
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: const {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
    ));
    final response = await dio.getUri<dynamic>(
      origin.resolve('/downloads/status.json'),
      options: Options(
        headers: const {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
      ),
    );
    final data = response.data;
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : throw const FormatException('status.json is not an object');
    final latestRaw = map['version']?.toString();
    if (latestRaw == null || latestRaw.trim().isEmpty) return null;
    final latest = normalizeVersion(latestRaw);

    // Hide when this device already runs latest (or newer).
    if (compareVersions(latest, current) <= 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsInstalledUpdateKey);
      return null;
    }

    // Hide after a successful install for this version (covers post-install
    // before OS relaunches, and Windows builds that lagged the APK version).
    final marked = await _markedInstalledVersion();
    if (marked != null && compareVersions(latest, marked) <= 0) {
      return null;
    }

    // Always use explicit remote installer URLs (GitHub Releases). Never point
    // the app at Railway /downloads/*.apk — those files are not deployed there.
    return AppUpdateInfo(
      latestVersion: latest,
      downloadSiteUrl: origin,
      androidApkUrl: _uriOrFallback(
        map['androidUrl'] ?? map['androidApkUrl'],
        _githubAndroidApk,
      ),
      windowsSetupUrl: _uriOrFallback(
        map['windowsUrl'] ?? map['windowsSetupUrl'],
        _githubWindowsSetup,
      ),
      macosZipUrl: _uriOrFallback(
        map['macosUrl'] ?? map['macosZipUrl'],
        _githubMacosZip,
      ),
      iosUpdateUrl: _uriOrFallback(
        map['iosUrl'] ?? map['iosUpdateUrl'],
        _githubIosPage,
      ),
    );
  } catch (_) {
    return null;
  }
});

/// Compares dotted versions ("1.2.3", build suffix after "+" ignored).
/// Returns >0 when [a] is newer than [b].
@visibleForTesting
int compareVersions(String a, String b) {
  List<int> parse(String v) => normalizeVersion(v)
      .split('.')
      .map((part) => int.tryParse(part.trim()) ?? 0)
      .toList();
  final pa = parse(a);
  final pb = parse(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}
