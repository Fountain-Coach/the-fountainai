# Module 08 — Reasoning Streams (Optional, MIDI2)

**Outcome**: Stream planner/awareness events as SSE-over-MIDI for transparency; add basic transport controls.

## What you’ll ship
A Swift `swiftcurseskit` dashboard that renders the SSE-over-MIDI stream viewer in the left pane with event metadata on the right, anchored by a status bar showing transport state and connection health. The dashboard must map keyboard controls (`space` toggles play/pause, `r` rewinds to the first event, `n` steps to the next event) and surface on-screen hints so terminal users discover the bindings.

## Setup
- Ensure the MIDI2 client adapter target links against the platform MIDI libraries and is referenced from `Package.swift`.
- Start FountainAiLauncher so planner/awareness streaming URLs and `MIDI_CLIENT_NAME` from **_includes/env.md** stay scoped to the supervisor.
- Prepare fixture SSE event logs so you can replay deterministic sequences during tests.

## Specs to read
- Planner/Awareness streaming endpoints
- MIDI2 transport interfaces (consumer side)

## Behavioral acceptance
- [ ] Live stream appears with event sequencing; transport works (play/stop/replay) via documented keyboard controls
- [ ] Curses dashboard redraws at the configured cadence without frame tearing and survives terminal resize events
- [ ] No out-of-spec/private calls; only documented streaming endpoints

## Test plan
- Fixture-based stream playback and UI timeline assertions
- Curses transport harness that sends keyboard events (`space`, `r`, `n`) and asserts transport state transitions
- Integration test that exercises redraw cadence (e.g., 250 ms ticker) and verifies layout recovery after simulated `SIGWINCH`

## Runbook
1. Start FountainAiLauncher (`bash Scripts/launcher start` or the GUI) so planner/awareness streaming URLs and `MIDI_CLIENT_NAME` are ready for the session.
2. Build the dashboard with MIDI support: `swift build`.
3. Launch the MIDI workspace: `swift run tutor-dashboard --panel midi-stream --color` (append `--fixtures <path>` if you support replay files).
4. Observe the connection banner to confirm the MIDI bridge announces the configured client name and the SSE stream begins populating the left pane.
5. Exercise transport controls—`space` (play/pause), `r` (rewind), `n` (next event)—and ensure the status bar updates to reflect the current state while the right pane shows matching metadata.
6. Resize the terminal to simulate `SIGWINCH` and verify the curses layout recovers without tearing or dropping events.
7. Exit with `q`, capture `bash Scripts/launcher logs -f` proving the stream consumed planner/awareness events successfully, then shut the launcher down (`bash Scripts/launcher stop`).

## Hand-off to Codex
> Implement a curses-native event stream viewer that wires planner/awareness SSE endpoints into `swiftcurseskit` components, includes keyboard transport controls, and configures the MIDI client for terminal execution.
