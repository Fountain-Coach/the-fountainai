#!/bin/bash
set -euo pipefail

# Bootstraps a FountainAI dev environment.
# Each major step can be disabled by setting its control variable to 0.
# Example: `BUILD=0 scripts/boot.sh` skips the Swift build.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/.."

# Load environment variables from .env if present
if [[ -f "$REPO_ROOT/.env" ]]; then
  set -a
  source "$REPO_ROOT/.env"
  set +a
fi

# Toggle variables (1=enable, 0=disable)
CHECK_ENV="${CHECK_ENV:-1}"
RUN_DIAGNOSTICS="${RUN_DIAGNOSTICS:-1}"
BUILD="${BUILD:-1}"
LAUNCH_DEMO="${LAUNCH_DEMO:-1}"

# Step 1: verify required environment variables
if [[ "$CHECK_ENV" == "1" ]]; then
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
fi

# Step 2: run diagnostics script
if [[ "$RUN_DIAGNOSTICS" == "1" ]]; then
  echo "==> Running diagnostics"
  if ! swift "$SCRIPT_DIR/start-diagnostics.swift"; then
    echo "Diagnostics reported issues; continuing..." >&2
  fi
fi

# Step 3: build all Swift targets
if [[ "$BUILD" == "1" ]]; then
  echo "==> Building Swift packages"
  swift build -c release
fi

# Step 4: start the launcher/demo
if [[ "$LAUNCH_DEMO" == "1" ]]; then
  echo "==> Starting FountainAI launcher"
  swift run FountainAiLauncher
fi

# © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
