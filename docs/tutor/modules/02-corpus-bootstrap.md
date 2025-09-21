# Module 02 — Corpus Bootstrap

**Outcome**: Add a curses-driven bootstrap panel inside `swiftcurseskit` that creates a corpus, seeds roles/baselines, and surfaces the initial Awareness snapshot without leaving the terminal app.

## What you’ll ship
A new panel in the existing `swiftcurseskit` app that routes to the bootstrap API, captures corpus metadata via keyboard-driven forms, and renders the resulting baseline data alongside Awareness polling output.

## Setup
- Wire the bootstrap client dependency into `swiftcurseskit` alongside the existing FountainStore bindings.
- Ensure the terminal environment has ncurses available (`swift build` should link against `libncursesw`).
- Run FountainAiLauncher (CLI or GUI) so the Bootstrap, Awareness, and FountainStore URLs from **_includes/env.md** are provided automatically—no manual exports.

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
1. Start the supervisor with `bash Scripts/launcher start` (or the GUI) and wait for the control plane to report HTTP 200.
2. Build the dashboard to validate the new panel target compiles: `swift build`.
3. Run the terminal app: `swift run tutor-dashboard --panel bootstrap` (use the router shortcut you wired if different) and confirm the Bootstrap pane appears.
4. Navigate the curses form with `Tab`/arrow keys, submit a corpus seed, and watch the status area for the `POST /bootstrap` confirmation (corpus id + version).
5. After submission, leave the pane open for two refresh cycles; confirm Awareness data streams into the adjacent widgets without freezing keyboard focus.
6. Exit with `q`, tail `bash Scripts/launcher logs -f` to ensure FountainStore received the created corpus and Awareness polling completed without errors, then shut the stack down with `bash Scripts/launcher stop` when finished.

## Hand-off to Codex
> Implement the curses bootstrap flow end-to-end: route `/bootstrap` into the new `swiftcurseskit` panel, submit the form to `POST /bootstrap`, and wire the existing Awareness polling utilities so baseline updates hydrate the curses widgets without breaking module style conventions.
