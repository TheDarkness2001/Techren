# TechRen EDU — native install & release builds

This project ships a **download website** (not a PWA). Students and staff install Android or Windows builds from the API host.

## Download site

- Landing page: `GET /` → [`website/index.html`](../website/index.html)
- Files: `GET /downloads/techren-edu.apk`, `GET /downloads/TechRenEDU-windows.zip`, `GET /downloads/TechRenEDU-macos.zip`
- Status: `GET /downloads/status.json` — installed apps compare `version` to their build and show an **Update** button (no uninstall).

Local check (API running on port 5002):

```text
http://127.0.0.1:5002/
http://127.0.0.1:5002/downloads/techren-edu.apk
```

## Build release installers

From the repo root (PowerShell):

**Production** (https API — required for `--release`):

```powershell
.\scripts\build-release-apps.ps1 -ApiBaseUrl "https://YOUR_API_HOST/api/v1"
```

**Local / school demo** (talks to API on this PC; uses profile builds):

```powershell
.\scripts\build-release-apps.ps1 -LocalDev
.\scripts\build-release-apps.ps1 -LocalDev -SkipWindows
```

Optional skips: `-SkipWindows`, `-SkipAndroid`.

### Windows build requirement

`flutter build windows` needs **Visual Studio** with the **Desktop development with C++** workload. Without it, Android can still be built; the download page will show Windows as not built yet.

Artifacts:

- `website/downloads/techren-edu.apk`
- `website/downloads/TechRenEDU-windows.zip`
- `website/downloads/status.json` (written by the script)

`API_BASE_URL` for production must be **https** and must not be localhost — enforced in the Flutter client for release mode.
## Android signing

[`techren_edu/android/app/build.gradle.kts`](../techren_edu/android/app/build.gradle.kts) currently signs **release** with the **debug** keystore so local `flutter build apk --release` works for internal testing.

For real distribution:

1. Create a release keystore (keep it offline / in CI secrets — never commit it):

```powershell
keytool -genkey -v -keystore techren-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias techren
```

2. Add `android/key.properties` (gitignored) with `storePassword`, `keyPassword`, `keyAlias`, `storeFile`.

3. Wire `signingConfigs.release` in `build.gradle.kts` and set `buildTypes.release.signingConfig` to that config.

4. Rebuild with `scripts/build-release-apps.ps1`.

Until Play Store publishing, users must allow **Install unknown apps** for the browser/file manager that downloaded the APK.

## Windows install

Unzip `TechRenEDU-windows.zip` and run `techren_edu.exe`. Keep the whole Release folder together (DLL/data next to the exe).

## iOS / iPhone

Flutter iOS builds require a **Mac with Xcode** (cannot build on Windows).

### One-time Mac setup

1. Install **Xcode** from the Mac App Store, open it once, and accept the license.
2. Install Flutter for macOS and ensure `flutter` is on your PATH.
3. Install CocoaPods: `sudo gem install cocoapods` (or `brew install cocoapods`).
4. From `techren_edu/`:

```bash
flutter doctor
flutter pub get
cd ios && pod install && cd ..
```

5. Open `ios/Runner.xcworkspace` in Xcode → **Signing & Capabilities** → select your **Team** (Apple Developer account). Bundle ID: `uz.techren.techrenEdu`.

### Run / build

```bash
# Simulator or device
flutter run -d ios --dart-define=API_BASE_URL=https://YOUR_API_HOST/api/v1

# Release IPA (TestFlight / App Store)
flutter build ipa --dart-define=API_BASE_URL=https://YOUR_API_HOST/api/v1
```

Or use the helper script from the repo root:

```bash
./scripts/build-apple-apps.sh --api-base-url "https://YOUR_API_HOST/api/v1"
```

The download site shows iOS as unavailable until an `.ipa` is produced and published (or hosted for TestFlight).

## macOS (Mac / MacBook)

Same Flutter project; runner lives in `techren_edu/macos/`.

Sandbox entitlements include outbound network (`network.client`), user-selected files, and keychain access for secure token storage.

```bash
flutter run -d macos --dart-define=API_BASE_URL=https://YOUR_API_HOST/api/v1
flutter build macos --dart-define=API_BASE_URL=https://YOUR_API_HOST/api/v1
```

Release app bundle: `techren_edu/build/macos/Build/Products/Release/TechRen EDU.app`

Distribute via notarized `.dmg` / Mac App Store, or zip the `.app` for internal school installs (users may need to allow the app under **Privacy & Security**).

## In-app updates (no uninstall)

Installed clients poll `/downloads/status.json`. When `version` is newer than the build’s `APP_VERSION`, the dashboard shows an **Update** button:

| Platform | What Update does |
|----------|------------------|
| Android | Downloads APK → system install prompt over the same package (same signing key) |
| Windows | Downloads setup → `/SILENT` Inno upgrade (same `AppId`) → relaunches |
| macOS | Downloads zip → replaces `TechRen EDU.app` → relaunches |
| iOS | Opens TestFlight / App Store / `iosUrl` (Apple does not allow in-app IPA install) |

Always ship new builds with `--dart-define=APP_VERSION=x.y.z` matching `pubspec.yaml`, then bump `status.json` (build scripts do both).

## App display name

Launcher / window title is **TechRen EDU** (Android label, Windows product name, iOS display name, macOS product name).
