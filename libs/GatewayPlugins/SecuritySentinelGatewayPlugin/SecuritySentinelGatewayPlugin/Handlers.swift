import Foundation
import FountainRuntime

/// Actor housing Security Sentinel handlers.
public actor Handlers {
    private let client: SecuritySentinelClient

    public init(client: SecuritySentinelClient = SentinelClientFactory.make()) {
        self.client = client
    }

    /// Consults the security sentinel and returns a detailed decision.
    public func sentinelConsult(_ request: HTTPRequest, body: ConsultRequest) async throws -> HTTPResponse {
        let decision = try await client.consult(summary: body.summary, context: ["context": body.context])
        let respBody = try JSONEncoder().encode(decision)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: respBody)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
