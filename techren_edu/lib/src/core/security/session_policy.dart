/// Client-side session limits (enforced in addition to JWT expiry).
abstract final class SessionPolicy {
  /// Absolute max time since last successful login.
  static const maxSessionAge = Duration(hours: 24);

  /// Max time in background before requiring re-login.
  static const maxIdleAge = Duration(minutes: 30);
}
