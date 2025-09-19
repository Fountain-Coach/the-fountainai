#!/usr/bin/env bash
set -euo pipefail

# Precompile all FountainAI service binaries and install them into dist/bin
# using the FountainAiLauncher in precompile mode.

ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
cd "$ROOT_DIR"

# Avoid sandbox/cache issues on macOS CI and local machines
export SWIFTPM_DISABLE_SANDBOX=${SWIFTPM_DISABLE_SANDBOX:-1}
export CLANG_MODULE_CACHE_PATH=${CLANG_MODULE_CACHE_PATH:-"$ROOT_DIR/.tmp/clang-cache"}
mkdir -p "$CLANG_MODULE_CACHE_PATH"

echo "[precompile] Building FountainAiLauncher"
swift build --package-path platform/FountainAILauncher -c release >/dev/null

echo "[precompile] Building and installing service binaries to dist/bin"
swift run --package-path platform/FountainAILauncher -c release \
  FountainAiLauncher --precompile

echo "[precompile] Done. Binaries in dist/bin; manifest at service-manifest.json"
