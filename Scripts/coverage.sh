#!/usr/bin/env bash
set -euo pipefail

THRESHOLD="${1:-0}"
SWIFT_BIN=$(command -v swift)
LLVM_COV_BIN=$(command -v llvm-cov || echo "$(dirname "$SWIFT_BIN")/../usr/bin/llvm-cov")

echo "[coverage] swift test --enable-code-coverage"
swift test --enable-code-coverage

CODECOV_DIR=$(dirname "$(swift test --show-codecov-path)")
if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "CODECOV_DIR=$CODECOV_DIR" >> "$GITHUB_ENV"
fi

TEST_BINARY=$(find .build -name '*.xctest' | head -n 1)

echo "[coverage] generating per-file summaries"
"$LLVM_COV_BIN" show "$TEST_BINARY" -instr-profile "$CODECOV_DIR/default.profdata" -summary-only > coverage-summary.txt

TARGETS=(
  "FountainRuntime:libs/FountainRuntime"
  "gateway-server:services/GatewayServer"
  "LLMGatewayPlugin:libs/GatewayPlugins/LLMGatewayPlugin"
  "AuthGatewayPlugin:libs/GatewayPlugins/AuthGatewayPlugin"
  "RateLimiterGatewayPlugin:libs/GatewayPlugins/RateLimiterGatewayPlugin"
  "BudgetBreakerGatewayPlugin:libs/GatewayPlugins/BudgetBreakerGatewayPlugin"
  "PayloadInspectionGatewayPlugin:libs/GatewayPlugins/PayloadInspectionGatewayPlugin"
  "DestructiveGuardianGatewayPlugin:libs/GatewayPlugins/DestructiveGuardianGatewayPlugin"
)

> coverage-targets.txt
COVERAGE_JSON=$("$LLVM_COV_BIN" export -summary-only "$TEST_BINARY" -instr-profile "$CODECOV_DIR/default.profdata")
for entry in "${TARGETS[@]}"; do
  name=${entry%%:*}
  path=${entry#*:}
  cov=$(echo "$COVERAGE_JSON" | jq --arg path "$path" '[.data[].files[] | select(.filename | contains($path)) | .summary.lines] | reduce .[] as $f ({covered:0,count:0}; {covered: (.covered + $f.covered), count: (.count + $f.count)}) | if .count > 0 then (.covered / .count * 100) else 0 end')
  printf "%s %.2f\n" "$name" "$cov" >> coverage-targets.txt
  printf "[coverage] %s line coverage: %.2f%%\n" "$name" "$cov"
  below=$(awk -v cov="$cov" -v thr="$THRESHOLD" 'BEGIN {print (cov < thr)}')
  if [ "$below" -eq 1 ]; then
    echo "[coverage] $name coverage ${cov}% below threshold ${THRESHOLD}%"
    exit 1
  fi
done

echo "[coverage] OK"
