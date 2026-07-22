import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';

class AppUpdateInfo {
  const AppUpdateInfo({required this.latestVersion, required this.downloadSiteUrl});

  final String latestVersion;

  /// Landing page where the user downloads the new installer.
  final Uri downloadSiteUrl;
}

/// scheme://host:port of the API server — the download site is served there too.
Uri _serverOrigin() {
  final api = Uri.parse(ApiConstants.baseUrl);
  return Uri(scheme: api.scheme, host: api.host, port: api.hasPort ? api.port : null);
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
        ? data
        : throw const FormatException('status.json is not an object');
    final latest = map['version']?.toString();
    if (latest == null || latest.isEmpty) return null;
    if (compareVersions(latest, AppConstants.appVersion) <= 0) return null;
    return AppUpdateInfo(latestVersion: latest, downloadSiteUrl: origin);
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
