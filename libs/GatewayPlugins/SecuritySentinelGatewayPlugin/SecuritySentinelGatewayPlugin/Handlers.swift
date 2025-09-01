import Foundation
import FountainRuntime

/// Actor housing Security Sentinel handlers.
public actor Handlers {
    public init() {}

    /// Consults the security sentinel and returns a detailed decision.
    public func sentinelConsult(_ request: HTTPRequest, body: ConsultRequest) async throws -> HTTPResponse {
        let client = SentinelClientFactory.make()
        let decision = try await client.consult(summary: body.summary, context: ["context": body.context])
        AuditLogger.logConsult(inputSummary: body.summary, decision: decision)
        let respBody = try JSONEncoder().encode(decision)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: respBody)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
