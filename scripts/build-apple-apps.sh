#!/usr/bin/env bash
# Build TechRen EDU for Apple platforms (iOS IPA and/or macOS .app).
# Requires: Mac with Xcode, Flutter, CocoaPods, and a signing Team in Xcode.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/build-apple-apps.sh --api-base-url "https://YOUR_API_HOST/api/v1" [options]

Options:
  --api-base-url URL   API base including /api/v1 (required unless --local-dev)
  --local-dev          Profile builds against http://127.0.0.1:5002/api/v1
  --skip-ios           Skip IPA build
  --skip-macos         Skip macOS .app build
  -h, --help           Show this help
EOF
}

API_BASE_URL=""
LOCAL_DEV=0
SKIP_IOS=0
SKIP_MACOS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-base-url) API_BASE_URL="${2:-}"; shift 2 ;;
    --local-dev) LOCAL_DEV=1; shift ;;
    --skip-ios) SKIP_IOS=1; shift ;;
    --skip-macos) SKIP_MACOS=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER_DIR="$ROOT/techren_edu"
DOWNLOADS_DIR="$ROOT/website/downloads"

if [[ ! -d "$FLUTTER_DIR" ]]; then
  echo "Missing Flutter project: $FLUTTER_DIR" >&2
  exit 1
fi

if [[ "$LOCAL_DEV" -eq 1 ]]; then
  if [[ -z "$API_BASE_URL" ]]; then
    API_BASE_URL="http://127.0.0.1:5002/api/v1"
  fi
  BUILD_MODE="profile"
  echo "LocalDev: using $BUILD_MODE builds with API_BASE_URL=$API_BASE_URL"
else
  if [[ -z "$API_BASE_URL" ]]; then
    echo "ApiBaseUrl is required unless --local-dev is set." >&2
    exit 1
  fi
  if [[ "$API_BASE_URL" =~ localhost|127\.0\.0\.1 ]] || [[ "$API_BASE_URL" != https://* ]]; then
    echo "Production builds require --api-base-url https://... (or use --local-dev). Got: $API_BASE_URL" >&2
    exit 1
  fi
  BUILD_MODE="release"
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found on PATH. Install Flutter for macOS first." >&2
  exit 1
fi

mkdir -p "$DOWNLOADS_DIR"

APP_VERSION="$(
  sed -nE 's/^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' "$FLUTTER_DIR/pubspec.yaml" | head -1
)"
if [[ -z "$APP_VERSION" ]]; then
  echo "Could not read version from pubspec.yaml" >&2
  exit 1
fi
echo "App version: $APP_VERSION"

BUILT=()

cd "$FLUTTER_DIR"
flutter pub get

if [[ "$SKIP_IOS" -eq 0 ]]; then
  echo "==> Building iOS IPA ($BUILD_MODE)..."
  if [[ "$BUILD_MODE" == "release" ]]; then
    flutter build ipa \
      --dart-define="API_BASE_URL=$API_BASE_URL" \
      --dart-define="APP_VERSION=$APP_VERSION"
    IPA_SRC="$(find build/ios/ipa -name '*.ipa' 2>/dev/null | head -1 || true)"
    if [[ -n "$IPA_SRC" ]]; then
      cp -f "$IPA_SRC" "$DOWNLOADS_DIR/techren-edu.ipa"
      echo "    Copied -> $DOWNLOADS_DIR/techren-edu.ipa"
      BUILT+=("ios")
    else
      echo "    IPA not found (check Xcode signing / export). Archive may still be under build/ios/archive." >&2
    fi
  else
    flutter build ios --"$BUILD_MODE" --no-codesign \
      --dart-define="API_BASE_URL=$API_BASE_URL" \
      --dart-define="APP_VERSION=$APP_VERSION"
    echo "    LocalDev iOS profile build complete (no IPA export)."
    BUILT+=("ios")
  fi
fi

if [[ "$SKIP_MACOS" -eq 0 ]]; then
  echo "==> Building macOS ($BUILD_MODE)..."
  flutter build macos --"$BUILD_MODE" \
    --dart-define="API_BASE_URL=$API_BASE_URL" \
    --dart-define="APP_VERSION=$APP_VERSION"

  APP_SRC=""
  for candidate in \
    "build/macos/Build/Products/Release/TechRen EDU.app" \
    "build/macos/Build/Products/Profile/TechRen EDU.app" \
    "build/macos/Build/Products/Release/techren_edu.app" \
    "build/macos/Build/Products/Profile/techren_edu.app"
  do
    if [[ -d "$candidate" ]]; then
      APP_SRC="$candidate"
      break
    fi
  done

  if [[ -z "$APP_SRC" ]]; then
    echo "macOS .app not found under build/macos/Build/Products/" >&2
    exit 1
  fi

  ZIP_DEST="$DOWNLOADS_DIR/TechRenEDU-macos.zip"
  rm -f "$ZIP_DEST"
  ditto -c -k --sequesterRsrc --keepParent "$APP_SRC" "$ZIP_DEST"
  echo "    Zipped -> $ZIP_DEST"
  BUILT+=("macos")
fi

echo "Done. Built: ${BUILT[*]:-none}"

# Merge/write status.json so in-app Update button finds Apple artifacts.
STATUS_PATH="$DOWNLOADS_DIR/status.json"
BUILT_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
ANDROID_FLAG=false; [[ -f "$DOWNLOADS_DIR/techren-edu.apk" ]] && ANDROID_FLAG=true
WINDOWS_FLAG=false; [[ -f "$DOWNLOADS_DIR/TechRenEDU-setup.exe" ]] && WINDOWS_FLAG=true
WINDOWS_ZIP=false; [[ -f "$DOWNLOADS_DIR/TechRenEDU-windows.zip" ]] && WINDOWS_ZIP=true
MACOS_FLAG=false; [[ -f "$DOWNLOADS_DIR/TechRenEDU-macos.zip" ]] && MACOS_FLAG=true
IOS_FLAG=false; [[ -f "$DOWNLOADS_DIR/techren-edu.ipa" ]] && IOS_FLAG=true

PREV_IOS_URL="https://github.com/TheDarkness2001/Techren/releases/latest"
if [[ -f "$STATUS_PATH" ]] && command -v python3 >/dev/null 2>&1; then
  EXTRACTED="$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('iosUrl') or '')" "$STATUS_PATH" 2>/dev/null || true)"
  if [[ -n "$EXTRACTED" ]]; then PREV_IOS_URL="$EXTRACTED"; fi
fi

cat > "$STATUS_PATH" <<EOF
{
  "version": "$APP_VERSION",
  "builtAt": "$BUILT_AT",
  "mode": "$BUILD_MODE",
  "apiBaseUrl": "$API_BASE_URL",
  "android": $ANDROID_FLAG,
  "windows": $WINDOWS_FLAG,
  "windowsZip": $WINDOWS_ZIP,
  "macos": $MACOS_FLAG,
  "ios": $IOS_FLAG,
  "androidUrl": "https://github.com/TheDarkness2001/Techren/releases/latest/download/techren-edu.apk",
  "windowsUrl": "https://github.com/TheDarkness2001/Techren/releases/latest/download/TechRenEDU-setup.exe",
  "macosUrl": "https://github.com/TheDarkness2001/Techren/releases/latest/download/TechRenEDU-macos.zip",
  "iosUrl": "$PREV_IOS_URL"
}
EOF

echo "Wrote $STATUS_PATH (version $APP_VERSION)"
echo "Next: upload installers to GitHub Releases (or host under /downloads); set Apple Team in Xcode for device/TestFlight."
echo "Installed apps poll status.json and show Update — no uninstall required (Android/Windows/macOS)."
