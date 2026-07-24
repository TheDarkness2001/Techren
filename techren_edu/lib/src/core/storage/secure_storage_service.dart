import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/storage_keys.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              wOptions: WindowsOptions(),
              webOptions: WebOptions(
                dbName: 'techrenSecureStorage',
                publicKey: 'techrenPublicKey',
              ),
            );

  final FlutterSecureStorage _storage;

  Future<void> _writeWithRetry(String key, String value) async {
    Object? lastError;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _storage.write(key: key, value: value);
        return;
      } catch (e) {
        lastError = e;
        await Future<void>.delayed(Duration(milliseconds: 40 * (attempt + 1)));
      }
    }
    if (kDebugMode) {
      debugPrint('SecureStorage write failed for $key: $lastError');
    }
    Error.throwWithStackTrace(lastError!, StackTrace.current);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _writeWithRetry(StorageKeys.accessToken, accessToken);
    await _writeWithRetry(StorageKeys.refreshToken, refreshToken);
  }

  Future<String?> getAccessToken() => _storage.read(key: StorageKeys.accessToken);

  Future<String?> getRefreshToken() => _storage.read(key: StorageKeys.refreshToken);

  Future<void> saveUserJson(String json) => _writeWithRetry(StorageKeys.userJson, json);

  Future<String?> getUserJson() => _storage.read(key: StorageKeys.userJson);

  Future<void> clearTokens() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
  }

  Future<void> markSessionStarted() async {
    final now = DateTime.now().toUtc().toIso8601String();
    await _writeWithRetry(StorageKeys.sessionStartedAt, now);
    await _storage.delete(key: StorageKeys.backgroundedAt);
  }

  Future<void> markBackgrounded() async {
    await _writeWithRetry(StorageKeys.backgroundedAt, DateTime.now().toUtc().toIso8601String());
  }

  Future<void> clearBackgrounded() async {
    await _storage.delete(key: StorageKeys.backgroundedAt);
  }

  Future<DateTime?> getSessionStartedAt() => _readDate(StorageKeys.sessionStartedAt);

  Future<DateTime?> getBackgroundedAt() => _readDate(StorageKeys.backgroundedAt);

  Future<DateTime?> _readDate(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  Future<void> setLogoutReason(String reason) => _writeWithRetry(StorageKeys.logoutReason, reason);

  Future<String?> takeLogoutReason() async {
    final reason = await _storage.read(key: StorageKeys.logoutReason);
    if (reason != null) await _storage.delete(key: StorageKeys.logoutReason);
    return reason;
  }

  Future<void> clearAll() => _storage.deleteAll();
}
