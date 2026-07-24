import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:5002/api/v1',
  );

  // Railway (and some mobile networks) can take 10–20s+ for TLS/connect;
  // 15s was aborting healthy-but-slow requests as "connection timeout".
  static const Duration connectTimeout = Duration(seconds: 45);
  static const Duration receiveTimeout = Duration(seconds: 60);

  /// Fail fast in release if the API is still pointing at localhost / plain HTTP.
  static void assertReleaseConfig() {
    if (!kReleaseMode) return;
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || uri.scheme != 'https') {
      throw StateError(
        'Release builds require --dart-define=API_BASE_URL=https://... '
        '(got: $baseUrl)',
      );
    }
    if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
      throw StateError('Release builds must not use a localhost API_BASE_URL');
    }
  }
}
