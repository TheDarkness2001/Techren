# Release installers land here after build scripts

Expected files:
- `techren-edu.apk` — Android (in-app Update installs over the same package)
- `TechRenEDU-setup.exe` — Windows installer (in-app Update runs `/SILENT` upgrade)
- `TechRenEDU-windows.zip` — Windows portable
- `TechRenEDU-macos.zip` — Mac `.app` zip (in-app Update replaces the app + relaunches)
- `techren-edu.ipa` — iOS (optional; Update opens TestFlight / `iosUrl`)
- `status.json` — version + URLs polled by the app for the Update banner

Build:
- Windows/Android: `scripts/build-release-apps.ps1`
- Apple: `scripts/build-apple-apps.sh`

Until platform files exist locally, the download page / app fall back to GitHub Releases URLs in `status.json`.
