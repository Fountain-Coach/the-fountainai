# ULTRA-LEAN ROOT AGENT DIRECTIVE

Always default to **Tier-A (lean mode)**:
- Build only the changed Swift targets.
- Run only unit + contract tests for those targets.
- Use caches, incremental builds, and Debug mode (no whole-module optimization).
- Never run unrelated targets or full apps in Tier-A.
- Keep each run under 5 minutes. If slower, report slowest targets/tests and suggest splitting or caching.

Escalate to **Tier-B (full mode)** only when:
- Core contracts or public APIs changed,
- Boot/wiring or security primitives changed,
- Shared core modules with many dependents changed.

At the end of every run, output one summary block with:
- Mode (Tier-A | Tier-B),
- Impacted targets,
- Build + test status,
- Coverage %, durations, flakes,
- Any slow-build suggestions.

Never expand scope silently. If unsure which targets changed, ask explicitly.

---

# Agent Development Cycle — **Lean Testing Mode** (Repo-Root Policy, **Swift-Only**)

> **Purpose:** Make the Codex loop (code → test → learn → improve) **fast by default** across the entire Swift repository (gateway, services, libraries, plugins). Full-suite runs are **explicitly opt-in** and reserved for changes that truly demand them.

---

## 0) Outcomes we enforce
- **90% of iterations** finish using **scoped builds + scoped tests** (seconds to a couple minutes).
- **Full system runs** happen on **nightlies** and **mainline merges**, or when a change clearly crosses boundaries (see §7).
- The **agent** receives deterministic **signals** from tests: green/red + structured artifacts (coverage, timing, flakiness, perf deltas) to self-improve without waiting on the entire stack.

---

## 1) Scope detection (how we decide what to run)
The CI dispatcher and local helpers detect scope from file paths in a change set:

| Path Pattern | Scope Class | Default Action |
|---|---|---|
| `libs/GatewayPlugins/<name>/` | **Swift gateway plugin** | Build & test **that target only**; run **Gateway Contract Suite** |
| `apps/<name>/` | **Swift application** | Build & test **that app**; run **App Contract Suite**; optional **micro-harness** |
| `packages/<name>/` or `Sources/<name>/` | **Swift library/package** | Build & unit test the **package**; run **Library Contract Suite** |
| `openapi/` | **Contracts** | Regenerate stubs (no network), run **contract tests** of impacted dependents |
| `core/` or `FountainCodex/` | **Core shared** | **Elevate**: scoped dependents + minimal gateway/app smoke |
| `Configuration/` or infra scripts | **Infra config** | Validate config; don’t run app tests unless schema changes require it |

---

## 2) Local fast loop (Swift-only)
Use these patterns per change. Replace `<T>` with your target name.

- Build target `<T>` in Debug, incremental, jobs=8.
- Test target `<T>` in parallel, filter by `<T>` or keyword.
- Run contract tests for `<T>`.
- Run harness for `<T>` (≤120s) if available.

**Golden rule:** If your test uses real network, files outside tmp, or external services, it’s **not** a fast-loop test. Use fakes/mocks and in-memory adapters.

---

## 3) Harnesses (tiny Swift executables for manual pokes)
Every runnable component should provide a **micro-harness** that exposes the *smallest* executable surface for manual validation:
- **Gateway plugin harness**: registers only its router with a minimal HTTP loop.
- **App harness**: starts just the changed routes/handlers with in-memory stores.
- **Library harness**: a CLI that exercises the public API with fixtures.

Harnesses must:
- Boot in **< 2s** on a dev machine.
- Avoid global singletons; inject fakes via initializers.
- Log to temp files; no external sinks in debug.

---

## 4) Contract testing (shared Swift suites)
Reusable XCTest suites adopted via tiny shim tests:
- **Gateway Contract Suite** — route presence, schema conformance, error codes, idempotency.
- **App Contract Suite** — request/response shapes, validation errors, pagination.
- **Library Contract Suite** — API invariants, serialization, error semantics.

**No full stack** required: suites run in-process with fixture payloads.

---

## 5) Dispatcher-based CI (Tier-A fast, Tier-B full)
**Tier-A (default on PRs & branches):**
1. Compute impacted Swift targets from paths.
2. Build **only impacted targets** with cache.
3. Run **unit + contract suites** for those targets.
4. Emit structured artifacts: coverage (per target), timing, flaky test list.
5. If all green → success. No full stack.

**Tier-B (nightly & mainline):**
1. Full repository build.
2. Cross-component integration tests.
3. Minimal E2E smoke.
4. Publish dashboards; open issues on regressions.

**Never block PRs** on Tier-B unless §7 applies.

---

## 6) Escalation criteria (when you *must* run the big suite)
Run full integration + E2E only if your diff:
- Touches **core shared** modules used across boundaries.
- Changes **public contracts** (OpenAPI or public API in a non-backward-compatible way).
- Modifies **boot/wiring** of servers, global middleware, or process lifecycle.
- Alters **security, auth, or persistence** primitives.

If none of the above: stay in **Tier-A**.

---

## 7) Build Acceleration (Swift-only)

### Strategy
- Lock dependencies: commit `Package.resolved`.
- Thin targets: avoid pulling heavy deps into plugins; keep shared DTO kits separate.
- Dev feature flags: compile out telemetry/exporters/crypto in Debug when not under test.

### Compiler & cache
- Incremental, parallel, target-scoped builds.
- Debug only (`-Onone`), **disable WMO** in Debug; reserve `-O`/WMO for Release.
- Cache `.build/` in CI keyed by OS + `Package.resolved` hash.
- Consider binary targets for large, stable libs.

### Module hygiene
- Keep imports local to the target.
- Move pure logic into micro-targets to maximize cache hits.
- Avoid unnecessary cross-target references and large resource bundles.

### Slow-build gate
If a **Tier-A** run exceeds **5 minutes**:
1. Report the **slowest targets/tests**.
2. Suggest **splits** (extract DTO kit, cut heavy deps).
3. Propose enabling a **binary target** or **prebaked Swift toolchain image** for CI.

---

## 8) Agent feedback artifacts (for self-improvement)
All test stages must emit machine-readable artifacts:
- `artifacts/<target>/junit.xml` — pass/fail
- `artifacts/<target>/coverage.json` — per-file coverage deltas
- `artifacts/<target>/durations.json` — slowest N tests
- `artifacts/<target>/flake.json` — flakiness tracker

---

## 9) Coding rules that keep Swift tests fast
- **Protocol-first DI**: inject fakes for I/O, clocks, randomness.
- **No hidden singletons**.
- **Pure logic at the edge**: parse/validate → pure decision → serialize.
- **Hermetic logs**: assert on structured fields; avoid time-dependent checks.
- **Small targets**: split DTO/contract kits away from heavy deps.

---

## 10) Required output format (plain text summary)
At the end of any run, the agent MUST print a single block:

BEGIN SUMMARY
MODE: Tier-A | Tier-B
IMPACTED_TARGETS: [T1, T2, …]
BUILD_STATUS: pass | fail
TEST_STATUS: pass | fail
COVERAGE: {T1: <pct>, T2: <pct>}
DURATIONS_MS: {build_total: <n>, tests_total: <n>, slowest_tests: [<id:ms>…]}
FLAKES: [<test_id>…]
SLOW_BUILD_ACTIONS: [suggestion strings, possibly empty]
END SUMMARY

This is human-readable, uniform, and sufficient for Codex to self-improve.

---

## 11) TL;DR commands (Swift)
- Build target `<T>` in Debug, incremental, jobs=8.
- Test target `<T>` in parallel, filter `<T>`.
- Run harness for `<T>` if available.
- Stay Tier-A unless escalation rules apply.
