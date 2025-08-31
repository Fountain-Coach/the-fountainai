# 🧠 FountainAI Root Agent Manifest — “Fully Tested Code”

**Scope:** Whole repository (Swift 6), CI, launcher, and plugins  
**Intent:** Make every change land with comprehensive tests and enforced coverage, automatically.

_Last updated:_ 31.08.2035

---

## 🎯 Mission

1) Generate **production-quality Swift code** _with tests first mindset_.  
2) **Enforce coverage** per target (default ≥ `MIN_COVERAGE`, see CI).  
3) Keep this file as a **machine-actionable contract** for Codex runs.

---

## ✅ Hard Rules (non-negotiable)

- **Build + Test + Coverage** must run green on macOS & Linux:  
  - `swift build -c release -Xswiftc -O -Xswiftc -warnings-as-errors`
  - `swift test -c release --enable-code-coverage`
- Use the repository script: `Scripts/coverage.sh $MIN_COVERAGE`  
  - Emits: `coverage-summary.txt`, `coverage.lcov`, `coverage-targets.txt`
- **Per-target coverage** is enforced (see `coverage.sh` targets list).  
- All PRs must add/adjust tests to keep coverage ≥ threshold for touched targets.
- Public APIs: add **golden tests** and **failure-path tests**.

---

## 🤝 Soft Rules (defaults Codex should assume)

- **Thresholds:** If not set by the PR, assume `MIN_COVERAGE = 90`.  
- **Coverage matrix:** Maintain a “What’s still uncovered?” matrix in this file (see below).  
- **Test taxonomy:**  
  - **Unit:** Pure logic, 1 module, no I/O.  
  - **Integration:** Multiple modules; start minimal HTTP servers if needed.  
  - **E2E:** Launch via `FountainAiLauncher` and verify outcomes.

---

## 🔍 Validation Rules (what Codex must verify)

- `Scripts/coverage.sh` exits **non-zero** if any tracked target is below threshold.  
- CI (`.github/workflows/ci.yml`) uses `MIN_COVERAGE` env; do not lower it without justification.  
- `coverage-targets.txt` contains **all key modules/plugins** touched by the PR.
- New code paths (error branches, edge conditions) have **explicit tests**.

---

## 🛟 Correction Logic (what to do if validation fails)

1) Parse `coverage-summary.txt` / JSON export and find **gaps**.  
2) Generate tests for missed branches/lines; prefer **small, focused** cases.  
3) Re-run coverage; if still below, add **integration/E2E** exercises.  
4) Update **matrix** and **commit**.

---

## ⚙️ Operation Cycle

> Codex must execute these steps for every iteration.

### 1. **Build & Test with Coverage**

   ```bash
   swift build -c release -Xswiftc -O -Xswiftc -warnings-as-errors
   Scripts/coverage.sh ${MIN_COVERAGE:-90}
   ```

### 2.    Export JSON (optional for fine-grained prompts)

```bash
CODECOV_DIR=$(dirname "$(swift test --show-codecov-path)")
TEST_BIN=$(find .build -name '*.xctest' | head -n 1)
llvm-cov export "$TEST_BIN" -instr-profile "$CODECOV_DIR/default.profdata" -format=json > coverage.json
```

### 3.    Regenerate Coverage Matrix (below) from coverage.json.
    
    
### 4.    Write artifacts: coverage-summary.txt, coverage.lcov, coverage-targets.txt.
    
### 5.    If touching runtime paths, run E2E through the Launcher:
```bash
swift run FountainAiLauncher --dry-run
```
or full supervised launch in CI sandbox, then hit health endpoints

### 6.    Commit: source + tests + updated agent.md matrix.

---

## 📦 Per-Target Coverage Policy

Coverage is enforced for these exemplars (Codex: keep in sync with Scripts/coverage.sh):

- libs/FountainRuntime
- apps/GatewayServer
- libs/GatewayPlugins/LLMGatewayPlugin
- libs/GatewayPlugins/AuthGatewayPlugin
- libs/GatewayPlugins/RateLimiterGatewayPlugin
- libs/GatewayPlugins/BudgetBreakerGatewayPlugin
- libs/GatewayPlugins/PayloadInspectionGatewayPlugin
- libs/GatewayPlugins/DestructiveGuardianGatewayPlugin
- libs/GatewayPlugins/SecuritySentinelGatewayPlugin

CI fails if any of the above dip below MIN_COVERAGE.

---

## 🧪 Test Types & Minimums

- **Unit:** Each new public function ⇒ ≥ 2 tests (happy path + 1 edge/failure).  
- **Integration:** For every new cross-module behavior ⇒ ≥ 1 scenario test.  
- **E2E:** For any new executable, command, or major flow ⇒ ≥ 1 scenario under the launcher.

---

## 🧭 Coverage Matrix (machine-readable)

Codex: regenerate this table each run by parsing coverage.json. Keep rows atomic.

| Feature / Path        | File(s) / Target                    | Action (what test to add)                          | Status | Blockers                  | Tags         |
|------------------------|-------------------------------------|---------------------------------------------------|--------|---------------------------|--------------|
| Example: rate limit hit | GatewayServer / RateLimiterPlugin   | Simulate over-budget burst, assert 429 + headers   | ⏳      | test clock helper missing | test, plugin |
| Example: parse failure  | FountainRuntime/Parser.swift        | Feed invalid token stream, assert error enum case  | ⏳      | —                         | test, parser |
| Example: launch failure | FountainAiLauncher                 | Corrupt binary hash → expect refusal + log         | ⏳      | fixture for hash mismatch | test, launcher |

Status: ✅ done · ⏳ todo · ⚠️ partial · ❌ missing

---

## 🧰 Prompt Snippets Codex Can Use

### Generate matrix from coverage JSON

You have coverage.json from llvm-cov export.  
List all functions/files with <100% coverage and propose ONE specific test per gap.  
Output rows for the Coverage Matrix table (no prose), grouped by target.

### Create edge/failure tests

For `<File.swift:LineRange>`, write a SwiftPM test that triggers the failure branch.  
No network or external processes unless explicitly mocked.

### E2E via Launcher

Launch FountainAiLauncher in a test harness, assert health/control-plane responses,  
and verify logs include request_id + exit_code. Fail fast on any stderr.

---

## 🧪 Acceptance Checklist (PR must satisfy)

- All tests pass on CI (Linux) and locally (macOS)  
- `Scripts/coverage.sh $MIN_COVERAGE` passes; coverage-targets.txt updated  
- Coverage Matrix updated in this file (no stale rows)  
- New behaviors include unit + (if applicable) integration/E2E tests  
- No warnings; -warnings-as-errors holds  
- Launcher flows tested when touching runtime orchestration

---

## 🗂 Artifacts & Locations

- **Coverage artifacts:** coverage-summary.txt, coverage.lcov, coverage-targets.txt  
- **Optional analysis:** coverage.json (for Codex parsing)  
- **Logs:** /logs/ (build/test summaries), feedback: /feedback/ (planning hints)

---

## 📓 Notes for Maintainers

- Prefer small PRs that complete vertical slices: code + tests + docs + matrix.  
- If you must lower MIN_COVERAGE, pin the reason and a follow-up matrix row.  
- Keep Scripts/coverage.sh authoritative for target list and measurements.

---

**Why this aligns with the repo today**

- CI already runs a **coverage script** and enforces thresholds; this draft formalizes how Codex uses it (and per-target enforcement you added).  
- The initial **coverage baseline and action plan** establish the gap; the matrix + prompts operationalize closing it.  
- The **operation cycle** matches the optimized build/test flow and the **Launcher-centric** run model.  
- The “**make the repo Codex-compatible**” matrix convention is preserved so agents can plan and act iteratively.  
- The JSON-driven **coverage-matrix** prompt matches your tutorial for LLVM coverage export + Codex loops.  
