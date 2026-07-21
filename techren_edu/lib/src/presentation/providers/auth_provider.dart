import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/app_user.dart';
import 'settings_provider.dart';

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
  const AuthState({required this.status, this.user});

  final AuthStatus status;
  final AppUser? user;

  AuthState copyWith({AuthStatus? status, AppUser? user}) {
    return AuthState(status: status ?? this.status, user: user ?? this.user);
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
      state = AuthState(
        status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        user: user,
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

  /// Local session wipe after refresh failure (tokens already cleared).
  void markUnauthenticated() {
    if (state.status == AuthStatus.unauthenticated && state.user == null) return;
    _clearSessionState();
  }

  void _clearSessionState() {
    state = const AuthState(status: AuthStatus.unauthenticated);
    // Allow a later bootstrap (e.g. after logout → splash) to run again.
    _bootstrapFuture = null;
    // Drop session-scoped caches so the next login cannot see stale data.
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
