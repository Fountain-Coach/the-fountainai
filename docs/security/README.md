# FountainAi Security

This document outlines the current security posture of FountainAi and highlights controls that protect the gateway and related tooling.

## Threat Landscape
- **Unauthorized access or privilege escalation** – Management APIs for gateways, DNS and model servers could be abused if authentication or role checks fail.
- **Destructive memory or data operations** – Misconfigured or malicious requests may delete logs, caches or model weights.
- **Prompt injection or model misuse** – Crafted prompts could cause the LLM to leak secrets or execute harmful instructions.
- **Denial of service & resource exhaustion** – Continuous high‑volume calls can degrade availability.
- **Supply‑chain or deployment compromise** – Unsigned images or outdated libraries may allow code tampering.

## Current Controls
### Authentication & authorization
The authentication gateway plugin validates OAuth2/OIDC bearer tokens and enforces role‑based access on administrative routes, returning `401` or `403` when credentials or scopes are insufficient.

### Chain‑of‑thought logging
[`CoTLogger`](../../Sources/GatewayApp/CoTLogger.swift) captures reasoning when `include_cot` is set, sanitizes secrets, and persists them.

### Rate limiting
[`RateLimiterGatewayPlugin`](../../libs/GatewayPlugins/RateLimiterGatewayPlugin/RateLimiterGatewayPlugin/RateLimiterGatewayPlugin.swift) implements per‑client token buckets to throttle excessive requests and records allowance metrics.

### Pre‑deployment verification
[`scripts/predeploy.sh`](../../scripts/predeploy.sh) verifies container image signatures with Cosign, scans for high‑severity vulnerabilities via Grype, and generates an SBOM using Syft before release.

## Roadmap & Gaps
The following recommendations remain pending:
- Write‑once logs, periodic snapshots, and anomaly monitoring for destructive operations.
- Prompt/response validation and policy enforcement for LLM interactions.
- Load balancing, autoscaling, circuit breakers, and per‑user request budgets.
- Signed container images, dependency scanning, and sandboxed runtimes.

For a detailed risk analysis and mitigation plan, see the [risk evaluation](./risk-evaluation.md).

---
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
