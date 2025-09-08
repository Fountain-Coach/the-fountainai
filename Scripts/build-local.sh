#!/usr/bin/env bash
set -euo pipefail

# Local macOS build helper that avoids sandbox/cachedir issues.
export SWIFTPM_DISABLE_SANDBOX=1
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-$PWD/.tmp/clang-cache}"

mkdir -p "$CLANG_MODULE_CACHE_PATH"

echo "[1/3] Building core (FountainAICore)"
swift build --target FountainAICore -c debug

echo "[2/3] Running core tests"
swift test --filter FountainAICoreTests

echo "[3/3] Building app (FountainAIApp)"
swift build --product FountainAIApp -c debug

echo "Build succeeded. Run with: \n  CLANG_MODULE_CACHE_PATH=$CLANG_MODULE_CACHE_PATH SWIFTPM_DISABLE_SANDBOX=1 swift run FountainAIApp\n"

