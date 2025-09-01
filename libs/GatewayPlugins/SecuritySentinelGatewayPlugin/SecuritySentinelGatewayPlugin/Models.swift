import Foundation

/// Request model for consulting the Security Sentinel.
public struct ConsultRequest: Codable, Sendable {
    /// Summary of the action the user intends to perform.
    public let summary: String
    /// Additional context describing the request.
    public let context: String

    public init(summary: String, context: String) {
        self.summary = summary
        self.context = context
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🖚️ All rights reserved.
