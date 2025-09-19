#!/usr/bin/env bash
set -euo pipefail

# Precompile all FountainAI service binaries and install them into dist/bin
# using the FountainAiLauncher in precompile mode.

ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
cd "$ROOT_DIR"

echo "[precompile] Building FountainAiLauncher"
swift build --package-path platform/FountainAILauncher -c release >/dev/null

echo "[precompile] Building and installing service binaries to dist/bin"
swift run --package-path platform/FountainAILauncher -c release \
  FountainAiLauncher --precompile

echo "[precompile] Done. Binaries in dist/bin; manifest at service-manifest.json"

