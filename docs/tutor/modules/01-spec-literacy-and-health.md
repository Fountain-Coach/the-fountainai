# Module 01 — Spec Literacy & Health

**Outcome**: Deliver a Swift curses dashboard powered by `swiftcurseskit` that enumerates services from OpenAPI specs, checks `/v1/health`, and lists `/v1/capabilities`.

## What you’ll ship
A terminal dashboard built with `swiftcurseskit` that renders documented services with live health and capability status.

## Setup
- Add `swiftcurseskit` as a SwiftPM dependency and include the module target in your executable:

  ```swift
  // Package.swift (excerpt)
  dependencies: [
      .package(url: "https://github.com/fountainai/swiftcurseskit", from: "1.2.0")
  ],
  targets: [
      .executableTarget(
          name: "TutorDashboard",
          dependencies: [
              .product(name: "SwiftCursesKit", package: "swiftcurseskit")
          ]
      )
  ]
  ```
- Keep FountainAiLauncher available (CLI or GUI). It will start every service with the signed environment documented in **_includes/env.md**—no manual exports or `.env` sourcing required.

## Specs to read
- `openapi/bootstrap.yml`
- `openapi/baseline-awareness.yml`
- `openapi/persist.yml` (FountainStore)
- `openapi/planner.yml`
- `openapi/function-caller.yml`
- `openapi/tools-factory.yml`
- Relevant gateway specs (rate limiter, budget breaker, security, etc.)

## Behavioral acceptance
- [ ] Load the above specs and render a services table (name, base URL, health, capabilities)
- [ ] Unknown/missing capability is shown with guidance: “Needs: <capability>”
- [ ] The curses view refreshes on a predictable cadence (e.g., every 5 seconds) and responds immediately to manual refresh commands
- [ ] Keyboard navigation (arrow keys/tab) moves focus across service rows without breaking health/capability polling

## Test plan
- Validate 200 from `/v1/health` per service
- Parse and render `/v1/capabilities`
- Exercise the refresh loop to confirm screen redraws occur without input glitches
- Simulate navigation keystrokes to verify focus handling and status updates remain in sync

## Runbook
1. Start the supervisor: `bash Scripts/launcher start` (or launch the macOS GUI). Wait for the log message `control plane is reachable` or check `http://127.0.0.1:9090/status` for HTTP 200.
2. Build the dashboard target to ensure dependencies resolve: `swift build`.
3. Launch the curses UI with `swift run tutor-dashboard` (append `--preview` to capture a headless snapshot) and wait for the services table to populate.
4. Use the arrow keys or `Tab` to move focus between rows; verify the health column flips to green once `/v1/health` returns `200` and that the capabilities column lists `/v1/capabilities` responses with "Needs: <capability>" for gaps.
5. Press the manual refresh binding (configured per `swiftcurseskit` defaults) and confirm the poll timer still re-runs every ~5 s without breaking keyboard navigation.
6. Exit with `q`; review `bash Scripts/launcher logs -f` to confirm both `/v1/health` and `/v1/capabilities` calls succeeded before handing off, then stop the stack with `bash Scripts/launcher stop` if you're done.

## Hand-off to Codex
> Build a service table that reads from the listed specs and queries `/v1/health` and `/v1/capabilities`. No hardcoded endpoints. Ensure Codex implementers connect those endpoints to the `swiftcurseskit` views described above, preserving the refresh cadence and keyboard navigation affordances.
