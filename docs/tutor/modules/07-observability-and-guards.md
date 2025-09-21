# Module 07 — Observability & Guards

**Outcome**: Extend the Swift curses dashboard with live widgets that surface gateway budgets, rate limits, and guard prompts in-line with operator workflows.

## What you’ll ship
Swift `swiftcurseskit` indicators that paint budget/rate-limit states, prompt overlays for destructive operations, and guard status banners that refresh alongside the terminal dashboard.

## Setup
- Add gateway client dependencies (budget breaker, rate limiter, guard) to the dashboard target.
- Export gateway secrets and URLs using **_includes/env.md** before running locally.
- Capture sample responses/headers for throttled and approved calls to drive automated tests.

## Specs to read
- Gateway OpenAPIs: budget breaker, rate limiter, destructive operations guard, security sentinel

## Behavioral acceptance
- [ ] Gateway budget and rate-limit headers are polled on the curses dashboard cadence and update the corresponding widgets without flicker
- [ ] Sensitive/destructive calls require keyboard confirmation within the curses prompt and block until the gateway guard approves
- [ ] Guard alerts render as terminal overlays that clear on acknowledgment while the API response metadata remains visible for audit
- [ ] Metrics remain available via `/metrics` or equivalent endpoints for downstream collectors

## Test plan
- Exercise simulated throttling to verify curses indicators reflect header changes and API responses stay correct
- Trigger guard rails to confirm keyboard confirmation flows mirror gateway decisions and that API contracts remain honored

## Runbook
1. `source .env` to load gateway endpoints and API keys into your session.
2. Build the dashboard target: `swift build`.
3. Start the observability workspace: `swift run tutor-dashboard --panel guards` (or equivalent hotkey).
4. Trigger API calls that return rate-limit headers and confirm the dashboard widgets update without flicker on the next poll tick.
5. Initiate a destructive action and verify the curses prompt overlay appears, requires keyboard confirmation, and logs the guard decision.
6. Simulate throttling/approval scenarios via fixtures or staging services to ensure banners and overlays react correctly.
7. Exit with `q` and review logs for captured headers, guard prompts, and confirmation that the poll cadence stayed active.

## Hand-off to Codex
> Wire gateway metadata into the Swift terminal UI via `swiftcurseskit` components and maintain operator prompts end-to-end in the curses experience.
