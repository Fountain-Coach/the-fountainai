#!/usr/bin/env bash
set -euo pipefail

export PERSIST_URL="${PERSIST_URL:-http://persist.local}"
export CORPUS_ID="${CORPUS_ID:-gui}"
export BASELINE_ID="${BASELINE_ID:-baseline-1}"
export BASELINE_CONTENT="${BASELINE_CONTENT:-Initial baseline seeded by gui-seed}"
export REFLECTION_ID="${REFLECTION_ID:-refl-1}"
export REFLECTION_Q="${REFLECTION_Q:-What is the GUI MVP?}"
export REFLECTION_A="${REFLECTION_A:-Corpus browser + detail with FTS.}"

swift run gui-seed | jq .

