# Module 03 — Awareness: Baselines, Drift, Reflections

**Outcome**: Extend the Swift curses dashboard so baseline management, drift visualization, and reflections timelines live beside the existing awareness panes.

## What you’ll ship
A curses module that layers baseline CRUD, scrollable drift graphs, and a reflections timeline onto the Swift dashboard.

## Setup
- Reuse the shared curses fixtures from Module 02—`swiftcurseskit` mocks, `AwarenessService` stubs, and the `DashboardHarness` integration harness—so acceptance checks can assert keyboard navigation, pane refresh cadence, and persistence wiring without duplicating scaffolding.
- Populate the `.env` variables from **_includes/env.md** so baseline, drift, and reflections endpoints resolve during local runs.
- Link the Awareness client mocks into your unit tests to simulate baseline/drift/reflection responses before hitting live services.

## Specs to read
- `openapi/baseline-awareness.yml`
- `openapi/persist.yml`

## Behavioral acceptance
- [ ] `POST /corpora/{id}/baselines` persists a new baseline version and surfaces it in the Baselines pane without requiring a dashboard restart
- [ ] Version history renders as a scrollable list that highlights the active baseline and responds to `j`/`k` navigation keys
- [ ] Drift and pattern visualizations refresh every 5 seconds while the dashboard is focused, using the `/drift` endpoints without blocking other panes
- [ ] Reflections timeline supports pagination via `[` and `]`, maintains cursor position, and preserves timestamps/author badges
- [ ] Keyboard shortcuts (`b`, `d`, `r`) switch between Baseline, Drift, and Reflection panes while keeping the curses layout consistent with Module 02

## Test plan
- Verify version bump after baseline creation and ensure the curses list updates on the next refresh tick
- Validate drift/pattern data shapes, empty-state handling, and redraw cadence stays within 100ms of the refresh interval
- Exercise reflections pagination to confirm cursor persistence and keyboard shortcut routing across panes

## Runbook
1. Source your `.env` so Awareness endpoints are available (`source .env`) and ensure a corpus id exists from Module 02.
2. Build the dashboard to confirm the new panes compile: `swift build`.
3. Launch the curses UI: `swift run tutor-dashboard --panel awareness` (adjust the router argument to target your baseline/drift/reflections workspace).
4. Hit `b`, `d`, and `r` to swap between Baseline, Drift, and Reflections panes; verify each refreshes on the shared poll loop without halting other panes.
5. Create a new baseline via the UI and confirm the version list updates on the next tick; scroll with `j`/`k` to highlight the active version and inspect drift graphs.
6. Page through reflections with `[` and `]`, ensuring cursor position persists and timestamps/authors render as expected.
7. Quit with `q` and check logs for successful `/baselines`, `/drift`, and `/reflections` calls before handing off.

## Hand-off to Codex
> Implement baseline CRUD, render drift/pattern insights, and extend the reflections timeline by wiring Awareness HTTP clients into `swiftcurseskit` view models while preserving the dashboard’s keyboard and refresh behaviors.
