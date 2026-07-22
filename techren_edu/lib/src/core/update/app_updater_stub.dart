import 'package:url_launcher/url_launcher.dart';

import '../../presentation/providers/app_update_provider.dart';

/// Web fallback — just open the download site.
Future<bool> startPlatformUpdate(
  AppUpdateInfo update, {
  void Function(double progress)? onProgress,
}) {
  return launchUrl(update.downloadSiteUrl, mode: LaunchMode.externalApplication);
}
