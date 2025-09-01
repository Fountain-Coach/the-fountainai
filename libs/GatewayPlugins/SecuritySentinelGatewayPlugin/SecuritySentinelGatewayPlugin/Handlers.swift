import Foundation
import FountainRuntime

/// Actor housing Security Sentinel handlers.
public actor Handlers {
    public init() {}

    /// Consults the security sentinel and returns a detailed decision.
    public func sentinelConsult(_ request: HTTPRequest, body: ConsultRequest) async throws -> HTTPResponse {
        let summary = body.summary.lowercased()
        let decision: String
        let reason: String
        if summary.contains("escalate") {
            decision = "escalate"
            reason = "escalation keyword found"
        } else if summary.contains("delete") || summary.contains("deny") || summary.contains("danger") {
            decision = "deny"
            reason = "dangerous keyword found"
        } else {
            decision = "allow"
            reason = "no dangerous keywords"
        }
        let response = ConsultResponse(
            decision: decision,
            reason: reason,
            confidence: 0.5,
            model: "mock-model",
            requestID: UUID().uuidString,
            latencyMS: 1,
            source: "mock",
            timestamp: Date()
        )
        let respBody = try JSONEncoder().encode(response)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: respBody)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
