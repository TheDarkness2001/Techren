import 'dart:convert';

import 'package:dio/dio.dart';
import '../../core/network/dio_client.dart';
import '../../core/security/session_policy.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../domain/entities/app_user.dart';

class AuthRepository {
  AuthRepository(this._client, this._storage);

  final DioClient _client;
  final SecureStorageService _storage;

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    // Stale tokens must not interfere with a fresh sign-in.
    await _storage.clearTokens();

    try {
      final response = await _postLogin(email: email, password: password);
      return await _persistSession(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      // One automatic retry for flaky first-connection / hot-restart races.
      if (_isTransientNetwork(e)) {
        try {
          await Future<void>.delayed(const Duration(milliseconds: 350));
          final response = await _postLogin(email: email, password: password);
          return await _persistSession(response.data['data'] as Map<String, dynamic>);
        } on DioException catch (retryError) {
          throw _client.mapError(retryError);
        }
      }
      throw _client.mapError(e);
    }
  }

  Future<Response<dynamic>> _postLogin({
    required String email,
    required String password,
  }) {
    return _client.dio.post('/auth/login', data: {
      'email': email.trim(),
      'password': password,
      'userType': 'auto',
    });
  }

  bool _isTransientNetwork(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.response == null;
  }

  Future<AppUser?> restoreSession() async {
    final token = await _storage.getAccessToken();
    final userJson = await _storage.getUserJson();
    if (token == null || userJson == null) return null;

    if (await _isSessionExpiredLocally()) {
      await _storage.clearAll();
      return null;
    }

    try {
      final response = await _client.dio.get('/auth/me');
      final user = AppUser.fromJson(response.data['data'] as Map<String, dynamic>);
      await _storage.saveUserJson(jsonEncode(user.toJson()));
      await _storage.clearBackgrounded();
      return user;
    } catch (_) {
      await _storage.clearAll();
      return null;
    }
  }

  Future<bool> _isSessionExpiredLocally() async {
    final started = await _storage.getSessionStartedAt();
    final backgrounded = await _storage.getBackgroundedAt();
    final now = DateTime.now().toUtc();

    // Older installs without timestamps: force re-login once for security.
    if (started == null) {
      return true;
    }
    if (now.difference(started) > SessionPolicy.maxSessionAge) {
      return true;
    }
    if (backgrounded != null && now.difference(backgrounded) > SessionPolicy.maxIdleAge) {
      return true;
    }
    return false;
  }

  Future<void> logout({String? reason}) async {
    final refreshToken = await _storage.getRefreshToken();
    try {
      if (refreshToken != null) {
        await _client.dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } finally {
      await _storage.clearAll();
      if (reason != null && reason.isNotEmpty) {
        await _storage.setLogoutReason(reason);
      }
    }
  }

  Future<void> markBackgrounded() => _storage.markBackgrounded();

  Future<void> clearBackgrounded() => _storage.clearBackgrounded();

  Future<String?> takeLogoutReason() => _storage.takeLogoutReason();

  Future<DateTime?> getSessionStartedAt() => _storage.getSessionStartedAt();

  Future<DateTime?> getBackgroundedAt() => _storage.getBackgroundedAt();

  Future<AppUser> _persistSession(Map<String, dynamic> data) async {
    final accessToken = data['accessToken']?.toString();
    final refreshToken = data['refreshToken']?.toString();
    final userRaw = data['user'];

    if (accessToken == null || accessToken.isEmpty || refreshToken == null || refreshToken.isEmpty) {
      throw StateError('Login response missing tokens');
    }
    if (userRaw is! Map) {
      throw StateError('Login response missing user');
    }

    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await _storage.markSessionStarted();
    final user = AppUser.fromJson(Map<String, dynamic>.from(userRaw));
    await _storage.saveUserJson(jsonEncode(user.toJson()));
    return user;
  }
}
