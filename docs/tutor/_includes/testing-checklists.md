# Testing checklists (contract-first)

Use these recurring checklists across modules:

## Health & Capabilities
- [ ] `/v1/health` returns 200 and includes build/revision info
- [ ] `/v1/capabilities` enumerates features; unknowns marked `NotSupported`

## Corpus I/O
- [ ] Create/read/update corpus resources through FountainStore
- [ ] Versioning semantics are visible where applicable (baselines, cards, scenes)

## Planner Loop
- [ ] `POST /planner` returns ordered steps with corpus context
- [ ] `POST /planner/execute` orchestrates tools via Function Caller

## GUI Discipline
- [ ] GUI issues only HTTP requests against documented OpenAPI operations
- [ ] Missing capabilities are surfaced with actionable messaging (no crashes)

## Curses UI
- [ ] Refresh cadence stays aligned with the `swiftcurseskit` render loop so screens reuse the shared throttling instead of hand-rolled timers
- [ ] Keyboard navigation hooks into the `swiftcurseskit` shortcut maps; module-specific keys are layered on top without overriding core bindings
- [ ] Focus management defers to the `swiftcurseskit` focus stack so only one pane or form captures input and tab/arrow order remains deterministic
- [ ] Redraw stability matches `swiftcurseskit` double-buffer expectations—no flicker, ghosting, or partial updates when data streams in

## Observability & Guards
- [ ] Budget/Rate limit decisions observable in responses/headers
- [ ] Destructive operations require explicit guard approval paths
