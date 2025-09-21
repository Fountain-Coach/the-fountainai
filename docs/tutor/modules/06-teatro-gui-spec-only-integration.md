# Module 06 — Teatro GUI: Spec-Only Integration

**Outcome**: Deliver spec-derived browsing panes in `swiftcurseskit` that surface corpora, baselines/drift, and planner runs without relying on GUI-only shortcuts.

## What you’ll ship
A curses workspace built with `swiftcurseskit` that renders corpora, baseline lineage, and planner execution history straight from the documented APIs.

## Setup
- Reuse the curses dashboard shell from prior modules and register a Teatro workspace entry in the router.
- Load FountainStore, Awareness, Planner, and Function Caller URLs from **_includes/env.md** to keep the panes spec-only.
- Prepare fixture JSON responses for each pane to validate parsing before pointing at live services.

## Specs to read
- The same specs from Modules 02–05 (persist, awareness, planner, tools, function caller)

## Behavioral acceptance
- [ ] Each pane (corpora, baselines, planner runs) loads exclusively from documented HTTP responses
- [ ] Keyboard navigation transitions between panes and datasets without stale state or hidden shortcuts
- [ ] Rendered records stay read-only and match spec-defined schemas
- [ ] Missing capability paths echo the documented guidance inside the curses views

## Test plan
- Simulate navigation keystrokes to move between corpora, baseline timelines, and planner runs
- Assert rendered cells map 1:1 with spec payloads and remain read-only
- Verify only documented endpoints are invoked when refreshing panes
- Snapshot the curses output against canned API fixtures to prevent regression drift

## Runbook
1. Source your `.env` so all service URLs are available in the shell.
2. Build the dashboard: `swift build`.
3. Launch the Teatro workspace: `swift run tutor-dashboard --panel teatro` (or the menu shortcut you registered).
4. Cycle between the corpora, baseline lineage, and planner history panes using the documented hotkeys; confirm each pane fetches data exclusively via HTTP (watch logs for matching endpoints).
5. Attempt to edit a record and verify the UI stays read-only—no extra requests should fire beyond the documented GET calls.
6. Leave the dashboard running through two refresh intervals to observe the spec responses refreshing without hidden GUI shortcuts.
7. Exit with `q` and review console output to confirm only documented endpoints were invoked.

## Hand-off to Codex
> Surface the HTTP responses from the documented APIs in the `swiftcurseskit` panes and keep capability guidance visible inside the terminal experience. No direct file or DB access.
