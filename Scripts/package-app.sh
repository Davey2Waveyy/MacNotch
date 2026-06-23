#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/MacNotch.app"
BIN_SRC="$ROOT/.build/release/MacNotch"

echo "==> swift build -c release"
swift build -c release --package-path "$ROOT"

echo "==> assembling bundle"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_SRC" "$APP/Contents/MacOS/MacNotch"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>MacNotch</string>
  <key>CFBundleDisplayName</key><string>MacNotch</string>
  <key>CFBundleIdentifier</key><string>com.macnotch.app</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleShortVersionString</key><string>0.1.0</string>
  <key>CFBundleExecutable</key><string>MacNotch</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  
  <key>NSCalendarsUsageDescription</key>
  <string>MacNotch shows your upcoming events in the notch.</string>
  <key>NSAppleEventsUsageDescription</key>
  <string>MacNotch controls Music and Spotify playback from the notch.</string>
</dict>
</plist>
PLIST

echo "==> ad-hoc codesign"
codesign --force --deep --sign - \
  --entitlements "$ROOT/MacNotch.entitlements" "$APP"

echo "==> built $APP"
