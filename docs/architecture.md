# 🏛 Architecture & Pillars

FountainAI organizes its Swift packages into modular layers.

## Golden Rule

All persistent data—including configuration—must reside in a FountainStore corpus. Services load and persist state through the corpus tree instead of local files, keeping deployments consistent and auditable.

## Architecture

- [Sources/FountainCodex/Parser/SpecLoader.swift](../Sources/FountainCodex/Parser/SpecLoader.swift#L1-L33) // loads OpenAPI specs and normalizes JSON or YAML
- [Sources/FountainCodex/ClientGenerator](../Sources/FountainCodex/ClientGenerator) // emits type-safe client code from specs
- [Sources/FountainCodex/ServerGenerator](../Sources/FountainCodex/ServerGenerator) // emits server routers and handlers
- [Sources/GatewayApp/GatewayServer.swift](../Sources/GatewayApp/GatewayServer.swift#L11-L41) // HTTP gateway with plugin chain and DNS utilities
- [Sources/ToolServer/main.swift](../Sources/ToolServer/main.swift) // OpenAPI-driven tool runtime
- [Sources/SSEOverMIDI/SseOverMidi.swift](../Sources/SSEOverMIDI/SseOverMidi.swift) // library for streaming reasoning over MIDI 2.0
- [Examples/SSEOverMIDI/TwoSessions.swift](../Examples/SSEOverMIDI/TwoSessions.swift) // demo wiring sender and receiver
- [Sources/PublishingFrontend](../Sources/PublishingFrontend) // static documentation server
- [FountainAiLauncher/Sources](../FountainAiLauncher/Sources) // supervisor launching configured services
- [ToolsmithPackage](../toolsmith) // orchestration package for tool generation

## Pillars

- **OpenAPI as constitution** — [SpecLoader](../Sources/FountainCodex/Parser/SpecLoader.swift#L1-L33) // specs drive model, client, and server generation
- **Transparent reasoning** — [TwoSessions.swift](../Examples/SSEOverMIDI/TwoSessions.swift#L1-L80) // streams thoughts through MIDI property notifications
- **Plugin-based gateway** — [GatewayPlugin.swift](../Sources/GatewayApp/GatewayPlugin.swift#L1-L60) // middleware prepare/respond hooks
- **Security and observability** — [LoggingPlugin.swift](../Sources/GatewayApp/LoggingPlugin.swift#L1-L40) // request/response logging
- **Automation** — [FountainAiLauncher](../FountainAiLauncher/Sources) // supervises services defined in configuration

## Undocumented Areas

- [Sources/FlexBridge](../Sources/FlexBridge) // TODO: document Flex backend bridge
- [Sources/MIDI2Transports](../Sources/MIDI2Transports) // TODO: detail transport abstractions
- [Sources/ResourceLoader](../Sources/ResourceLoader) // TODO: clarify resource discovery
- [Sources/clientgen-service](../Sources/clientgen-service) // TODO: describe service wrapper
- [Sources/flexctl](../Sources/flexctl) // TODO: document CLI controls
- [Sources/MIDI2Models](../Sources/MIDI2Models) // TODO: expand model coverage

---

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
