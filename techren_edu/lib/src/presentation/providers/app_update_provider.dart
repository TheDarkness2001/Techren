import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Resolves to update info when the server has a newer build, otherwise null.
/// Never throws — a failed check silently means "no update".
final appUpdateProvider = FutureProvider<AppUpdateInfo?>((ref) async {
  // The web build always serves the latest version, no installer to update.
  if (kIsWeb) return null;

  final origin = _serverOrigin();
  try {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    final response = await dio.getUri<dynamic>(origin.resolve('/downloads/status.json'));
    final data = response.data;
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : throw const FormatException('status.json is not an object');
    final latest = map['version']?.toString();
    if (latest == null || latest.isEmpty) return null;
    if (compareVersions(latest, AppConstants.appVersion) <= 0) return null;

    // Prefer explicit URLs from status.json (usually GitHub Releases — Railway
    // cannot host large APKs/EXEs). Fall back to same-origin only when flagged
    // and no remote URL is set.
    Uri installerUrl({
      required dynamic remoteRaw,
      required String fallback,
      required dynamic localFlag,
      required String localPath,
    }) {
      final remote = remoteRaw?.toString().trim();
      if (remote != null && remote.isNotEmpty) {
        return _uriOrFallback(remote, fallback);
      }
      final available = localFlag == true || localFlag?.toString().toLowerCase() == 'true';
      if (available) return origin.resolve(localPath);
      return Uri.parse(fallback);
    }

    return AppUpdateInfo(
      latestVersion: latest,
      downloadSiteUrl: origin,
      androidApkUrl: installerUrl(
        remoteRaw: map['androidUrl'] ?? map['androidApkUrl'],
        fallback: _githubAndroidApk,
        localFlag: map['android'],
        localPath: '/downloads/techren-edu.apk',
      ),
      windowsSetupUrl: installerUrl(
        remoteRaw: map['windowsUrl'] ?? map['windowsSetupUrl'],
        fallback: _githubWindowsSetup,
        localFlag: map['windows'],
        localPath: '/downloads/TechRenEDU-setup.exe',
      ),
      macosZipUrl: installerUrl(
        remoteRaw: map['macosUrl'] ?? map['macosZipUrl'],
        fallback: _githubMacosZip,
        localFlag: map['macos'],
        localPath: '/downloads/TechRenEDU-macos.zip',
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
  List<int> parse(String v) => v
      .split('+')
      .first
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
