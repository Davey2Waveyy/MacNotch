#!/usr/bin/env bash
# Fast dev launch: build debug, wrap the binary in a minimal .app bundle, and
# open it. Running the raw SPM executable via `open` launches it through
# Terminal; a proper .app bundle (LSUIElement) launches with no Terminal and no
# Dock icon.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="NotchApple"
APP="$ROOT/build/${APP_NAME}-dev.app"
BIN="$ROOT/.build/debug/MacNotch"

echo "==> swift build"
swift build --package-path "$ROOT"

echo "==> (re)assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/NotchApple"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>NotchApple</string>
  <key>CFBundleDisplayName</key><string>NotchApple</string>
  <key>CFBundleIdentifier</key><string>io.notchapple.NotchApple.dev</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleShortVersionString</key><string>0.1.0-dev</string>
  <key>CFBundleExecutable</key><string>NotchApple</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  
  <key>NSCalendarsUsageDescription</key>
  <string>NotchApple shows your upcoming events in the notch.</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>NotchApple controls Music and Spotify playback from the notch.</string>
</dict>
</plist>
PLIST

# Ad-hoc sign so TCC permissions (Calendar, Automation) attach to a stable identity.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

# Restart cleanly.
pkill -9 -f "NotchApple-dev.app/Contents/MacOS/NotchApple" 2>/dev/null || true
pkill -9 -f "MacNotch-dev.app/Contents/MacOS/MacNotch" 2>/dev/null || true
pkill -9 -f ".build/debug/MacNotch" 2>/dev/null || true
sleep 0.3
open "$APP"
echo "==> launched $APP (no Terminal, no Dock icon)"
