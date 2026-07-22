import 'dart:io';

import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../presentation/providers/app_update_provider.dart';

/// One-click update:
/// - Windows: download the setup wizard, run it silently, exit. The installer
///   replaces the files and relaunches the new version.
/// - Android: open the APK URL — the browser downloads it and the system
///   install prompt appears (user confirms once; OS requirement).
/// - Other platforms: open the download site.
Future<bool> startPlatformUpdate(
  AppUpdateInfo update, {
  void Function(double progress)? onProgress,
}) async {
  if (Platform.isWindows) {
    final setupUrl = update.downloadSiteUrl.resolve('/downloads/TechRenEDU-setup.exe');
    final target = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}TechRenEDU-setup.exe',
    );

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(minutes: 5),
    ));
    await dio.downloadUri(
      setupUrl,
      target.path,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress?.call(received / total);
      },
    );

    // /SILENT shows only a small progress window; the installer relaunches
    // the app when it finishes (Check: WizardSilent in the .iss).
    await Process.start(target.path, const ['/SILENT'], mode: ProcessStartMode.detached);
    exit(0);
  }

  if (Platform.isAndroid) {
    return launchUrl(
      update.downloadSiteUrl.resolve('/downloads/techren-edu.apk'),
      mode: LaunchMode.externalApplication,
    );
  }

  return launchUrl(update.downloadSiteUrl, mode: LaunchMode.externalApplication);
}
