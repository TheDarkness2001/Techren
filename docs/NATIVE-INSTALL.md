# TechRen EDU — native install & release builds

This project ships a **download website** (not a PWA). Students and staff install Android or Windows builds from the API host.

## Download site

- Landing page: `GET /` → [`website/index.html`](../website/index.html)
- Files: `GET /downloads/techren-edu.apk`, `GET /downloads/TechRenEDU-windows.zip`
- Served by the Express API ([`backend/src/app.js`](../backend/src/app.js)) from the repo `website/` folder

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

**Cannot be built on Windows.** Flutter iOS builds require a **Mac with Xcode**.

Options later:
- Build on a Mac: `flutter build ipa --dart-define=API_BASE_URL=https://...`
- Or use a cloud Mac CI (Codemagic, GitHub Actions macOS) + Apple Developer account for TestFlight / App Store

The download site shows iOS as unavailable until an `.ipa` is produced on macOS and published (or hosted for TestFlight).

## App display name

Launcher / window title is **TechRen EDU** (Android label, Windows product name, iOS display name).
