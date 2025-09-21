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
- Load environment variables for FountainAI clients (see **_includes/env.md**) so the dashboard can query each documented service. Provide local `.env` defaults for contributors.

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
- Configure base URLs and keys from **_includes/env.md**
- Wire `/v1/health` responses into the `swiftcurseskit` view model that feeds service row status indicators
- Map `/v1/capabilities` payloads into `swiftcurseskit` list/detail components so operators can drill into capability explanations

## Hand-off to Codex
> Build a service table that reads from the listed specs and queries `/v1/health` and `/v1/capabilities`. No hardcoded endpoints. Ensure Codex implementers connect those endpoints to the `swiftcurseskit` views described above, preserving the refresh cadence and keyboard navigation affordances.
