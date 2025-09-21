# Module 03 — Awareness: Baselines, Drift, Reflections

**Outcome**: Extend the Swift curses dashboard so baseline management, drift visualization, and reflections timelines live beside the existing awareness panes.

## What you’ll ship
A curses module that layers baseline CRUD, scrollable drift graphs, and a reflections timeline onto the Swift dashboard.

> **Setup**: Reuse the shared curses fixtures from Module 02—`swiftcurseskit` mocks, `AwarenessService` stubs, and the `DashboardHarness` integration harness—so acceptance checks can assert keyboard navigation, pane refresh cadence, and persistence wiring without duplicating scaffolding.

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
- Depend on corpus id from Module 02; reuse environment from **_includes/env.md**
- Wire Awareness endpoints into the `swiftcurseskit` view models: `BaselineListViewModel`, `DriftViewModel`, and `ReflectionsTimelineViewModel` should orchestrate data pulls while delegating rendering to existing dashboard components.
- Maintain curses UX constraints—non-blocking network calls, fixed-width columns, and shared status bar updates—by scheduling async refresh work on the dashboard's poll loop.

## Hand-off to Codex
> Implement baseline CRUD, render drift/pattern insights, and extend the reflections timeline by wiring Awareness HTTP clients into `swiftcurseskit` view models while preserving the dashboard’s keyboard and refresh behaviors.
