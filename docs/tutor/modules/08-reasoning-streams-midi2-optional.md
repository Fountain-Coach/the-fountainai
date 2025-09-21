# Module 08 — Reasoning Streams (Optional, MIDI2)

**Outcome**: Stream planner/awareness events as SSE-over-MIDI for transparency; add basic transport controls.

## What you’ll ship
A Swift `swiftcurseskit` dashboard that renders the SSE-over-MIDI stream viewer in the left pane with event metadata on the right, anchored by a status bar showing transport state and connection health. The dashboard must map keyboard controls (`space` toggles play/pause, `r` rewinds to the first event, `n` steps to the next event) and surface on-screen hints so terminal users discover the bindings.

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
- Bind planner and awareness SSE endpoints to `swiftcurseskit` stream widgets via the MIDI2 client adapter; confirm the MIDI client identifier matches the terminal session and is discoverable to the OS MIDI stack.
- Export `MIDI_CLIENT_NAME` (or platform equivalent) before launching the curses dashboard so the MIDI2 bridge registers correctly, then `swift run` the module with terminal colors enabled.
- Validate the dashboard by connecting to staging endpoints first, watching the transport status bar for latency/backpressure indicators, and only then switch to production URLs.
- Document the expected keyboard shortcuts in the deployment notes so on-call engineers can triage from an SSH session without a pointing device.

## Hand-off to Codex
> Implement a curses-native event stream viewer that wires planner/awareness SSE endpoints into `swiftcurseskit` components, includes keyboard transport controls, and configures the MIDI client for terminal execution.
