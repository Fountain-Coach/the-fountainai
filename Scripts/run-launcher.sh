#!/usr/bin/env bash
set -euo pipefail

# Verbose runner with explicit, continuous feedback.

ROOT_DIR="$(cd "$(dirname "$0")"/.. && pwd)"
cd "$ROOT_DIR"

export SWIFTPM_DISABLE_SANDBOX=${SWIFTPM_DISABLE_SANDBOX:-1}
export CLANG_MODULE_CACHE_PATH=${CLANG_MODULE_CACHE_PATH:-"$ROOT_DIR/.tmp/clang-cache"}
export NSUnbufferedIO=YES
mkdir -p "$CLANG_MODULE_CACHE_PATH" logs

echo "[runner] START $(date +%H:%M:%S)"
echo "[runner] SWIFTPM_DISABLE_SANDBOX=$SWIFTPM_DISABLE_SANDBOX"
echo "[runner] CLANG_MODULE_CACHE_PATH=$CLANG_MODULE_CACHE_PATH"

heartbeat() {
  local msg="$1" pid="$2" start_ts
  start_ts=$(date +%s)
  while kill -0 "$pid" 2>/dev/null; do
    local now elapsed
    now=$(date +%s)
    elapsed=$((now-start_ts))
    printf "[hb] %s • %ss elapsed\n" "$msg" "$elapsed"
    sleep 2
  done
}

echo "[build] Building Launcher in release (-v for live steps)"
(
  script -q /dev/null swift build --package-path platform/FountainAILauncher -c release -v 2>&1 \
    | awk '{ print "[build] " $0; fflush(stdout) }'
) &
build_pid=$!
heartbeat "building launcher" "$build_pid" & hb_build=$!
wait "$build_pid" || true
kill "$hb_build" >/dev/null 2>&1 || true

BIN_DIR=$(swift build --package-path platform/FountainAILauncher --show-bin-path -c release)
LAUNCHER="$BIN_DIR/FountainAiLauncher"
if [[ ! -x "$LAUNCHER" ]]; then
  echo "[error] Launcher binary not found at $LAUNCHER" >&2
  exit 1
fi

echo "[run] Launching FountainAiLauncher from $LAUNCHER"
set -o pipefail
(
  "$LAUNCHER" 2>&1 | awk '{ print "[launcher] " $0; fflush(stdout) }'
) &
runner_pid=$!
heartbeat "Launcher running" "$runner_pid" & hb_pid=$!

wait "$runner_pid" || true
kill "$hb_pid" >/dev/null 2>&1 || true

status=$?
echo "[runner] EXIT status=$status at $(date +%H:%M:%S)"
exit $status
