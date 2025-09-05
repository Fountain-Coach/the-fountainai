# How does the FountainAI Gateway handle a request?

A **request** is any HTTP call reaching the gateway, typically a client prompt or function call encoded in a `ChatRequest`.

1. **Receive connection** – `NIOHTTPServer` accepts the call and hands it to the gateway's core handler.
2. **Plugin prepare chain** – each `GatewayPlugin` executes its `prepare` hook in order, allowing mutation or early rejection (401/403/429/503).
3. **Persona orchestration** – security personas such as Security Sentinel or Destructive Guardian may deny or escalate the request (202).
4. **Plugin routers** – authentication and LLM plugins inspect routes like `/chat`; if one responds, processing stops.
5. **Built-in endpoints** – unmatched calls are checked against health, metrics, JWT issuance, RoleGuard, certificate, and DNS handlers.
6. **Dynamic proxy routing** – `tryProxy` searches configured routes, applies rate limits, builds upstream URLs, and forwards requests with circuit-breaker protection, otherwise returning 404.
7. **Plugin respond chain** – plugins run `respond` hooks in reverse order, e.g., logging, before the response leaves.
8. **Metrics & logging** – counters and structured logs record every request for observability.

These chained reactions enforce authentication, safety personas, rate limiting, and auditing, creating a controlled perimeter around FountainAI's LLM services.

For more on gateway safety features, see [What functionality does the FountainAI Gateway implement to provide a safe LLM environment?](./what-functionality-does-the-fountainai-gateway-implement-to-provide-a-safe-llm-environment.md).
