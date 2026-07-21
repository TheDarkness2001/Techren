import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/remote/settings_api.dart';
import '../../domain/entities/platform_settings.dart';
import 'auth_provider.dart';

final settingsApiProvider = Provider<SettingsApi>((ref) {
  return SettingsApi(ref.watch(dioClientProvider));
});

final platformSettingsProvider = FutureProvider.autoDispose<PlatformSettings>((ref) async {
  final auth = ref.watch(authProvider);
  // Do not hit protected /settings while logged out (avoids spurious 401 + refresh races).
  if (auth.status != AuthStatus.authenticated) {
    return PlatformSettings.empty;
  }

  try {
    return await ref.watch(settingsApiProvider).getSettings();
  } catch (_) {
    return PlatformSettings.empty;
  }
});

final walletEnabledProvider = Provider<bool>((ref) {
  return ref.watch(platformSettingsProvider).valueOrNull?.featureFlags.walletEnabled ?? false;
});
