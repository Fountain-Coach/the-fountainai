# FountainAI GUI Development Roadmap

This document translates the “FountainAI Platform — Current Status and Roadmap to GUI Development” into a concrete, testable, and sequenced plan for building the GUI. It aligns the GUI with the OpenAPI‑first platform, FountainStore persistence, and Teatro rendering engine.

## Summary
- Goal: Ship an OpenAPI‑driven GUI that surfaces corpus browsing, annotation, and capability‑aware workflows end‑to‑end through FountainAI services.
- Principle: GUI talks only to documented APIs; OpenAPI specs are the single source of truth.
- Persistence: FountainStore is the sole datastore (FTS and Vector optional modules available for search and semantic features).
- Rendering: Teatro provides deterministic rendering and playback primitives (including SSE‑over‑MIDI streams) for interactive experiences.

## Guiding Principles
- OpenAPI‑only: No ad‑hoc endpoints. Update and curate specs before implementation.
- Capability negotiation: Every service exposes `/v1/capabilities`; GUI surfaces missing capabilities as actionable feedback.
- Single persistence: All state and history live in FountainStore; GUI reads/writes via documented services.
- Lean CI: Fast iteration by default; full suites run on demand or for contract changes.
- Observability: Health (`/v1/health`), metrics (`/metrics`), and capability requests flow into telemetry and GUI diagnostics.

## Scope
In scope
- Corpus browsing, search (FTS/Vector), and item detail views.
- Annotations and provenance surfaces (who/what/when/why changes, lineage across services).
- Capability‑aware UX (explain missing features, offer enablement paths).
- Token/stream visualization where flows provide SSE (via LLM Gateway) and MIDI‑backed playback (via Teatro).

Out of scope (initially)
- Non‑documented/private endpoints; direct DB access.
- Multi‑tenant ops UX beyond basic environment configuration.
- Complex role‑based administration beyond gateway persona defaults.

## Dependencies (APIs and Envs)
- Gateway and guards: `openapi/v1/gateway.yml`, `auth-gateway.yml`, `rate-limiter-gateway.yml`, `payload-inspection-gateway.yml`, `destructive-guardian-gateway.yml`, `role-health-check-gateway.yml`, `security-sentinel-gateway.yml`.
- Domain services: `openapi/v1/persist.yml` (FountainStore), `bootstrap.yml`, `baseline-awareness.yml`, `semantic-browser.yml`, `planner.yml`, `function-caller.yml`, `tools-factory.yml`, `tool-server.yml`, `openapi-curator.yml`.
- LLM Gateway: `openapi/v1/llm-gateway.yml` for chat/streaming.
- Required env vars: `FOUNTAINSTORE_URL`, `FOUNTAINSTORE_API_KEY`.

## Milestones

### M0 — Foundations (Platform Alignment)
Goals
- Ensure all referenced services exist and conform to their OpenAPI specs.
- Seed baseline corpus (Bootstrap + Baseline Awareness) and verify Persist (FountainStore) paths.
- Implement capability negotiation across services; return actionable `NotSupported` errors with `need` fields.

Deliverables
- Curated OpenAPI set under `openapi/` (validated by the OpenAPI Curator).
- Seed scripts under `seeding/` produce minimal yet realistic data.
- Health/metrics surfaces verified and documented.

Acceptance
- All gateway/persona specs pass curation; `services/*` routes match contracts.
- `FOUNTAINSTORE_*` documented and validated in a local runbook.
- Capability map rendered via a simple diagnostic view (JSON output acceptable in M0).

### M1 — Corpus Browser MVP
Goals
- Browse, filter, and search items stored in FountainStore via `persist.yml` and `semantic-browser.yml`.
- Provide basic item detail view with history (MVCC snapshots), tags, and related links.

Deliverables
- GUI routes/components for: list, search, detail.
- FTS search (BM25) and vector search (HNSW) wired if modules are enabled; sensible fallback if not.
- Pagination and sort primitives; minimal keyboard navigation.

Acceptance
- Given seeded corpus, a user can: list items, run an FTS query, open a detail view, and see historical versions.
- All calls traceable in gateway logs; no undocumented endpoints used.

### M2 — Annotation & Provenance
Goals
- Create/read/update annotations bound to items and versions.
- Show provenance across services (what transformed what, when, by whom).

Deliverables
- Annotation composer with autosave and version awareness.
- Provenance panel (lineage graph or step list) derived from gateway/persona logs and Persist metadata.

Acceptance
- Users can add annotations to a specific version and retrieve them reliably.
- Provenance view shows at least: source op(s), time, actor/service, outcome.

### M3 — Capability‑Aware UX
Goals
- Surface missing capabilities returned by services; guide user to resolve (e.g., enable module, set config, open issue).

Deliverables
- Inline banners/tooltips that render `{"need": "<capability>"}` from error responses.
- A capabilities dashboard with current map fetched from each service’s `/v1/capabilities`.

Acceptance
- When backend lacks a capability, GUI shows a clear message and a resolution path; no silent failures.

### M4 — Streams, Playback, and Teatro Integration
Goals
- Visualize token streams from the LLM Gateway and support synchronized playback using Teatro primitives.

Deliverables
- Stream viewer with reliability stats, token timing, and basic controls.
- Optional MIDI 2.0 playback path (SSE over UMP) leveraging Teatro; graceful fallback without MIDI.

Acceptance
- Users can initiate a stream request, observe tokens and timing, and replay segments deterministically.

### M5 — Persistence UX Enhancements
Goals
- Saved searches, pinned items, and sharable deep links.
- Bulk operations (tagging, export) routed through documented APIs.

Deliverables
- Saved queries persisted to FountainStore; linkable views.
- Export endpoints wired (where documented) with progress and error states.

Acceptance
- Saved searches survive reload; deep links restore filters and selection.

### M6 — Hardening & Observability
Goals
- Close gaps, improve performance, and finalize diagnostics.

Deliverables
- Metrics overlays (latency, error rates) and health badges per service.
- E2E and contract test coverage for core flows.

Acceptance
- Green lean CI by default; full suites green on demand.
- SLOs defined for search latency, stream jitter, and annotation saves.

## Testing Strategy
- Contract tests: Validate requests/responses against OpenAPI via Curator; fail on drift.
- Integration tests: Seed corpus; exercise list/search/detail/annotate; verify Persist effects.
- E2E smoke: GUI boots; user completes core flows without internal errors.
- Stream tests: Simulated SSE sessions; verify token timing and UI state transitions.

## Telemetry & Output Format
- Collect `capabilityRequests` aggregated by `need` from gateway responses and display in the capabilities dashboard.
- Standard run output (for CI/dev) should include:
  ```json
  {
    "mode": "Tier-A | Tier-B",
    "impactedTargets": ["gui", "gateway", "persist"],
    "build": "passed | failed",
    "tests": "passed | failed",
    "durations": {"buildSec": 0, "testsSec": 0},
    "capabilityRequests": [{"need": "query.fullText", "count": 3}]
  }
  ```

## Risks & Mitigations
- Spec drift: Always update and curate OpenAPI first; block merges on curation failures.
- Capability gaps: Render clear UX; provide toggles/docs to enable missing modules or feature flags.
- Data shape changes: Keep Persist schemas versioned; use MVCC history to prevent breaking reads.
- Performance on large corpora: Progressive loading, indexed queries, and background prefetch.

## Environment & Local Runbook (Dev)
- Prereqs: Swift toolchain, SwiftPM; services from `services/` built via SPM.
- Env: Set `FOUNTAINSTORE_URL` and `FOUNTAINSTORE_API_KEY`.
- Start: Launch gateway and persist services; run seeders in `seeding/`.
- GUI: Run Teatro‑based frontend or host app; configure base URL to Gateway.

## Acceptance Checklist (Release Readiness)
- [ ] GUI uses only documented OpenAPI endpoints.
- [ ] Corpus browsing/search/detail complete against seeded data.
- [ ] Annotation & provenance surfaces functional and persisted.
- [ ] Capability negotiation surfaced and actionable.
- [ ] Streams visualized; playback deterministic where available.
- [ ] Health and metrics visible; SLOs defined and measured.
- [ ] Lean CI green; contract tests cover critical flows.

## References
- PDF: `docs/FountainAI Platform_ Current Status and Roadmap to GUI Development.pdf`
- Repos: Fountain‑Store, Teatro, midi2, the‑fountainai
- Platform overview: `README.md`, `agent.md`

