import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../presentation/providers/app_update_provider.dart';

const _androidInstallChannel = MethodChannel('uz.techren.techren_edu/updater');

/// One-click update — installs over the existing app (no uninstall needed).
/// - Windows: download setup → silent install → exit; installer relaunches.
/// - Android: download APK → system "Update" prompt (same package/signature).
/// - Other: open download site.
Future<bool> startPlatformUpdate(
  AppUpdateInfo update, {
  void Function(double progress)? onProgress,
}) async {
  if (Platform.isWindows) {
    final target = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}TechRenEDU-setup.exe',
    );

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(minutes: 10),
    ));
    await dio.downloadUri(
      update.windowsSetupUrl,
      target.path,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress?.call(received / total);
      },
    );

    await Process.start(target.path, const ['/SILENT'], mode: ProcessStartMode.detached);
    exit(0);
  }

  if (Platform.isAndroid) {
    final target = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}techren-edu-update.apk',
    );

    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(minutes: 10),
    ));
    await dio.downloadUri(
      update.androidApkUrl,
      target.path,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress?.call(received / total);
      },
    );

    await _androidInstallChannel.invokeMethod<bool>('installApk', {
      'path': target.path,
    });
    return true;
  }

  return launchUrl(update.downloadSiteUrl, mode: LaunchMode.externalApplication);
}
