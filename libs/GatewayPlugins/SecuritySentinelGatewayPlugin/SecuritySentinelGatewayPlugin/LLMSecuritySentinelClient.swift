import Foundation
import AsyncHTTPClient
import NIOCore

/// Failure mode behaviour when the LLM call fails.
enum FailMode: String {
    case allow, deny, fallback
}

/// Client that consults an external LLM backed Security Sentinel service.
final class LLMSecuritySentinelClient: SecuritySentinelClient {
    private let http: HTTPClient
    private let url: URL
    private let apiKey: String
    private let timeoutMS: Int
    private let retries: Int
    private let model: String?
    private let failMode: FailMode
    private let breaker: CircuitBreaker
    private let ownsHTTPClient: Bool

    init(http: HTTPClient? = nil) {
        guard let urlString = SentinelEnv.url, let url = URL(string: urlString), let apiKey = SentinelEnv.apiKey else {
            fatalError("SEC_SENTINEL_URL and SEC_SENTINEL_API_KEY must be set")
        }
        if let http = http {
            self.http = http
            self.ownsHTTPClient = false
        } else {
            self.http = HTTPClient(eventLoopGroupProvider: .singleton)
            self.ownsHTTPClient = true
        }
        self.url = url
        self.apiKey = apiKey
        self.timeoutMS = SentinelEnv.timeoutMS
        self.retries = SentinelEnv.retries
        self.model = SentinelEnv.model
        self.failMode = FailMode(rawValue: SentinelEnv.failMode) ?? .fallback
        self.breaker = CircuitBreaker()
    }

    deinit {
        if ownsHTTPClient {
            try? http.syncShutdown()
        }
    }

    private struct Payload: Codable {
        let summary: String
        let context: [String: String]?
        let model: String?
    }

    private struct LLMResponse: Codable {
        let decision: String
        let reason: String
        let confidence: Double?
        let model: String?
        let requestID: String?
    }

    func consult(summary: String, context: [String: (any Codable & Sendable)]?) async throws -> SentinelDecision {
        guard await breaker.allow() else {
            return try await applyFailMode(reason: "circuit open", summary: summary, context: context)
        }
        let payload = Payload(summary: summary, context: nil, model: model)
        let body = try JSONEncoder().encode(payload)
        var request = HTTPClientRequest(url: url.absoluteString)
        request.method = .POST
        request.headers.add(name: "Content-Type", value: "application/json")
        request.headers.add(name: "Authorization", value: "Bearer \(apiKey)")
        request.body = .bytes(body)

        var attempt = 0
        let start = Date()
        while true {
            attempt += 1
            do {
                let response = try await http.execute(request, timeout: .milliseconds(Int64(timeoutMS)))
                if response.status.code >= 500 {
                    throw NSError(domain: "llm", code: Int(response.status.code))
                }
                guard response.status.code < 400 else {
                    return try await applyFailMode(reason: "LLM \(response.status.code)", summary: summary, context: context)
                }
                let buffer = try await response.body.collect(upTo: 1_048_576)
                let data = Data(buffer.readableBytesView)
                let decoded = try JSONDecoder().decode(LLMResponse.self, from: data)
                let latency = Int(Date().timeIntervalSince(start) * 1000)
                let decision = SentinelDecision(
                    decision: SentinelVerdict(rawValue: decoded.decision) ?? .deny,
                    reason: decoded.reason,
                    confidence: decoded.confidence,
                    model: decoded.model,
                    requestID: decoded.requestID ?? UUID().uuidString,
                    latencyMS: latency,
                    source: .llm,
                    timestamp: ISO8601DateFormatter().string(from: Date())
                )
                await breaker.recordSuccess()
                return decision
            } catch {
                if attempt <= retries {
                    let backoff = UInt64(pow(2.0, Double(attempt - 1))) * 100_000_000
                    try await Task.sleep(nanoseconds: backoff)
                    continue
                } else {
                    await breaker.recordFailure()
                    return try await applyFailMode(reason: "LLM unavailable", summary: summary, context: context)
                }
            }
        }
    }

    private func applyFailMode(reason: String, summary: String, context: [String: (any Codable & Sendable)]?) async throws -> SentinelDecision {
        let ts = ISO8601DateFormatter().string(from: Date())
        switch failMode {
        case .allow:
            return SentinelDecision(
                decision: .allow,
                reason: reason,
                confidence: nil,
                model: nil,
                requestID: UUID().uuidString,
                latencyMS: 0,
                source: .llm,
                timestamp: ts
            )
        case .deny:
            return SentinelDecision(
                decision: .deny,
                reason: reason,
                confidence: nil,
                model: nil,
                requestID: UUID().uuidString,
                latencyMS: 0,
                source: .llm,
                timestamp: ts
            )
        case .fallback:
            let fallback = RuleBasedSecuritySentinelClient()
            return try await fallback.consult(summary: summary, context: context)
        }
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
