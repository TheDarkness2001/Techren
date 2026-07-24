import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/security/session_policy.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/app_user.dart';
import 'settings_provider.dart';
import 'task_integrity_provider.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.watch(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioClientProvider),
    ref.watch(secureStorageProvider),
  );
});

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.user, this.logoutMessage});

  final AuthStatus status;
  final AppUser? user;
  final String? logoutMessage;

  AuthState copyWith({AuthStatus? status, AppUser? user, String? logoutMessage}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      logoutMessage: logoutMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref)
      : _repository = _ref.read(authRepositoryProvider),
        super(const AuthState(status: AuthStatus.unknown));

  final Ref _ref;
  final AuthRepository _repository;
  Future<void>? _bootstrapFuture;

  /// Idempotent — safe to call from [main] and SplashScreen.
  Future<void> bootstrap() {
    return _bootstrapFuture ??= _doBootstrap();
  }

  Future<void> _doBootstrap() async {
    try {
      final user = await _repository.restoreSession();
      final reason = await _repository.takeLogoutReason();
      state = AuthState(
        status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        user: user,
        logoutMessage: reason,
      );
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final user = await _repository.login(
      email: email,
      password: password,
    );
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> logout() async {
    await _repository.logout();
    _clearSessionState();
  }

  Future<void> logoutDueToTaskLeave() async {
    if (state.status != AuthStatus.authenticated) return;
    _ref.read(taskIntegrityProvider.notifier).endTask();
    await _repository.logout(
      reason: 'Signed out because you left the app during a learning task.',
    );
    _clearSessionState(
      message: 'Signed out because you left the app during a learning task.',
    );
  }

  Future<void> onAppResumed() async {
    if (state.status != AuthStatus.authenticated) return;
    final storage = _ref.read(secureStorageProvider);
    final started = await storage.getSessionStartedAt();
    final backgrounded = await storage.getBackgroundedAt();
    final now = DateTime.now().toUtc();

    if (started != null && now.difference(started) > SessionPolicy.maxSessionAge) {
      await _repository.logout(reason: 'Your session expired. Please sign in again.');
      _clearSessionState(message: 'Your session expired. Please sign in again.');
      return;
    }
    if (backgrounded != null && now.difference(backgrounded) > SessionPolicy.maxIdleAge) {
      await _repository.logout(reason: 'Signed out after being idle. Please sign in again.');
      _clearSessionState(message: 'Signed out after being idle. Please sign in again.');
      return;
    }
    await _repository.clearBackgrounded();
  }

  void onAppBackgrounded() {
    Future.microtask(() => _repository.markBackgrounded());
  }

  /// Local session wipe after refresh failure (tokens already cleared).
  void markUnauthenticated() {
    if (state.status == AuthStatus.unauthenticated && state.user == null) return;
    _clearSessionState();
  }

  void clearLogoutMessage() {
    if (state.logoutMessage == null) return;
    state = AuthState(status: state.status, user: state.user);
  }

  void _clearSessionState({String? message}) {
    state = AuthState(status: AuthStatus.unauthenticated, logoutMessage: message);
    _bootstrapFuture = null;
    _ref.invalidate(platformSettingsProvider);
  }

  void updateProfileImage(String? profileImage) {
    final user = state.user;
    if (user == null) return;
    state = AuthState(
      status: state.status,
      user: user.copyWith(profileImage: profileImage),
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(ref);
  // Wire after DioClient exists to avoid a circular type inference with dioClientProvider.
  ref.read(dioClientProvider).onSessionExpired = () {
    Future.microtask(notifier.markUnauthenticated);
  };
  return notifier;
});
