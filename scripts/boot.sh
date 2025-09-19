#!/bin/bash
set -euo pipefail

# Bootstraps a FountainAI dev environment.
# OpenAPI specifications are the authoritative source for service metadata.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."

# Load environment variables from .env if present
if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  source "$REPO_ROOT/.env"
  set +a
fi

# Verify required environment variables
echo "==> Checking environment variables"
REQUIRED_VARS=(OPENAI_API_KEY FOUNTAINSTORE_URL FOUNTAINSTORE_API_KEY)
for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var:-}" ]]; then
    echo "Missing required env var: $var" >&2
    exit 1
  else
    echo "Found $var"
  fi
done

# Run diagnostics script
echo "==> Running diagnostics"
if ! swift "$SCRIPT_DIR/start-diagnostics.swift"; then
  echo "Diagnostics reported issues; continuing..." >&2
fi

# Build all Swift targets
echo "==> Building Swift packages"
swift build -c release

# Start the launcher/demo
echo "==> Starting FountainAI launcher"
export SWIFTPM_DISABLE_SANDBOX=${SWIFTPM_DISABLE_SANDBOX:-1}
export CLANG_MODULE_CACHE_PATH=${CLANG_MODULE_CACHE_PATH:-"$REPO_ROOT/.tmp/clang-cache"}
mkdir -p "$CLANG_MODULE_CACHE_PATH"
swift run --package-path platform/FountainAILauncher FountainAiLauncher


# © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
