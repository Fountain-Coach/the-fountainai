# Tutor Path (v1.0.0)

> Documentation imported from the [Tutor v1.0.0 release](https://github.com/Fountain-Coach/tutor/releases/tag/v1.0.0). This copy tracks the upstream walkthrough so the FountainAI repo can follow the tutorial path locally.

> Each stage treats the documented APIs as the single source of truth while the curses UI surfaces service health, corpus insights, and planner activity without private backdoors.

---

## Repository Layout (Proposed)

```
README.md
AGENTS.md
LICENSE
docs/
  tutor/
    README.md
    modules/
      01-spec-literacy-and-health.md
      02-corpus-bootstrap.md
      03-awareness-baselines-drift-reflections.md
      04-planner-and-llm-gateway-loop.md
      05-tools-factory-to-function-caller.md
      06-teatro-gui-spec-only-integration.md
      07-observability-and-guards.md
      08-reasoning-streams-midi2-optional.md
    _includes/
      env.md
      repo-links.md
      testing-checklists.md
```

> **Notes**
> - Keep all module docs within `docs/tutor/modules/` and reference common snippets (env, links, testing) from `_includes/`.
> - Expect `swiftcurseskit` views—tables, forms, event loops—to hydrate from `/v1/health`, `/v1/capabilities`, and OpenAPI definitions under `openapi/` directories across repos.

---

## Global Principles

1. **Specs Drive the Dashboard** — curate the OpenAPI schema before wiring `swiftcurseskit` tables or panels.
2. **Corpus Widgets Everywhere** — hydrate curses forms from a seeded FountainStore corpus to keep data entry consistent.
3. **HTTP-Powered Curses UI** — route every `swiftcurseskit` surface (service tables, planner loops) through documented endpoints only.
4. **Capability Panels** — render `/v1/capabilities` deltas directly inside the dashboard so missing features stay visible.

## Profiles (Conceptual)

- `ai` — completions/streaming via an HTTP gateway (model-agnostic).
- `persist` — FountainStore as the durable store for corpora & artifacts.
- `teatro` — GUI that renders strictly from API responses.
- `midi2` — optional reasoning/timing/sonic transparency (SSE-over-MIDI).

## Modules

1. [**Spec Literacy & Health**](modules/01-spec-literacy-and-health.md) — list services, check `/v1/health`, and project them into `swiftcurseskit` service tables.
2. [**Corpus Bootstrap**](modules/02-corpus-bootstrap.md) — create a corpus, seed baselines/roles, and back the curses data-entry forms with FountainStore.
3. [**Awareness: Baselines, Drift, Reflections**](modules/03-awareness-baselines-drift-reflections.md) — add baselines, inspect drift patterns, and wire dashboards to awareness feeds.
4. [**Planner + LLM Gateway Loop**](modules/04-planner-and-llm-gateway-loop.md) — surface ordered planner steps in `swiftcurseskit` loops before triggering Function Caller execution.
5. [**Tools Factory → Function Caller**](modules/05-tools-factory-to-function-caller.md) — register/invoke tools from OpenAPI operations and expose invocation logs in curses panels.
6. [**Teatro GUI: Spec-Only Integration**](modules/06-teatro-gui-spec-only-integration.md) — translate lessons into a spec-bound curses shell while keeping Teatro parity.
7. [**Observability & Guards**](modules/07-observability-and-guards.md) — chart budgets, rate limits, and guardrails through `swiftcurseskit` gauges.
8. [**Reasoning Streams (Optional, MIDI2)**](modules/08-reasoning-streams-midi2-optional.md) — stream planner and awareness events into live terminal transports.

## How To Use This Path

- Start at Module 01 and continue sequentially; each module keeps the previous app useful.
- Treat the **acceptance criteria** and **test plans** as your source of truth.
- When a capability is missing, surface it in the UI as a request with guidance.

## Shared Resources

- **Environment Baseline:** [`_includes/env.md`](_includes/env.md)
- **Testing Checklists:** [`_includes/testing-checklists.md`](_includes/testing-checklists.md)
- **Repo Links:** [`_includes/repo-links.md`](_includes/repo-links.md)
