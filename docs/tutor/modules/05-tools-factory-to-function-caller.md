# Module 05 — Tools Factory → Function Caller

**Outcome**: Register a tool from an OpenAPI operation; invoke it via Function Caller; persist results.

## What you’ll ship
An end-to-end tool management workflow inside `swiftcurseskit`:

- A curses-based tool registration pane that binds `operationId` entries from Tools Factory to shared view models.
- An invocation panel that calls Function Caller endpoints and streams output into a scrolling results history buffer.
- Terminal UI rendering that surfaces past results inline (status, timestamp, payload excerpts) so operators can review history without leaving the curses session.

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
- Configure Tools Factory and Function Caller URLs, wiring them into the shared `swiftcurseskit` view models used by both panes
- Ensure invocation responses append to the persistent results history buffer rendered in the curses interface
- Monitor poll cadence to keep the results history synchronized without flicker; adjust timer intervals if rendering lags

## Hand-off to Codex
> Wire Tools Factory and Function Caller endpoints into the shared `swiftcurseskit` view models, implement the curses panes for registration/invocation, and persist invocation outputs to the on-screen history and corpus.
