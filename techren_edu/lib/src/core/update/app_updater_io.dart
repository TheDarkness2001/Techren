import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../presentation/providers/app_update_provider.dart';

const _androidInstallChannel = MethodChannel('uz.techren.techren_edu/updater');

String _tempJoin(String name) =>
    '${Directory.systemTemp.path}${Platform.pathSeparator}$name';

/// One-click update — installs over the existing app (no uninstall needed).
/// - Windows: download setup → silent install → exit; installer relaunches.
/// - Android: download APK → system update prompt (same package/signature).
/// - macOS: download zip → replace .app → relaunch.
/// - iOS: open TestFlight / App Store / release page (Apple blocks in-app IPA install).
Future<bool> startPlatformUpdate(
  AppUpdateInfo update, {
  void Function(double progress)? onProgress,
}) async {
  if (Platform.isWindows) {
    return _updateWindows(update, onProgress: onProgress);
  }
  if (Platform.isAndroid) {
    return _updateAndroid(update, onProgress: onProgress);
  }
  if (Platform.isMacOS) {
    return _updateMacos(update, onProgress: onProgress);
  }
  if (Platform.isIOS) {
    return launchUrl(update.iosUpdateUrl, mode: LaunchMode.externalApplication);
  }

  return launchUrl(update.downloadSiteUrl, mode: LaunchMode.externalApplication);
}

Dio _downloadClient() => Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(minutes: 10),
    ));

Future<bool> _updateWindows(
  AppUpdateInfo update, {
  void Function(double progress)? onProgress,
}) async {
  final target = File(_tempJoin('TechRenEDU-setup.exe'));

  await _downloadClient().downloadUri(
    update.windowsSetupUrl,
    target.path,
    onReceiveProgress: (received, total) {
      if (total > 0) onProgress?.call(received / total);
    },
  );

  // Same AppId in Inno Setup → upgrades in place, closes running app, relaunches.
  await Process.start(target.path, const ['/SILENT'], mode: ProcessStartMode.detached);
  exit(0);
}

Future<bool> _updateAndroid(
  AppUpdateInfo update, {
  void Function(double progress)? onProgress,
}) async {
  final target = File(_tempJoin('techren-edu-update.apk'));

  await _downloadClient().downloadUri(
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

Future<bool> _updateMacos(
  AppUpdateInfo update, {
  void Function(double progress)? onProgress,
}) async {
  final currentApp = _macosBundlePath();
  if (currentApp == null) {
    return launchUrl(update.downloadSiteUrl, mode: LaunchMode.externalApplication);
  }

  final zipPath = _tempJoin('TechRenEDU-macos-update.zip');
  final extractDir = _tempJoin('techren-edu-macos-update');
  final extract = Directory(extractDir);
  if (extract.existsSync()) {
    extract.deleteSync(recursive: true);
  }
  extract.createSync(recursive: true);

  await _downloadClient().downloadUri(
    update.macosZipUrl,
    zipPath,
    onReceiveProgress: (received, total) {
      if (total > 0) onProgress?.call(received / total * 0.9);
    },
  );

  final unzip = await Process.run('unzip', ['-o', zipPath, '-d', extractDir]);
  if (unzip.exitCode != 0) {
    throw StateError('Failed to unpack macOS update: ${unzip.stderr}');
  }

  final newApp = _findAppBundle(Directory(extractDir));
  if (newApp == null) {
    throw StateError('macOS update zip did not contain a .app bundle.');
  }

  onProgress?.call(0.95);

  // Detached shell replaces the bundle after this process exits, then relaunches.
  final scriptFile = File(_tempJoin('techren-edu-apply-update.sh'));
  final ourPid = pid;
  final script = '''
#!/bin/bash
set -e
NEW_APP=${_shQuote(newApp.path)}
CURRENT_APP=${_shQuote(currentApp.path)}
ZIP=${_shQuote(zipPath)}
EXTRACT=${_shQuote(extractDir)}
APP_PID=$ourPid
# Wait until this app process is gone (max ~60s).
for i in \$(seq 1 120); do
  if ! kill -0 "\$APP_PID" >/dev/null 2>&1; then
    break
  fi
  sleep 0.5
done
# Brief settle so file locks release.
sleep 0.5
ditto "\$NEW_APP" "\$CURRENT_APP"
rm -rf "\$EXTRACT" "\$ZIP"
open "\$CURRENT_APP"
rm -f -- "\$0"
''';
  await scriptFile.writeAsString(script);
  await Process.run('chmod', ['+x', scriptFile.path]);
  await Process.start(
    '/bin/bash',
    [scriptFile.path],
    mode: ProcessStartMode.detached,
  );
  exit(0);
}

Directory? _macosBundlePath() {
  // e.g. .../TechRen EDU.app/Contents/MacOS/TechRen EDU
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 6; i++) {
    if (dir.path.endsWith('.app')) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}

Directory? _findAppBundle(Directory root) {
  try {
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is Directory && entity.path.endsWith('.app')) {
        return entity;
      }
    }
  } catch (_) {}
  return null;
}

String _shQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";
