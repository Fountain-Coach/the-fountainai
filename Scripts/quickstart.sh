#!/usr/bin/env bash
set -euo pipefail

# Quickstart: build minimal tools, launch Persist locally, seed, and browse

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/.build/arm64-apple-macosx/debug"

log() { printf "[quickstart] %s\n" "$*"; }

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command '$1' not found in PATH" >&2
    exit 1
  fi
}

require swift

log "Building minimal targets (persist-server, gui-*)"
swift build --product persist-server --product gui-seed --product gui-browse --product gui-capabilities >/dev/null

PERSIST_PORT=${PERSIST_PORT:-8005}
PERSIST_URL="http://localhost:${PERSIST_PORT}"

log "Starting persist-server on ${PERSIST_URL} (background)"
DEFAULT_CORPUS_ID=${DEFAULT_CORPUS_ID:-gui} \
"$BUILD_DIR/persist-server" >/dev/null 2>&1 &
PERSIST_PID=$!
trap 'log "Stopping persist-server ($PERSIST_PID)"; kill $PERSIST_PID >/dev/null 2>&1 || true' EXIT

wait_for() {
  local url=$1; local tries=${2:-40}
  for ((i=1;i<=tries;i++)); do
    if curl -sf "$url" >/dev/null; then return 0; fi
    sleep 0.25
  done
  return 1
}

log "Waiting for persist-server to become ready..."
if ! wait_for "$PERSIST_URL/capabilities" 80; then
  echo "persist-server did not become ready at $PERSIST_URL" >&2
  exit 1
fi

log "Capabilities:"
PERSIST_URL="$PERSIST_URL" "$BUILD_DIR/gui-capabilities" 2>/dev/null || true
echo

log "Seeding default corpus 'gui'"
PERSIST_URL="$PERSIST_URL" CORPUS_ID=gui "$BUILD_DIR/gui-seed" >/dev/null || true

log "Listing corpora via gui-browse"
PERSIST_URL="$PERSIST_URL" "$BUILD_DIR/gui-browse" corpora || true

echo
log "Done. persist-server is still running (pid $PERSIST_PID)."
log "Try other commands, e.g.:"
echo "  PERSIST_URL=$PERSIST_URL $BUILD_DIR/gui-browse entities q=FountainAI type=ORG"
echo "  PERSIST_URL=$PERSIST_URL $BUILD_DIR/gui-browse segments q=swift limit=5"
echo
log "Press Ctrl-C to stop."
wait $PERSIST_PID || true

