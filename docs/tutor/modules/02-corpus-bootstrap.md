# Module 02 — Corpus Bootstrap

**Outcome**: Add a curses-driven bootstrap panel inside `swiftcurseskit` that creates a corpus, seeds roles/baselines, and surfaces the initial Awareness snapshot without leaving the terminal app.

## What you’ll ship
A new panel in the existing `swiftcurseskit` app that routes to the bootstrap API, captures corpus metadata via keyboard-driven forms, and renders the resulting baseline data alongside Awareness polling output.

## Setup
- Wire the bootstrap client dependency into `swiftcurseskit` alongside the existing FountainStore bindings.
- Ensure the terminal environment has ncurses available (`swift build` should link against `libncursesw`).
- Configure environment variables for Bootstrap, Awareness, and FountainStore endpoints (see **_includes/env.md**) so the panel can submit and refresh data.

## Specs to read
- `openapi/bootstrap.yml`
- `openapi/persist.yml`
- `openapi/baseline-awareness.yml`

## Behavioral acceptance
- [ ] `POST /bootstrap` creates a corpus and seeds roles/baselines
- [ ] FountainStore reflects corpus records; Awareness shows an initial snapshot
- [ ] The curses form allows full keyboard navigation (Tab/Shift-Tab or arrow keys) between fields and actions without mouse input
- [ ] After a corpus is created, the panel triggers a refresh cadence that repolls Awareness until the baseline snapshot renders in the UI

## Test plan
- Confirm corpus creation returns identifiers and version info
- Confirm Awareness reads back seeded baseline
- Exercise curses navigation in a local run (`swift run swiftcurseskit`) to ensure focus states and submit shortcuts operate as documented
- Validate that the panel repolls Awareness on an interval after corpus creation and stops once the baseline is shown

## Runbook
- Ensure FountainStore, Bootstrap, and Awareness URLs are configured (see **_includes/env.md**) and routed through the `swiftcurseskit` configuration layer.
- Register the new panel in the router so `/bootstrap` commands or menu entries open the curses view instead of a placeholder.
- Keep the Awareness poller scoped to the panel view and reuse existing module logging so refresh cadence issues surface in the standard terminal status area.

## Hand-off to Codex
> Implement the curses bootstrap flow end-to-end: route `/bootstrap` into the new `swiftcurseskit` panel, submit the form to `POST /bootstrap`, and wire the existing Awareness polling utilities so baseline updates hydrate the curses widgets without breaking module style conventions.
