#!/usr/bin/env bash
set -euo pipefail

MODE=${MODE:-Tier-A}

IMPACTED_JSON=$(bash Scripts/impacted-targets.sh | jq -R -s 'split("\n") | map(select(length>0))')

BUILD_STATUS=${BUILD_STATUS:-unknown}
TEST_STATUS=${TEST_STATUS:-unknown}
BUILD_SEC=${BUILD_SEC:-0}
TESTS_SEC=${TESTS_SEC:-0}
CAP_REQ_JSON=${CAPABILITY_REQUESTS:-'[{"need":"query.fullText","count":0}]'}

jq -n \
  --arg mode "$MODE" \
  --argjson impactedTargets "$IMPACTED_JSON" \
  --arg build "$BUILD_STATUS" \
  --arg tests "$TEST_STATUS" \
  --arg buildSec "$BUILD_SEC" \
  --arg testsSec "$TESTS_SEC" \
  --argjson capabilityRequests "$CAP_REQ_JSON" \
  '{mode:$mode, impactedTargets:$impactedTargets, build:$build, tests:$tests, durations:{buildSec:($buildSec|tonumber), testsSec:($testsSec|tonumber)}, capabilityRequests:$capabilityRequests}'
