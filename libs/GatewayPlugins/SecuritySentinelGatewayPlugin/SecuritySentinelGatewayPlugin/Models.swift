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

/// Response returned from the Security Sentinel consult endpoint.
public struct ConsultResponse: Codable, Sendable {
    /// Final decision such as allow, deny, or escalate.
    public let decision: String
    /// Human readable explanation for the decision.
    public let reason: String
    /// Model’s confidence score for the decision.
    public let confidence: Double
    /// Identifier of the model that produced the decision.
    public let model: String
    /// Identifier for tracking the consult request.
    public let requestID: String
    /// Latency in milliseconds for generating the response.
    public let latencyMS: Int
    /// Source system that produced the decision.
    public let source: String
    /// Timestamp when the decision was produced.
    public let timestamp: Date

    public init(decision: String, reason: String, confidence: Double, model: String, requestID: String, latencyMS: Int, source: String, timestamp: Date) {
        self.decision = decision
        self.reason = reason
        self.confidence = confidence
        self.model = model
        self.requestID = requestID
        self.latencyMS = latencyMS
        self.source = source
        self.timestamp = timestamp
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🖚️ All rights reserved.
