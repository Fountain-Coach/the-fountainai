# 🧠 FountainAI Root Agent — **Task‑Scoped Contract**

**Scope:** This repository (Swift 6). **Operational scope per PR:** only the *current task* (changed files + directly affected interfaces).  
**Intent:** Codex implements and tests **the task at hand**, not the whole system. Keep the feedback loop **≤ 5 minutes**.

_Last updated:_ 01.09.2025

---

## TL;DR

- **Constrain** to the **Impact Cone**: `{changed files} ∪ {their public interfaces} ∪ {direct dependents}`.  
- **Fast unit tests only** for impacted targets (mocks/stubs by default).  
- **No coverage, no Linux, no broad E2E** in the task loop.  
- Escalate minimally only when a cross‑module contract actually changes.

---

## ✅ Hard Rules (per task iteration)

1) **Build fast & strict** (Debug + warnings as errors):  
```bash
swift build -c debug -Xswiftc -Onone -Xswiftc -enable-testing -Xswiftc -warnings-as-errors
```

2) **Test only the Impact Cone** (parallel, filtered):  
```bash
Scripts/impacted-targets.sh | xargs -I {} swift test --parallel --filter {}
```

3) **Every changed public API**: add **1 happy path + 1 failure path** unit test.  
4) **Do not** call real network/processes in task loop (use mocks/stubs).

---

## 🤝 Soft Rules (defaults)

- Behavioral test names (Given/When/Then).  
- Use test builders/fixtures; avoid deep graphs.  
- If a test > 500 ms → refactor/mock.  
- Skip trivial pass‑throughs unless guarding invariants.

---

## 🔍 Validation (what Codex must check each run)

- Changed files compile with **no warnings**.  
- Impact Cone unit tests **green**.  
- Changed **public APIs** have happy/failure tests.  
- If change is cross‑module, add **exactly one** contract/integration smoke (≤ 10s).

---

## 🛟 Correction Logic

1) Narrow the cone; isolate with stubs.  
2) Add a **micro‑test** for the failing branch.  
3) If still failing, add a seam test (interface‑level).  
4) Only if necessary, add **one** integration smoke (≤ 10s).

---

## ⚙️ Task Loop

1) **State the Task Contract** (inputs/outputs/invariants).  
2) **List Impact Cone** via script.  
3) **Write/adjust tests first** for the changed logic/API.  
4) **Implement** until green with filtered tests.  
5) If cross‑module, add one seam test (≤ 10s).  
6) **Commit** code + tests + short task note.

---

## 🧪 Escalation Matrix

| Risk | Criteria | Extra checks |
|------|---------|--------------|
| Low  | Pure internal logic | none |
| Med  | Public API change in one module | 1 interface contract test |
| High | Cross‑module protocol/security/launcher | 1 integration smoke (≤10s) |

> Coverage, Linux, and broad E2E live in the **full suite** (nightly / main / opt‑in label).

---

## 🧰 CI: Minimal PR Workflow (reference)

```yaml
# .github/workflows/task-fast.yml
name: task-fast
on:
  pull_request:
    types: [opened, synchronize, reopened]
jobs:
  fast:
    runs-on: macos-latest
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/cache@v4
        with:
          path: |
            .build
            ~/.swiftpm
          key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
          restore-keys: ${{ runner.os }}-spm-
      - run: swift build -c debug -Xswiftc -Onone -Xswiftc -enable-testing -Xswiftc -warnings-as-errors
      - run: Scripts/impacted-targets.sh | tee impacted-filters.txt
      - run: xargs -I {} swift test --parallel --filter {} < impacted-filters.txt
```

---

## 🛠 Script: `Scripts/impacted-targets.sh` (drop‑in)

```bash
#!/usr/bin/env bash
set -euo pipefail

BASE=${BASE_REF:-origin/main}

# 1) changed source files against main
CHANGED=$(git diff --name-only "$BASE"...HEAD | grep -E '\.(swift|c|cpp|mm|metal)$' || true)

# Nothing relevant changed → print a no-op filter so CI can exit 0 after build
if [[ -z "$CHANGED" ]]; then
  echo '^Noop$'
  exit 0
fi

# 2) naive path→target mapper aligned with repo layout
# libs/<Module>/..., apps/<App>/...
TARGETS=()
while IFS= read -r f; do
  top=$(echo "$f" | awk -F'/' '{print $1}')
  mod=$(echo "$f" | awk -F'/' '{print $2}')
  case "$top" in
    libs) name="$mod" ;;
    apps) name="$mod" ;;
    *)    name="" ;;
  esac
  [[ -n "${name}" ]] && TARGETS+=("^${name}\.\|\b${name}Tests\.")
done <<< "$CHANGED"

# 3) de-dupe; fallback to running all tests if mapping failed
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  echo '.*'   # run all tests as a safe fallback
else
  printf '%s\n' "${TARGETS[@]}" | sort -u
fi
```

> You can later replace the naive mapper with a precise `swift package describe --type json` → `jq` mapping. The naive version keeps PRs fast today.

---

## 📓 Maintainers

- Keep PRs **small & vertical** (code + tests).  
- If a module grows flaky, quarantine extra checks to a **full-suite** workflow (nightly/main/label).  
- Avoid adding coverage or Linux to PR loop; reserve for gates that aren’t speed‑critical.
