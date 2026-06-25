#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/MacNotch.app"
DMG="$ROOT/build/MacNotch.dmg"
BIN_SRC="$ROOT/.build/release/MacNotch"
VERSION="${1:-0.1.0}"

echo "==> swift build -c release"
swift build -c release --package-path "$ROOT"

echo "==> assembling bundle"
rm -rf "$APP" "$DMG"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_SRC" "$APP/Contents/MacOS/MacNotch"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>MacNotch</string>
  <key>CFBundleDisplayName</key><string>MacNotch</string>
  <key>CFBundleIdentifier</key><string>com.macnotch.app</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
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

echo "==> creating DMG"
STAGING="$ROOT/build/_dmg-staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -r "$APP" "$STAGING/MacNotch.app"
ln -s /Applications "$STAGING/Applications"

hdiutil create \
  -volname "MacNotch" \
  -srcfolder "$STAGING" \
  -ov -format UDZO \
  "$DMG" > /dev/null

rm -rf "$STAGING"

echo "==> done: $DMG"
