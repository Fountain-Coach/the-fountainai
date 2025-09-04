# OpenAPI Coverage Index

This index tracks which FountainAI components expose OpenAPI specifications. Update this file whenever a new service or tool is added to keep coverage consistent.

## Services with OpenAPI Specs

| Service | OpenAPI Spec |
| --- | --- |
| Baseline Awareness Service | [openapi/v1/baseline-awareness.yml](openapi/v1/baseline-awareness.yml) |
| Bootstrap Service | [openapi/v1/bootstrap.yml](openapi/v1/bootstrap.yml) |
| DNS API | [openapi/v1/dns.yml](openapi/v1/dns.yml) |
| Function Caller Service | [openapi/v1/function-caller.yml](openapi/v1/function-caller.yml) |
| Gateway Service | [openapi/v1/gateway.yml](openapi/v1/gateway.yml) |
| LLM Gateway Plugin | [openapi/v2/llm-gateway.yml](openapi/v2/llm-gateway.yml) |
| OpenAPI Curator Service | [openapi/v1/openapi-curator.yml](openapi/v1/openapi-curator.yml) |
| Persistence Service | [openapi/v1/persist.yml](openapi/v1/persist.yml) |
| Planner Service | [openapi/v1/planner.yml](openapi/v1/planner.yml) |
| Planner Service (legacy) | [openapi/v0/planner.yml](openapi/v0/planner.yml) |
| Semantic Browser & Dissector API | [openapi/v1/semantic-browser.yml](openapi/v1/semantic-browser.yml) |
| Tools Factory Service | [openapi/v1/tools-factory.yml](openapi/v1/tools-factory.yml) |
| Tool Server | [openapi/v1/tool-server.yml](openapi/v1/tool-server.yml) |

## Gateway Plugins

| Plugin | OpenAPI Spec |
| --- | --- |
| Auth Gateway Plugin | [openapi/v1/auth-gateway.yml](openapi/v1/auth-gateway.yml) |
| Budget Breaker Gateway Plugin | [openapi/v1/budget-breaker-gateway.yml](openapi/v1/budget-breaker-gateway.yml) |
| Destructive Guardian Gateway Plugin | [openapi/v1/destructive-guardian-gateway.yml](openapi/v1/destructive-guardian-gateway.yml) |
| Payload Inspection Gateway Plugin | [openapi/v1/payload-inspection-gateway.yml](openapi/v1/payload-inspection-gateway.yml) |
| Rate Limiter Gateway Plugin | [openapi/v1/rate-limiter-gateway.yml](openapi/v1/rate-limiter-gateway.yml) |
| Role Health Check Gateway Plugin | [openapi/v1/role-health-check-gateway.yml](openapi/v1/role-health-check-gateway.yml) |
| Security Sentinel Gateway Plugin | [openapi/v1/security-sentinel-gateway.yml](openapi/v1/security-sentinel-gateway.yml) |

## Utilities and CLIs without OpenAPI Coverage

| Tool/CLI | Rationale |
| --- | --- |
| ClientgenService | Generates client code; exposes no HTTP API. |
| Flexctl | Internal command-line utility; no network surface. |
| OpenAPICuratorCLI | CLI wrapper around the curator service; spec covers the service instead. |
| PublishingFrontendCLI | Local publishing helper; not a network service. |
| SSEClient | Example client for Server-Sent Events; no endpoints to document. |

Keep this index current as the project evolves.
