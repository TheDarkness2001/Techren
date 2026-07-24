class StorageKeys {
  static const accessToken = 'access_token';
  static const refreshToken = 'refresh_token';
  static const userJson = 'user_json';
  /// ISO-8601 time when the user last signed in (absolute session cap).
  static const sessionStartedAt = 'session_started_at';
  /// ISO-8601 time when the app last went to background (idle timeout).
  static const backgroundedAt = 'backgrounded_at';
  /// Shown once on the login screen after anti-cheat auto-logout.
  static const logoutReason = 'logout_reason';
}
