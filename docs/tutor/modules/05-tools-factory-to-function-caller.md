# Module 05 — Tools Factory → Function Caller

**Outcome**: Register a tool from an OpenAPI operation; invoke it via Function Caller; persist results.

## What you’ll ship
An end-to-end tool management workflow inside `swiftcurseskit`:

- A curses-based tool registration pane that binds `operationId` entries from Tools Factory to shared view models.
- An invocation panel that calls Function Caller endpoints and streams output into a scrolling results history buffer.
- Terminal UI rendering that surfaces past results inline (status, timestamp, payload excerpts) so operators can review history without leaving the curses session.

## Setup
- Import Tools Factory and Function Caller client libraries into the dashboard target; update `Package.swift` dependencies if missing.
- Load service credentials via **_includes/env.md** so registration/invocation calls succeed in local runs.
- Seed a test corpus/tool scenario (can reuse Module 02 data) to validate result persistence when you exercise the workflow.

## Specs to read
- `openapi/tools-factory.yml`
- `openapi/function-caller.yml`
- `openapi/persist.yml`

## Behavioral Acceptance
- [ ] Register operations in Tools Factory
- [ ] Tools appear in the curses catalog pane and are invokable by `operationId`
- [ ] Cursor navigation toggles between catalog and invocation panes with visible focus cues
- [ ] Invocation pane exposes keyboard shortcuts (e.g., `r`) to rerun the highlighted tool without re-registering
- [ ] Results history refreshes on a fixed cadence (e.g., every poll tick) and renders within the curses UI without tearing
- [ ] Results persisted in corpus with links back to tool invocation

## Test Plan
- Validate tool registration lifecycle and result persistence
- Exercise curses navigation between catalog and invocation panes (arrow keys, tab cycling)
- Verify rerun shortcuts dispatch Function Caller requests using the cached registration metadata
- Confirm results history refresh cadence matches the configured poll interval and reflects new corpus entries

## Runbook
1. Export your `.env` file so Tools Factory, Function Caller, and FountainStore URLs are available.
2. Build the dashboard target: `swift build` (or the executable name you registered for the workflow).
3. Start the curses workflow: `swift run tutor-dashboard --panel tools`.
4. Register a tool from the catalog pane (select by `operationId`, submit with `Enter`); confirm the registration success banner appears and the tool surfaces in the invocation list.
5. Move focus to the invocation pane, press the rerun binding (`r` by default) to invoke the highlighted tool, and watch the streaming output buffer populate.
6. Leave the dashboard open for two poll cycles to verify the results history refreshes automatically and persists the new record to the corpus.
7. Exit (`q`) and inspect logs to ensure the Tools Factory registration, Function Caller invocation, and FountainStore persistence calls all completed.

## Hand-off to Codex
> Wire Tools Factory and Function Caller endpoints into the shared `swiftcurseskit` view models, implement the curses panes for registration/invocation, and persist invocation outputs to the on-screen history and corpus.
