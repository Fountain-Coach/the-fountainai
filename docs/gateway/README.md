# GatewayApp

Comprehensive implementation documentation for the FountainAI Gateway. The gateway is a lightweight SwiftNIO-based HTTP server that composes middleware plugins and exposes management endpoints for health, metrics, certificate renewal and dynamic routing.

## OpenAPI Specification
The Gateway API is described by the [OpenAPI document](../openapi/v1/gateway.yml). Key operations include:

- `GET /health` – uptime check returning an empty JSON object.
- `GET /metrics` – runtime counters and gauges encoded as JSON, secured with bearer authentication.
- `POST /auth/token` – verifies client credentials and issues short-lived JWTs.
- `GET /certificates` – reads metadata about the active TLS certificate.
- `POST /certificates/renew` – triggers the certificate renewal script.
- `GET /routes` – lists configured reverse-proxy routes.
- `POST /routes` – persists a new reverse-proxy route.
- `PUT /routes/{routeId}` – updates an existing route definition.
- `DELETE /routes/{routeId}` – removes a configured route.

Refer to the OpenAPI file for request and response schemas, authentication requirements and error models.

## Implementation

### `GatewayServer`
[`GatewayServer.swift`](GatewayServer.swift) wires the SwiftNIO HTTP kernel, executes the plugin pipeline and implements the management endpoints listed above. It also persists dynamic routes and delegates DNS operations when a `ZoneManager` is provided.

### `CertificateManager`
[`CertificateManager.swift`](CertificateManager.swift) schedules execution of a renewal script and exposes `start`, `stop` and `triggerNow` for manual control.

### `CredentialStore`
[`CredentialStore.swift`](CredentialStore.swift) loads API client credentials from environment variables, validates pairs and signs or verifies JSON Web Tokens used by the authentication gateway plugin.

#### Authentication Environment Variables
Define a `GATEWAY_CRED_<CLIENT_ID>` variable for each client allowed to request a token, an optional `GATEWAY_ROLE_<CLIENT_ID>` to embed a role claim, and set `GATEWAY_JWT_SECRET` to the HMAC signing key used to mint and verify JWTs.

### Entry Point
[`main.swift`](main.swift) constructs a `GatewayServer` with `CoTLogger`, `LoggingPlugin` and `PublishingFrontendPlugin` and starts listening on port 8080. Passing `--dns` additionally launches a DNS server backed by `ZoneManager`. See [DNS subsystem docs](../FountainCodex/DNS/README.md) for zone management and server details.

## Plugin Index

The gateway composes middleware plugins to augment request handling. Each plugin is documented below.

### [GatewayPlugin](GatewayPlugin.swift)
Protocol describing middleware hooks for the gateway server.

- `prepare(_:)` – Allows mutation or inspection of a request before routing. Default implementation returns the request unchanged.
- `respond(_:for:)` – Allows mutation or inspection of the response before it is returned. Default implementation returns the response unchanged.

### AuthGatewayPlugin
Provides `/auth/validate` and `/auth/claims` endpoints for token verification and claim retrieval.

### [LoggingPlugin](LoggingPlugin.swift)
Logs incoming requests and outgoing responses for debugging.

- `prepare(_:)` – Prints the request method and path.
- `respond(_:for:)` – Logs the response status for the original request.

### [PublishingFrontendPlugin](PublishingFrontendPlugin.swift)
Serves static files from disk when the router does not handle a request.

- `rootPath` – Directory containing files to be served.
- `respond(_:for:)` – Intercepts `404` responses for GET requests, serving a file with the appropriate `Content-Type` header when found.

### [CoTLogger](CoTLogger.swift)
Captures chain-of-thought responses when `/chat` requests include `include_cot: true`.

- `respond(_:for:)` – Appends sanitized `cot` entries to `logs/cot.log`.

### [BudgetBreakerPlugin](BudgetBreakerPlugin.swift)
Applies per-user request budgets with circuit breakers and health-triggered load shedding.

- `updateHealth(isHealthy:)` – Integrates autoscaling or health signals to shed load.
- `stats()` – Returns counts of allowed versus throttled requests for metrics.

### Built-in Rate Limiting
`GatewayServer` enforces per-route token bucket limits.

- `rateLimit` – Optional requests-per-minute quota on route definitions.
- Exceeding the quota returns HTTP `429` and increments throttling metrics.

---
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
