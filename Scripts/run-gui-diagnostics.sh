#!/usr/bin/env bash
set -euo pipefail

export GATEWAY_URL="${GATEWAY_URL:-http://gateway.local}"
export PERSIST_URL="${PERSIST_URL:-http://persist.local}"
export SEMANTIC_BROWSER_URL="${SEMANTIC_BROWSER_URL:-http://semantic-browser.local}"
export LLM_GATEWAY_URL="${LLM_GATEWAY_URL:-http://llm-gateway.fountain.coach/api/v1}"

swift run gui-diagnostics | jq .

