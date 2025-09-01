# 🌊 FountainAI

FountainAI is a **Swift 6 transparent reasoning engine** that speaks **MIDI 2.0 with Capability Inquiry (MIDI-CI)**.  
It projects its **OpenAPI specifications** as the constitutional source of truth and streams reasoning in **SSE-style updates over MIDI**.

**Claim:**  
> If you speak MIDI-CI, you can discover us.  
> If you speak OpenAPI, you already understand us.  

---

## 🚀 Quick start

Try streaming reasoning as Server-Sent Events over a local MIDI 2.0 loopback:

```bash
swift Examples/SSEOverMIDI/TwoSessions.swift
```

See [docs/sse-over-midi-guide.md](docs/sse-over-midi-guide.md) for setup details.

### Configure environment

Copy the example environment file and fill in your secrets:

```bash
cp .env.example .env
# edit .env and provide real values
```

`scripts/boot.sh` and other utilities will automatically load variables from `.env`.

The build pipeline relies on the [OpenAPI Curator](docs/openapi-curator.md) to produce curated service specs before registering tools with the Tools Factory.

### Required environment variables

The OpenAPI Curator service uses the following variables:

- `CURATOR_RULES_PATH` – path to the YAML rule file (default `Configuration/curator.yml`).
- `CURATOR_STORAGE_PATH` – directory where curated outputs are stored.
---

## 🎹 Identity

- **Manufacturer ID:** `TBD` (temporary `7D` in development; official MMA ID pending)  
- **Families / Models:**  
  - `Core.Kernel` — reasoning engine  
  - `Core.Orchestrator` — ensemble orchestration  
  - `GUI.DefaultUI` — standard GUI  
  - `Service.*` — official microservices  
  - `Plugin.Author.PluginName` — delegated community plugins  

Each endpoint replies to MIDI-CI **Process Inquiry** with `manufacturerId`, `family`, `model`, `version`, and persistent `muid`.

---

## 🖥️ Publishing Frontend

`libs/PublishingFrontend` provides the HTTP rendering library, and `apps/PublishingFrontendCLI` serves generated docs through a lightweight NIO HTTP server. The roadmap transforms it into the full user and administrator portal. It will render chat interfaces, plugin marketplaces, usage dashboards, and admin consoles for DNS, certificates, budgets, and system health, all driven by FountainAI's OpenAPI specifications. See [docs/PublishingFrontend/README.md](docs/PublishingFrontend/README.md) for requirements and future plans.

## 📁 Repository Structure

- apps: Executable targets (CLIs and servers)
   - GatewayServer: HTTP gateway runtime (target `gateway-server`).
   - PublishingFrontendCLI: Publishing frontend CLI (target `publishing-frontend`).
   - Flexctl: MIDI2 tooling CLI (target `flexctl`).
   - ClientgenService: Client generator service (target `clientgen-service`).
   - ToolsFactoryServer: Tool server runtime (target `tools-factory-server`).
   - OpenAPICuratorCLI: OpenAPI spec curation and promotion CLI.
   - OpenAPICuratorService: Ephemeral service exposing the curation API.
- libs: Reusable Swift libraries
   - FountainCodex: Core code generation and utilities.
   - PublishingFrontend: Publishing frontend library APIs.
   - ResourceLoader: Shared resource loading utilities.
- MIDI2: MIDI2 components (MIDI2Models, MIDI2Core, MIDI2Transports, SSEOverMIDI, FlexBridge).
- ToolServer: Tool server library (adapters, router, resources).
- internal: Generated code and internal modules (not user-edited)
   - openapi: Service specs and API codegen.
- docs: Documentation and design notes (gateway, SSE, security, proposals).
- tests: SwiftPM test targets mirroring apps/libs components.

## 📚 Learn More

- [Architecture & Pillars](docs/architecture.md)  
- [Security](docs/security/README.md)  
- [Operations & Deployment](platform/FountainAILauncher/README.md)
- [Design Patterns](docs/design-patterns.md)  
- [Licensing Matrix](docs/licensing-matrix.md)  

---
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
