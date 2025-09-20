# 🧠 FountainAI Root Agent — **OpenAPI‑Driven Platform**

_Last updated: 2025‑03‑09_

## 0) Scope & OpenAPI Surface
You own the entire FountainAI platform. **Every service below must expose and consume its OpenAPI spec**—the spec is the single source of truth:

### Core & Persistence
- `openapi/v1/bootstrap.yml` – Bootstrapping  
- `openapi/v1/baseline-awareness.yml` – Baseline Awareness  
- `openapi/v1/persist.yml` – FountainStore  

### Domain Services
- `openapi/v1/semantic-browser.yml` – Semantic Browser  
- `openapi/v1/planner.yml` (plus `openapi/v0/planner.yml` legacy reference) – Planner  
- `openapi/v1/function-caller.yml` – Function Caller  
- `openapi/v1/tool-server.yml` – Tool Server  
- `openapi/v1/tools-factory.yml` – Tools Factory  
- `openapi/v1/openapi-curator.yml` – OpenAPI Curator  

### Gateways & Guards
- `openapi/v1/gateway.yml` – Core Gateway  
- `openapi/v1/auth-gateway.yml` – Auth Gateway  
- `openapi/v1/budget-breaker-gateway.yml` – Budget Breaker Gateway  
- `openapi/v1/curator-gateway.yml` – Curator Gateway  
- `openapi/v1/destructive-guardian-gateway.yml` – Destructive Guardian Gateway  
- `openapi/v1/payload-inspection-gateway.yml` – Payload Inspection Gateway  
- `openapi/v1/rate-limiter-gateway.yml` – Rate Limiter Gateway  
- `openapi/v1/role-health-check-gateway.yml` – Role Health‑Check Gateway  
- `openapi/v1/security-sentinel-gateway.yml` – Security Sentinel Gateway  

### Infrastructure Utilities
- `openapi/v1/dns.yml` – DNS Service  
- `openapi/v1/llm-gateway.yml` – LLM Gateway  

### Tests & Fixtures
- `Tests/ToolsFactoryServiceTests/openapi/v1/tools-factory.yml` – Tools Factory test spec  

_Add new services by adding their OpenAPI document under `openapi/` and updating this list._

## 1) Golden Rule
> **OpenAPI specs are authoritative for every interface.**  
> Before changing behavior, update the relevant spec and curate it. No ad‑hoc endpoints or undocumented parameters.

## 2) Deliverables (Platform‑Wide)

1. **Spec Curation**  
   - Keep all specs under `openapi/`.  
   - After any change, call the OpenAPI Curator (`POST /curate`) with all spec files.

2. **Service Alignment**  
   - Ensure every service in the list above conforms exactly to its OpenAPI.  
   - The Teatro GUI must communicate **only** through documented APIs.

3. **Corpus Semantics**  
   - FountainStore is the sole persistence layer.  
   - Bootstrapping and Baseline Awareness define corpus semantics; all services operate on corpus‑aware endpoints.

4. **GUI Development**  
   - Build Teatro components (corpus browser, annotation surfaces, capability‑aware feedback).  
   - Remove legacy indexer UI code and wire all flows to FountainStore.

5. **Documentation**  
   - Keep `docs/` aligned with OpenAPI-driven architecture and GUI entry points.

## 3) Capability Negotiation
- On startup, each service calls its counterpart’s `/v1/capabilities`.  
- If an operation requires a missing capability, respond with `400 NotSupported`, log the request (`"need": "<capability>"`), and surface the feedback in the GUI.  
- Forward capability requests to the Launcher for telemetry.

## 4) Tests & CI (Lean by Default)
Maintainers delegate the **entire test strategy to you**.  
You may run, limit, or skip tests to keep iterations fast.

- Use `swift build` or `swift run` for quick GUI cycles (no tests).  
- Run targeted tests via `swift test --filter <Pattern>` when needed.  
- Full suite only when `FULL_TESTS=1` or contract changes demand it.

## 4.1) Launcher App Quickstart (No Xcode)
The macOS menubar app is `FountainAILauncherApp`. SwiftPM builds a binary; we provide a bundler to produce a clickable `.app`.

- Build (binary):
  - `swift build --product FountainAILauncherApp`
- Bundle (.app):
  - `bash Scripts/make_app.sh FountainAILauncherApp`
- Launch:
  - `open dist/FountainAILauncherApp.app`

## 5) Configuration & Security
Required environment variables for services:

FOUNTAINSTORE_URL
FOUNTAINSTORE_API_KEY

- Health checks: `/v1/health`  
- Metrics: `/metrics`  
- Launcher remains the golden entry point referencing this file.

GUI specific:
- OpenAI provider requires only an API key (captured via onboarding, stored in Keychain).  
- No base URL is required for OpenAI.  
- Local advanced features (Persist/Semantic Browser) remain optional and off by default.

## 6) Acceptance Checklist
- [ ] Every service implementation matches its OpenAPI spec.  
- [ ] Bootstrapping + Baseline Awareness define corpus semantics across the platform.  
- [ ] Teatro GUI communicates solely via documented OpenAPIs.  
- [ ] Capability negotiation implemented and logged.  
- [ ] Lean CI (your chosen tier) green.  
- [ ] `FOUNTAINSTORE_*` environment variables documented in Launcher/Ops.
- [ ] `FountainAILauncherApp` builds, bundles, and launches via Build · Bundle · Launch sequence.

## 7) Tooling & Permissions
- Scripts are provided under `Scripts/` and are executable. When in doubt, run via bash:
- `bash Scripts/make_app.sh FountainAILauncherApp`
  - `bash Scripts/quickstart.sh` (optional local Persist demo)
- The agent may perform any Swift build/test/run steps necessary to guide users to the Build · Bundle · Launch path.

## 8) Output Format
At the end of every run, print:

```json
{
  "mode": "Tier-A | Tier-B",
  "impactedTargets": ["..."],
  "build": "passed | failed",
  "tests": "passed | failed",
  "durations": {"buildSec": 0, "testsSec": 0},
  "capabilityRequests": [{"need": "query.fullText", "count": 3}]
}
```

## 9) Placement
This file lives at the repository root as agent.md and is your canonical contract.

```
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
```
