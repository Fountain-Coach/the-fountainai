# Module 06 — Teatro GUI: Spec-Only Integration

**Outcome**: Deliver spec-derived browsing panes in `swiftcurseskit` that surface corpora, baselines/drift, and planner runs without relying on GUI-only shortcuts.

## What you’ll ship
A curses workspace built with `swiftcurseskit` that renders corpora, baseline lineage, and planner execution history straight from the documented APIs.

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
- Wire FountainAI client responses directly into `swiftcurseskit` list/detail components for each pane
- Ensure keyboard commands stay in sync with HTTP refresh loops instead of GUI affordances

## Hand-off to Codex
> Surface the HTTP responses from the documented APIs in the `swiftcurseskit` panes and keep capability guidance visible inside the terminal experience. No direct file or DB access.
