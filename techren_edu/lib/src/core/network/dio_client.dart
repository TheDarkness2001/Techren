import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../errors/app_exception.dart';
import '../storage/secure_storage_service.dart';

typedef SessionExpiredCallback = void Function();

class DioClient {
  DioClient(
    this._storage, {
    SessionExpiredCallback? onSessionExpired,
  }) : _onSessionExpired = onSessionExpired {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Public auth calls must not send stale Bearer tokens.
          if (!_isPublicAuthPath(options.path)) {
            final token = await _storage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } else {
            options.headers.remove('Authorization');
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final path = error.requestOptions.path;

          // Never try session refresh against login/refresh endpoints.
          if (status == 401 && !_isPublicAuthPath(path)) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final opts = error.requestOptions;
              final token = await _storage.getAccessToken();
              if (token != null) {
                opts.headers['Authorization'] = 'Bearer $token';
              }
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {
                // Fall through and surface original error.
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final SecureStorageService _storage;
  SessionExpiredCallback? _onSessionExpired;
  late final Dio _dio;
  Future<bool>? _refreshFuture;

  Dio get dio => _dio;

  set onSessionExpired(SessionExpiredCallback? callback) {
    _onSessionExpired = callback;
  }

  static bool _isPublicAuthPath(String path) {
    final normalized = path.toLowerCase();
    return normalized.contains('/auth/login') ||
        normalized.contains('/auth/teacher/login') ||
        normalized.contains('/auth/student/login') ||
        normalized.contains('/auth/parent/login') ||
        normalized.contains('/auth/refresh');
  }

  /// Queues concurrent 401s onto a single refresh attempt.
  Future<bool> _tryRefresh() {
    return _refreshFuture ??= _doRefresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<bool> _doRefresh() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _failSession();
        return false;
      }

      final response = await Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
        ),
      ).post('/auth/refresh', data: {'refreshToken': refreshToken});

      final data = response.data['data'] as Map<String, dynamic>;
      await _storage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: refreshToken,
      );
      return true;
    } catch (_) {
      await _failSession();
      return false;
    }
  }

  Future<void> _failSession() async {
    // Only drop auth tokens — avoid wiping unrelated prefs/session keys.
    await _storage.clearTokens();
    _onSessionExpired?.call();
  }

  AppException mapError(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return AppException(
        err['message']?.toString() ?? 'Request failed',
        code: err['code']?.toString(),
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException('Connection timed out. Please try again.', code: 'TIMEOUT');
      case DioExceptionType.connectionError:
        return AppException('Cannot reach the server. Check that the API is running.', code: 'CONNECTION');
      default:
        return AppException(error.message ?? 'Network error', code: 'NETWORK');
    }
  }
}
