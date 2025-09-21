# Module 04 — Planner + LLM Gateway Loop

**Outcome**: Plan then execute inside the Swift curses dashboard; the planner orchestrates steps via Function Caller with corpus context while the UI keeps focus and layout predictable.

## What you’ll ship
A two-pane Swift `swiftcurseskit` dashboard module: the left pane hosts the planner step list (creation, navigation, status), the right pane renders execution details and tool outputs. Keyboard focus should move predictably between panes (e.g., `Tab` to toggle, arrow keys within a pane) and the screen should maintain a persistent header/footer for status and capability messaging.

## Setup
- Load Planner, Function Caller, and gateway URLs from **_includes/env.md** so local runs can reach each service.
- Add the planner module target to `Package.swift` and wire dependencies on the Planner and Function Caller client libraries.
- Register the planner workspace with the curses router (menu entry or hotkey) so it can be launched via `swift run` arguments during verification.

## Specs to read
- `openapi/planner.yml`
- `openapi/function-caller.yml`
- Gateway specs used by the LLM gateway

## Behavioral acceptance
- [ ] `POST /planner` yields an ordered step list with corpus context
- [ ] `POST /planner/execute` runs steps via Function Caller and shows ordered outputs
- [ ] Planner steps can be navigated via keyboard controls inside the curses dashboard without losing focus context
- [ ] Execution status updates render live in the execution pane and refresh when the operator presses the designated manual refresh key

## Test plan
- Contract test for step ordering and minimal error handling per step
- Curses interaction test pass: simulated key events traverse planner steps, trigger execute, and confirm status refresh behavior

## Runbook
1. Export Planner, Function Caller, and gateway environment variables (`source .env`) and confirm credentials resolve.
2. Build the dashboard module: `swift build` (or target the specific planner executable if split out).
3. Launch the planner workspace: `swift run tutor-dashboard --panel planner`.
4. Trigger `POST /planner` from inside the curses pane and confirm the ordered steps appear in the left panel with focus on step 1.
5. Execute the highlighted plan (`Enter`/designated key) and watch the right pane stream Function Caller outputs; manually press the refresh key to ensure live updates continue afterward.
6. Toggle focus with `Tab`/arrow keys to confirm keyboard routing remains stable while the poller updates statuses.
7. Quit (`q`) and verify logs show paired `/planner` and `/planner/execute` calls plus any surfaced `NotSupported` capabilities.

## Hand-off to Codex
> Implement plan → execute controls wired to the documented endpoints only, rendering planner and execution panes with `swiftcurseskit` components and maintaining capability-aware status messaging in the curses UI.
