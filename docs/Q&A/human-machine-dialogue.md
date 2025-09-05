# Human–Machine Dialogue and Reasoning in FountainAI.

FountainAI coordinates conversations between people and specialized services, capturing reasoning and streaming results across diverse channels.

## Who participates in a dialogue?

- **Users** supply prompts or requests.
- **Clients** package those prompts into `ChatRequest`s and deliver them to the gateway.
- **Orchestrators** consult personas and external services before allowing a request to proceed, as implemented in the [Gateway Persona Orchestrator](../../libs/GatewayPersonaOrchestrator/GatewayPersonaOrchestrator/GatewayPersonaOrchestrator.swift).

## What planner endpoints guide reasoning?

Planner services expose HTTP endpoints that break a high-level goal into executable steps. Orchestrators call these endpoints when additional structure is needed, blending the planner's roadmap with persona decisions before responding to the user.

## How does SSE-over-MIDI streaming work?

FountainAI can stream responses over MIDI by encoding Server‑Sent Events as MIDI SysEx frames. The [example](../../Examples/SSEOverMIDI/main.swift) demonstrates sending tokens as MIDI packets and reconstructing the stream on the receiving side.

