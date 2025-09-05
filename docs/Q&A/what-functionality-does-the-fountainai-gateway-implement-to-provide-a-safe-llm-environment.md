# What functionality does the FountainAI Gateway implement to provide a safe LLM environment?

FountainAI Gateway is a SwiftNIO-based HTTP gateway that centralizes HTTPS termination, request routing, and control-plane APIs. It exposes health, metrics, JWT issuance, certificate management, and dynamic route CRUD for centralized service management.

## Plugin architecture
`GatewayServer` composes a pipeline of `GatewayPlugin` implementations that can mutate or block requests and responses. Built-in plugins include logging and static-file fallback. Plugins are registered via lightweight extension files to keep dependencies modular.

## Security and safety controls
Authentication and authorization rely on signed JWTs and configurable validators. RoleGuard enforces path-based scopes, while rate limiting, payload inspection, destructive-operation gating, budget breakers, and a Security Sentinel offer defense-in-depth. Comprehensive metrics surface unauthorized access, allowances, and plugin-specific events.

Requests are additionally validated against a curator-provided truth table; see [gateway evidence checks](../gateway/README.md#curatorgatewayplugin) for details.

## Operational features
TLS certificates can auto-renew or be manually triggered. Routes are stored on disk with CRUD APIs, DNS zones can be managed through an optional ZoneManager (see [How does DNS work in FountainAI?](./how-does-dns-work-in-fountainai.md)), and RoleGuard rules hot-reload via an admin endpoint. Additional plugins can be added to extend gateway behavior.

## Safe LLM environment
By forcing all LLM traffic through the plugin chain, FountainAI centralizes auth, rate limiting, payload vetting, and audit logging. Destructive actions require approval, suspicious payloads can be denied, and every request and response is observable, creating a controlled perimeter around LLM backends.

