#!/usr/bin/env bash
set -euo pipefail

# FountainAI GUI E2E sanity: seed -> diagnostics -> browse

# Config (override via env)
export PERSIST_URL="${PERSIST_URL:-http://persist.local}"
export GATEWAY_URL="${GATEWAY_URL:-http://gateway.local}"
export SEMANTIC_BROWSER_URL="${SEMANTIC_BROWSER_URL:-http://semantic-browser.local}"
export LLM_GATEWAY_URL="${LLM_GATEWAY_URL:-http://llm-gateway.fountain.coach/api/v1}"
export CORPUS_ID="${CORPUS_ID:-gui}"
export BASELINE_ID="${BASELINE_ID:-baseline-1}"
export BASELINE_CONTENT="${BASELINE_CONTENT:-Initial baseline seeded by gui-seed}"
export REFLECTION_ID="${REFLECTION_ID:-refl-1}"
export REFLECTION_Q="${REFLECTION_Q:-What is the GUI MVP?}"
export REFLECTION_A="${REFLECTION_A:-Corpus browser + detail with FTS.}"

echo "[1/4] Seeding corpus: ${CORPUS_ID}"
swift run -c debug gui-seed || { echo "Seeding failed" >&2; exit 1; }

echo "[2/4] Running diagnostics"
swift run -c debug gui-diagnostics || { echo "Diagnostics failed" >&2; exit 1; }

echo "[3/4] Browsing corpora"
swift run -c debug gui-browse corpora || { echo "Browse corpora failed" >&2; exit 1; }

echo "[4/4] Browsing segments/entities"
swift run -c debug gui-browse segments q=swift limit=5 || true
swift run -c debug gui-browse entities q=FountainAI type=ORG limit=5 || true

echo "E2E sanity completed."

