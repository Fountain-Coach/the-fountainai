#!/usr/bin/env bash
set -euo pipefail

# make_app.sh — wrap a SwiftPM-built executable into a macOS .app bundle
# Usage: Scripts/make_app.sh <ProductName> [dist_dir]

APP_NAME=${1:-}
DIST_DIR=${2:-dist}

if [[ -z "$APP_NAME" ]]; then
  echo "Usage: Scripts/make_app.sh <ProductName> [dist_dir]" >&2
  exit 2
fi

BIN_DIR=$(swift build --show-bin-path)
BIN_PATH="$BIN_DIR/$APP_NAME"
if [[ ! -x "$BIN_PATH" ]]; then
  echo "Building $APP_NAME..." >&2
  swift build --product "$APP_NAME"
fi

BIN_PATH="$BIN_DIR/$APP_NAME"
if [[ ! -x "$BIN_PATH" ]]; then
  echo "Could not find built binary at $BIN_PATH" >&2
  exit 1
fi

APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
cat > "$APP_BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>FountainAI</string>
  <key>CFBundleIdentifier</key><string>co.fountain.ai.app</string>
  <key>CFBundleExecutable</key><string>__EXEC__</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

# Replace placeholder with actual executable name
sed -i '' "s/__EXEC__/$APP_NAME/g" "$APP_BUNDLE/Contents/Info.plist"

cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo "Created: $APP_BUNDLE"
echo "Launch with: open '$APP_BUNDLE'"
