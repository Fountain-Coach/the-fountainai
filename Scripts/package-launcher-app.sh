#!/usr/bin/env bash
set -euo pipefail

# package-launcher-app.sh — builds the menubar app and bundles the FountainAiLauncher binary
# Usage: Scripts/package-launcher-app.sh [dist_dir]

DIST_DIR=${1:-dist}
APP_NAME=FountainAILauncherApp
LAUNCHER_PKG=platform/FountainAILauncher
LAUNCHER_BIN=FountainAiLauncher

echo "[1/4] Building Launcher CLI (release)"
swift build --package-path "$LAUNCHER_PKG" -c release >/dev/null

echo "[2/4] Building $APP_NAME (release)"
swift build -c release --product "$APP_NAME" >/dev/null

echo "[3/4] Creating .app bundle"
Scripts/make_app.sh "$APP_NAME" "$DIST_DIR" >/dev/null

echo "[4/4] Embedding Launcher binary"
BIN_DIR=$(swift build --package-path "$LAUNCHER_PKG" --show-bin-path -c release)
BIN_PATH="$BIN_DIR/$LAUNCHER_BIN"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
RES_DIR="$APP_BUNDLE/Contents/Resources/Launcher"
mkdir -p "$RES_DIR"
cp "$BIN_PATH" "$RES_DIR/$LAUNCHER_BIN"
chmod +x "$RES_DIR/$LAUNCHER_BIN"

echo "✅ Packaged: $APP_BUNDLE"
echo "   Open with: open '$APP_BUNDLE'"

