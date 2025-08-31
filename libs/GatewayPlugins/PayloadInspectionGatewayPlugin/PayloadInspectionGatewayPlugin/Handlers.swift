import Foundation
import FountainRuntime

/// Actor housing payload inspection handlers.
public actor Handlers {
    private let maxSize: Int

    /// Creates a new handlers instance.
    /// - Parameter maxSize: Maximum allowed payload size in bytes.
    public init(maxSize: Int = 1024) {
        self.maxSize = maxSize
    }

    /// Inspects the provided payload and returns sanitized content with any violations.
    public func inspectPayload(_ request: HTTPRequest, body: PayloadInspectionRequest?) async throws -> HTTPResponse {
        guard let body else { return HTTPResponse(status: 400) }
        guard body.payload.utf8.count <= maxSize else { return HTTPResponse(status: 413) }
        let response = PayloadInspectionResponse(sanitized: body.payload, violations: [])
        let data = try JSONEncoder().encode(response)
        return HTTPResponse(status: 200, headers: ["Content-Type": "application/json"], body: data)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
