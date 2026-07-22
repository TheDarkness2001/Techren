<#
.SYNOPSIS
  Build TechRen EDU APK + Windows zip into website/downloads.

.PARAMETER ApiBaseUrl
  API base including /api/v1. For -LocalDev, http://127.0.0.1:5002/api/v1 is allowed (profile builds).
  For production release, must be https:// (not localhost).

.PARAMETER LocalDev
  Build profile (not release) so localhost API works for school/internal demos.

.EXAMPLE
  .\scripts\build-release-apps.ps1 -ApiBaseUrl "https://api.example.com/api/v1"
.EXAMPLE
  .\scripts\build-release-apps.ps1 -LocalDev -SkipWindows
#>
[CmdletBinding()]
param(
  [string]$ApiBaseUrl = '',

  [switch]$LocalDev,
  [switch]$SkipAndroid,
  [switch]$SkipWindows
)

$ErrorActionPreference = 'Stop'

if ($LocalDev) {
  if (-not $ApiBaseUrl) { $ApiBaseUrl = 'http://127.0.0.1:5002/api/v1' }
  $buildMode = 'profile'
  Write-Host "LocalDev: using $buildMode builds with API_BASE_URL=$ApiBaseUrl"
} else {
  if (-not $ApiBaseUrl) {
    throw "ApiBaseUrl is required unless -LocalDev is set."
  }
  if ($ApiBaseUrl -match 'localhost|127\.0\.0\.1' -or $ApiBaseUrl -notmatch '^https://') {
    throw "Production builds require -ApiBaseUrl https://... (or use -LocalDev). Got: $ApiBaseUrl"
  }
  $buildMode = 'release'
}

$root = Split-Path -Parent $PSScriptRoot
$flutterDir = Join-Path $root 'techren_edu'
$downloadsDir = Join-Path $root 'website\downloads'

if (-not (Test-Path $flutterDir)) { throw "Missing Flutter project: $flutterDir" }
New-Item -ItemType Directory -Force -Path $downloadsDir | Out-Null

# App version from pubspec.yaml (e.g. "1.0.0+1" -> "1.0.0").
# Installed apps compare this against /downloads/status.json to show an Update button.
$pubspec = Get-Content (Join-Path $flutterDir 'pubspec.yaml') -Raw
if ($pubspec -notmatch '(?m)^version:\s*([^\s+]+)') { throw "Could not read version from pubspec.yaml" }
$appVersion = $Matches[1]
Write-Host "App version: $appVersion"

$built = @()

Push-Location $flutterDir
try {
  if (-not $SkipAndroid) {
    Write-Host "==> Building Android APK ($buildMode)..."
    & flutter build apk "--$buildMode" "--dart-define=API_BASE_URL=$ApiBaseUrl" "--dart-define=APP_VERSION=$appVersion"
    $apkSrc = Join-Path $flutterDir "build\app\outputs\flutter-apk\app-$buildMode.apk"
    if (-not (Test-Path $apkSrc)) {
      $apkSrc = Join-Path $flutterDir 'build\app\outputs\flutter-apk\app-release.apk'
    }
    if (-not (Test-Path $apkSrc)) { throw "APK not found under build\app\outputs\flutter-apk\" }
    $apkDest = Join-Path $downloadsDir 'techren-edu.apk'
    Copy-Item $apkSrc $apkDest -Force
    Write-Host "    Copied -> $apkDest"
    $built += 'android'
  }

  if (-not $SkipWindows) {
    Write-Host "==> Building Windows ($buildMode)..."
    & flutter build windows "--$buildMode" "--dart-define=API_BASE_URL=$ApiBaseUrl" "--dart-define=APP_VERSION=$appVersion"
    $candidates = @(
      (Join-Path $flutterDir 'build\windows\x64\runner\Release'),
      (Join-Path $flutterDir 'build\windows\x64\runner\Profile'),
      (Join-Path $flutterDir 'build\windows\runner\Release'),
      (Join-Path $flutterDir 'build\windows\runner\Profile')
    )
    $winDir = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $winDir) {
      throw @"
Windows build folder not found.

Common fixes:
1) Enable Developer Mode (Settings → System → For developers) — required for Flutter plugin symlinks.
2) Confirm Visual Studio Build Tools has the 'Desktop development with C++' workload.
See docs/NATIVE-INSTALL.md.
"@
    }

    $zipDest = Join-Path $downloadsDir 'TechRenEDU-windows.zip'
    if (Test-Path $zipDest) { Remove-Item $zipDest -Force }
    Compress-Archive -Path (Join-Path $winDir '*') -DestinationPath $zipDest -Force
    Write-Host "    Zipped  -> $zipDest"

    # Setup wizard (Desktop + Start Menu shortcuts) via Inno Setup, if installed.
    $isccCandidates = @(
      (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe'),
      'C:\Program Files (x86)\Inno Setup 6\ISCC.exe'
    )
    $iscc = $isccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($iscc) {
      Write-Host "==> Building Windows installer (Inno Setup)..."
      $issFile = Join-Path $PSScriptRoot 'techren-windows-installer.iss'
      $iconFile = Join-Path $flutterDir 'windows\runner\resources\app_icon.ico'
      & $iscc "/DAppVersion=$appVersion" "/DSourceDir=$winDir" "/DOutputDir=$downloadsDir" "/DIconFile=$iconFile" /Qp $issFile
      if ($LASTEXITCODE -ne 0) { throw "Inno Setup compile failed (exit $LASTEXITCODE)" }
      $setupDest = Join-Path $downloadsDir 'TechRenEDU-setup.exe'
      Write-Host "    Setup   -> $setupDest"
    } else {
      Write-Host '    Inno Setup not found - skipping setup.exe (zip only). Install: winget install JRSoftware.InnoSetup'
    }
    $built += 'windows'
  }
}
finally {
  Pop-Location
}

$status = @{
  version = $appVersion
  builtAt = (Get-Date).ToUniversalTime().ToString('o')
  mode = $buildMode
  apiBaseUrl = $ApiBaseUrl
  android = [bool](Test-Path (Join-Path $downloadsDir 'techren-edu.apk'))
  windows = [bool](Test-Path (Join-Path $downloadsDir 'TechRenEDU-setup.exe'))
  windowsZip = [bool](Test-Path (Join-Path $downloadsDir 'TechRenEDU-windows.zip'))
}
$status | ConvertTo-Json | Set-Content -Path (Join-Path $downloadsDir 'status.json') -Encoding utf8

Write-Host ""
Write-Host "Done. Built: $($built -join ', ')"
Write-Host "Android: /downloads/techren-edu.apk"
Write-Host "Windows: /downloads/TechRenEDU-windows.zip"
