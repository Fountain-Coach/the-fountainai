#!/usr/bin/env bash
set -euo pipefail

# make_app.sh — wrap a SwiftPM-built executable into a macOS .app bundle
# Usage: Scripts/make_app.sh <ProductName> [dist_dir]
# Env overrides:
#   BUNDLE_ID   (default: co.fountain.ai.launcherapp.dev)
#   VERSION     (default: current timestamp)

APP_NAME=${1:-}
DIST_DIR=${2:-dist}
BUNDLE_ID=${BUNDLE_ID:-co.fountain.ai.launcherapp.dev}
VERSION=${VERSION:-$(date +%Y.%m.%d.%H%M%S)}

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

mkdir -p "$DIST_DIR"

# Create versioned app bundle and update symlink for stable path
APP_BUNDLE="$DIST_DIR/$APP_NAME-$VERSION.app"
rm -rf "$APP_BUNDLE" "$DIST_DIR/$APP_NAME.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
cat > "$APP_BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>__APPNAME__</string>
  <key>CFBundleIdentifier</key><string>__BUNDLE_ID__</string>
  <key>CFBundleExecutable</key><string>__EXEC__</string>
  <key>CFBundleShortVersionString</key><string>__VERSION__</string>
  <key>CFBundleVersion</key><string>__VERSION__</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

# Replace placeholder with actual executable name
sed -i '' "s/__EXEC__/$APP_NAME/g" "$APP_BUNDLE/Contents/Info.plist"
sed -i '' "s#__BUNDLE_ID__#$BUNDLE_ID#g" "$APP_BUNDLE/Contents/Info.plist"
sed -i '' "s/__VERSION__/$VERSION/g" "$APP_BUNDLE/Contents/Info.plist"
sed -i '' "s/__APPNAME__/$APP_NAME/g" "$APP_BUNDLE/Contents/Info.plist"

cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Stable symlink path
ln -s "$(basename "$APP_BUNDLE")" "$DIST_DIR/$APP_NAME.app"

# Remove quarantine to avoid app translocation in dev builds
if command -v xattr >/dev/null 2>&1; then
  xattr -dr com.apple.quarantine "$APP_BUNDLE" "$DIST_DIR/$APP_NAME.app" || true
fi

echo "Created: $APP_BUNDLE"
echo "Symlink: $DIST_DIR/$APP_NAME.app -> $(basename "$APP_BUNDLE")"
echo "Launch with: open '$DIST_DIR/$APP_NAME.app'"
