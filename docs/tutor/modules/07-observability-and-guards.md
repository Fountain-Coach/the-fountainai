# Module 07 — Observability & Guards

**Outcome**: Extend the Swift curses dashboard with live widgets that surface gateway budgets, rate limits, and guard prompts in-line with operator workflows.

## What you’ll ship
Swift `swiftcurseskit` indicators that paint budget/rate-limit states, prompt overlays for destructive operations, and guard status banners that refresh alongside the terminal dashboard.

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
- Configure gateway base URLs and route response headers/metadata into `swiftcurseskit` data sources feeding the dashboard widgets
- Persist and rehydrate operator prompts within the curses UI so guard dialogues survive screen refreshes and reconnects

## Hand-off to Codex
> Wire gateway metadata into the Swift terminal UI via `swiftcurseskit` components and maintain operator prompts end-to-end in the curses experience.
