import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../presentation/providers/app_update_provider.dart';

const _androidInstallChannel = MethodChannel('uz.techren.techren_edu/updater');

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
      followRedirects: true,
      maxRedirects: 8,
      headers: const {
        // Some CDNs reject empty / default clients.
        'User-Agent': 'TechRenEDU-Updater/1.0',
        'Accept': '*/*',
      },
    ));

Future<String> _tempPath(String name) async {
  if (Platform.isAndroid) {
    final dir = await getTemporaryDirectory();
    return '${dir.path}${Platform.pathSeparator}$name';
  }
  return '${Directory.systemTemp.path}${Platform.pathSeparator}$name';
}

Future<bool> _updateWindows(
  AppUpdateInfo update, {
  void Function(double progress)? onProgress,
}) async {
  final target = File(await _tempPath('TechRenEDU-setup.exe'));

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
  final target = File(await _tempPath('techren-edu-update.apk'));
  if (target.existsSync()) {
    try {
      target.deleteSync();
    } catch (_) {}
  }

  await _downloadClient().downloadUri(
    update.androidApkUrl,
    target.path,
    onReceiveProgress: (received, total) {
      if (total > 0) onProgress?.call(received / total * 0.95);
    },
  );

  _assertApkFile(target);
  onProgress?.call(0.98);

  // Native PackageInstaller: system "Update" sheet → replaces this app → relaunches.
  // Same package name + signing key = upgrade in place (no uninstall, no Downloads folder).
  await _androidInstallChannel.invokeMethod<bool>('installApk', {
    'path': target.path,
  });
  onProgress?.call(1);
  return true;
}

void _assertApkFile(File file) {
  if (!file.existsSync()) {
    throw StateError('Download failed — APK file missing.');
  }
  final length = file.lengthSync();
  if (length < 1024 * 100) {
    // Likely an HTML/JSON error page saved as .apk
    throw StateError(
      'Download failed — got ${length}B instead of an APK. '
      'Check the GitHub Release asset techren-edu.apk.',
    );
  }
  final raf = file.openSync(mode: FileMode.read);
  try {
    final header = Uint8List(4);
    final read = raf.readIntoSync(header);
    // APK is a ZIP archive → local file header magic "PK\x03\x04"
    if (read < 4 || header[0] != 0x50 || header[1] != 0x4b) {
      throw StateError(
        'Download failed — file is not a valid APK. '
        'Open the download link and confirm techren-edu.apk is attached to the Release.',
      );
    }
  } finally {
    raf.closeSync();
  }
}

Future<bool> _updateMacos(
  AppUpdateInfo update, {
  void Function(double progress)? onProgress,
}) async {
  final currentApp = _macosBundlePath();
  if (currentApp == null) {
    return launchUrl(update.downloadSiteUrl, mode: LaunchMode.externalApplication);
  }

  final zipPath = await _tempPath('TechRenEDU-macos-update.zip');
  final extractDir = await _tempPath('techren-edu-macos-update');
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
  final scriptFile = File(await _tempPath('techren-edu-apply-update.sh'));
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
