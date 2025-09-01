# ROLE
You are Codex, a senior **Swift** backend engineer in the FountainAI stack. Your task is to **integrate the existing Security Sentinel gateway plugin with a real LLM-backed Security Sentinel service**, replacing the current keyword stub while preserving backward compatibility, auditability, and Swift-native conventions.

---

# OBJECTIVE
Replace the rule-based keyword checks in the `/sentinel/consult` gateway plugin with a production-ready **Swift** client that calls an **external Security Sentinel LLM service** and returns a normalized **allow | deny | escalate** decision with rationale and metadata. Keep the keyword path as a **configurable fallback**.

---

# CONTEXT (What exists today)
- Endpoint: `POST /sentinel/consult` receives a short natural-language summary of a potentially risky operation.
- Current behavior: simple keyword matching (`escalate`, `delete`, `deny`, `danger`) produces decisions.
- Docs mention:
  - A separate **Security Sentinel service** (LLM-based) consulted before high-risk actions.
  - A **Security Sentinel persona** that outputs `allow | deny | escalate`.
- Infra conventions:
  - **No hardcoded URLs/ports/secrets**; read from a root-level `.env` (already exported into process env by our runtime).
  - Swift-native stack (server + HTTP client + logging + tests).
  - Structured logging and auditable decisions.

---

# REQUIREMENTS & DELIVERABLES (Swift)

## 1) Public HTTP API (keep stable)
- Keep the existing **HTTP contract** for `POST /sentinel/consult` intact (route/path unchanged).
- Request JSON (unchanged shape if it already exists). If missing, implement:

  ```json
  {
    "summary": "string - concise description of the proposed action",
    "context": { "any": "optional metadata map" }
  }
  ```

* Response JSON (add metadata while keeping `decision` stable):

  ```json
  {
    "decision": "allow | deny | escalate",
    "reason": "string",
    "confidence": 0.0,
    "model": "string",
    "request_id": "uuid",
    "latency_ms": 123,
    "source": "llm | fallback_rules",
    "timestamp": "RFC3339"
  }
  ```

## 2) Swift Abstractions

Define a protocol and DTOs to decouple implementations:

```swift
// Domain/SentinelDecision.swift
public enum SentinelSource: String, Codable { case llm, fallback_rules }

public enum SentinelVerdict: String, Codable { case allow, deny, escalate }

public struct SentinelDecision: Codable, Sendable {
    public let decision: SentinelVerdict
    public let reason: String
    public let confidence: Double?
    public let model: String?
    public let requestID: String
    public let latencyMS: Int
    public let source: SentinelSource
    public let timestamp: String // RFC3339
}

// Domain/SecuritySentinelClient.swift
public protocol SecuritySentinelClient: Sendable {
    func consult(summary: String, context: [String: Codable]? ) async throws -> SentinelDecision
}
```

### Implementations

* **LLM client** (`LLMSecuritySentinelClient`):

  * Uses **AsyncHTTPClient** (preferred) or `URLSession` with Swift Concurrency.
  * Configurable via environment:

    * `SEC_SENTINEL_ENABLED=true|false` (default true)
    * `SEC_SENTINEL_URL`
    * `SEC_SENTINEL_API_KEY`
    * `SEC_SENTINEL_TIMEOUT_MS` (default 4000)
    * `SEC_SENTINEL_RETRIES` (default 1)
    * `SEC_SENTINEL_MODEL` (optional)
    * `SEC_SENTINEL_FAIL_MODE=fallback|allow|deny` (default `fallback`)
  * Request JSON (example):

    ```json
    {
      "persona": "security_sentinel",
      "summary": "...",
      "context": { ... },
      "expected_decisions": ["allow","deny","escalate"],
      "decision_schema_version": "1.0",
      "model": "optional"
    }
    ```
  * Parse strict response:

    ```json
    { "decision":"allow|deny|escalate","reason":"...","confidence":0.0,"model":"...","request_id":"uuid" }
    ```
  * Measure latency, fill `source = "llm"`.

* **Rule-based fallback** (`RuleBasedSecuritySentinelClient`):

  * Retain existing keyword checks.
  * Fill `source = "fallback_rules"`, `model = nil`, `confidence = nil`.

* **Factory / Resolver**:

  * Constructs the **LLM client** when `SEC_SENTINEL_ENABLED=true`.
  * On errors from the LLM client, apply `SEC_SENTINEL_FAIL_MODE`:

    * `fallback`: use RuleBased client.
    * `allow`: return `allow` with reason “LLM unavailable”.
    * `deny`: return `deny` with reason “LLM unavailable”.

## 3) Server Integration (Swift)

* If the gateway uses **Vapor**:

  * Add a route handler in `routes.swift` (or similar) that:

    1. Validates input (non-empty `summary`, max 1000 chars).
    2. Calls `SecuritySentinelClient.consult(...)`.
    3. Returns the `SentinelDecision` as JSON with `200`.
    4. On validation error, return `400`.
* If not using Vapor, adapt to the project’s HTTP server framework equivalently (maintain Swift Concurrency).

## 4) HTTP Client Robustness

* Implement retries with exponential backoff for **5xx/timeouts** (up to `SEC_SENTINEL_RETRIES`).
* Treat **4xx** from the LLM as hard-fail (apply fail mode).
* Timeouts per request using `AsyncHTTPClient` request options.
* Simple in-memory circuit breaker (time-based open/half-open) to short-circuit repeated failures for ~30s.

## 5) Logging, Auditing, Tracing (Swift)

* Use **swift-log** (e.g., `import Logging`).
* Emit structured logs (JSON if logger supports) with fields: `request_id`, `decision`, `source`, `latency_ms`, `model`, and **hash of `summary`** (SHA-256) instead of raw summary.
* Redact sensitive keys in `context` (e.g., `token`, `apikey`, `secret`) in logs.
* Optional: integrate **OpenTelemetry Swift** if present; create span `security_sentinel.consult` with attributes (decision, source, model, latency).

## 6) Configuration

Add to `README.md` and `.env.example`:

```
SEC_SENTINEL_ENABLED=true
SEC_SENTINEL_URL=https://llm-gateway/sentinel/consult
SEC_SENTINEL_API_KEY=changeme
SEC_SENTINEL_TIMEOUT_MS=4000
SEC_SENTINEL_RETRIES=1
SEC_SENTINEL_MODEL=
SEC_SENTINEL_FAIL_MODE=fallback   # fallback | allow | deny
```

Read via `ProcessInfo.processInfo.environment`.

## 7) Tests (Swift XCTest)

* **Unit tests**:

  * `RuleBasedSecuritySentinelClientTests` (all keyword permutations).
  * `LLMSecuritySentinelClientSuccessTests` (mock HTTP 200; each decision).
  * `LLMSecuritySentinelClient4xxFailModeTests` (apply allow/deny/fallback).
  * `LLMSecuritySentinelClient5xxRetryTests` (retries + backoff, then fail mode).
  * `SentinelClientFactoryTests` (env-driven selection + failover).
  * Input validation (empty/oversized summary → 400).
* **Integration-style tests** (spawning the server or routing layer):

  * When LLM healthy → `source == "llm"`.
  * When LLM down + `FAIL_MODE=fallback` → `source == "fallback_rules"`.
  * When `FAIL_MODE=allow|deny` → route returns respective decision.
* Use a lightweight in-process **Mock LLM Server** (NIO/Vapor) or stub `HTTPClient` with a custom `HTTPClientDelegate`.

## 8) Backward Compatibility & Migration

* Keep route path and `decision` field unchanged.
* Extra fields are additive and safe for older clients to ignore.
* Preserve rule-based behavior behind the failover path.

---

# ACCEPTANCE CRITERIA

1. `POST /sentinel/consult` uses **LLM client** when enabled and returns normalized decision + metadata.
2. On LLM errors:

   * `SEC_SENTINEL_FAIL_MODE=fallback` → uses rule-based client.
   * `SEC_SENTINEL_FAIL_MODE=allow` → returns `allow`.
   * `SEC_SENTINEL_FAIL_MODE=deny` → returns `deny`.
3. Structured audit logs include **hashed summary**, `request_id`, `source`, `decision`, `latency_ms`, `model`.
4. XCTest suite covers success, failure, retries, and all fail modes (aim ≥90% for new code).
5. No secrets/URLs hardcoded; everything via env.
6. README and `.env.example` updated with run/test instructions.

---

# SWIFTPM LAYOUT (suggested)

```
SecuritySentinelGateway/
  Package.swift
  Sources/
    App/
      Config/
        Env.swift
      Domain/
        SentinelDecision.swift
        SecuritySentinelClient.swift
      Clients/
        RuleBasedSecuritySentinelClient.swift
        LLMSecuritySentinelClient.swift
        SentinelClientFactory.swift
      Infra/
        AuditLogger.swift
        CircuitBreaker.swift
        Hashing.swift
      HTTP/
        Routes/SentinelRoutes.swift
        Models/ConsultRequest.swift
        Models/ConsultResponse.swift
    Run/
      main.swift
  Tests/
    AppTests/
      RuleBasedSecuritySentinelClientTests.swift
      LLMSecuritySentinelClientSuccessTests.swift
      LLMSecuritySentinelClient4xxFailModeTests.swift
      LLMSecuritySentinelClient5xxRetryTests.swift
      SentinelClientFactoryTests.swift
      SentinelRouteIntegrationTests.swift
```

---

# IMPLEMENTATION SKETCH (key snippets)

```swift
// Config/Env.swift
struct Env {
    static let enabled = (ProcessInfo.processInfo.environment["SEC_SENTINEL_ENABLED"] ?? "true").lowercased() != "false"
    static let url = ProcessInfo.processInfo.environment["SEC_SENTINEL_URL"]
    static let apiKey = ProcessInfo.processInfo.environment["SEC_SENTINEL_API_KEY"]
    static let timeoutMS = Int(ProcessInfo.processInfo.environment["SEC_SENTINEL_TIMEOUT_MS"] ?? "4000") ?? 4000
    static let retries = Int(ProcessInfo.processInfo.environment["SEC_SENTINEL_RETRIES"] ?? "1") ?? 1
    static let model = ProcessInfo.processInfo.environment["SEC_SENTINEL_MODEL"]
    static let failMode = ProcessInfo.processInfo.environment["SEC_SENTINEL_FAIL_MODE"] ?? "fallback" // allow|deny|fallback
}
```

```swift
// Clients/SentinelClientFactory.swift
enum FailMode { case allow, deny, fallback }

struct SentinelClientFactory {
    static func make(httpClient: HTTPClientProtocol = DefaultHTTPClient()) -> SecuritySentinelClient {
        guard Env.enabled, let _ = Env.url, let _ = Env.apiKey else {
            return RuleBasedSecuritySentinelClient()
        }
        return LLMSecuritySentinelClient(
            http: httpClient,
            failMode: FailMode(rawValue: Env.failMode) ?? .fallback
        )
    }
}
```

```swift
// Clients/LLMSecuritySentinelClient.swift (outline)
final class LLMSecuritySentinelClient: SecuritySentinelClient {
    private let http: HTTPClientProtocol
    private let failMode: FailMode
    private let breaker = CircuitBreaker(openInterval: .seconds(30))

    init(http: HTTPClientProtocol, failMode: FailMode) {
        self.http = http; self.failMode = failMode
    }

    func consult(summary: String, context: [String: Codable]?) async throws -> SentinelDecision {
        // breaker, timeout, retries, Authorization: Bearer <API KEY>, JSON payload
        // map response to SentinelDecision(decision, reason, confidence, model, requestID, latencyMS, source: .llm, timestamp)
        // on error: apply failMode semantics
    }
}
```

```swift
// Clients/RuleBasedSecuritySentinelClient.swift (outline)
final class RuleBasedSecuritySentinelClient: SecuritySentinelClient {
    func consult(summary: String, context: [String: Codable]?) async throws -> SentinelDecision {
        // keyword checks → allow/deny/escalate
        // source: .fallback_rules
    }
}
```

```swift
// HTTP/Routes/SentinelRoutes.swift (Vapor-style outline)
func routes(_ app: Application) throws {
    app.post("sentinel", "consult") { req async throws -> SentinelDecision in
        let body = try req.content.decode(ConsultRequest.self)
        try body.validate() // non-empty summary, <= 1000 chars
        let client = SentinelClientFactory.make()
        let decision = try await client.consult(summary: body.summary, context: body.context)
        AuditLogger.logConsult(inputSummary: body.summary, decision: decision)
        return decision
    }
}
```

---

# OUTPUT

1. Swift source files implementing the LLM client integration, factory failover, audit logging, and route wiring.
2. Updated `README.md` and `.env.example`.
3. Passing **XCTest** suite.
4. Commit message:

   ```
   feat(sentinel): Swift LLM integration with fallback, audit logging, fail modes; add tests & docs
   ```
