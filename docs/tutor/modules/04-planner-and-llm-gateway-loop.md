# Module 04 — Planner + LLM Gateway Loop

**Outcome**: Plan then execute inside the Swift curses dashboard; the planner orchestrates steps via Function Caller with corpus context while the UI keeps focus and layout predictable.

## What you’ll ship
A two-pane Swift `swiftcurseskit` dashboard module: the left pane hosts the planner step list (creation, navigation, status), the right pane renders execution details and tool outputs. Keyboard focus should move predictably between panes (e.g., `Tab` to toggle, arrow keys within a pane) and the screen should maintain a persistent header/footer for status and capability messaging.

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
- Ensure Planner and Function Caller URLs are set; surface `NotSupported` if capabilities are missing
- Map `/planner` responses into planner pane views and `/planner/execute` payloads into execution detail views via `swiftcurseskit`
- Keep capability-aware messaging in the curses UI header/footer so missing planner/execute capabilities show actionable guidance

## Hand-off to Codex
> Implement plan → execute controls wired to the documented endpoints only, rendering planner and execution panes with `swiftcurseskit` components and maintaining capability-aware status messaging in the curses UI.
