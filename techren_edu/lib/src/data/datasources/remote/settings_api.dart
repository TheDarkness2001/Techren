import '../../../core/network/dio_client.dart';
import '../../../domain/entities/platform_settings.dart';

class SettingsApi {
  SettingsApi(this._client);

  final DioClient _client;

  Future<PlatformSettings> getSettings() async {
    final response = await _client.dio.get('/settings');
    return PlatformSettings.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PlatformSettings> updateSettings({
    FeatureFlags? featureFlags,
    Map<String, Map<String, bool>>? rolePermissions,
  }) async {
    final response = await _client.dio.put('/settings', data: {
      if (featureFlags != null) 'featureFlags': featureFlags.toJson(),
      if (rolePermissions != null) 'rolePermissions': rolePermissions,
    });
    return PlatformSettings.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
