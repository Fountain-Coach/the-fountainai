# Codex Whitespace TUI Kit

This zip contains **everything Codex needs** to integrate with the whitespace-forward ncurses TUI system.

## Contents
- `schemas/` — JSON Schemas (`ui_response`, `ui_component`) to validate LLM output
- `prompts/` — versioned prompt files for system + tasks
- `adapter/Swift/LLMAdapter.swift` — reference Swift adapter (policy enforcement + fallback)
- `tests/` — golden test vectors for two layouts and a Fountain formatter
- `examples/` — example response

## Quick Start
1. Validate model output against `schemas/ui_response.schema.json` (which references `ui_component.schema.json`).
2. Use `adapter/Swift/LLMAdapter.swift` to call your LLM endpoint at `/v1/ui/generate`.
3. Run golden tests by sending the `*_request.json` to the endpoint and comparing normalized JSON with `*_expected.json`.

## Policies
- Max 12 components per response
- Allowed types: Heading, Card, List, Timeline, Rule, Inspector, Command
- Inspector only when terminal cols ≥ 120
- Color pairs limited to 1..4 (monochrome fallback is OK)

© 2025-09-20
