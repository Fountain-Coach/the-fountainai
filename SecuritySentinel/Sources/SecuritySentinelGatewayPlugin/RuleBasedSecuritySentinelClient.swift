import Foundation

/// Simple keyword based sentinel client used as a fallback.
final class RuleBasedSecuritySentinelClient: SecuritySentinelClient {
    func consult(summary: String, context: [String: (any Codable & Sendable)]?) async throws -> SentinelDecision {
        let text = summary.lowercased()
        let verdict: SentinelVerdict
        let reason: String
        if text.contains("escalate") {
            verdict = .escalate
            reason = "escalation keyword found"
        } else if text.contains("delete") || text.contains("deny") || text.contains("danger") {
            verdict = .deny
            reason = "dangerous keyword found"
        } else {
            verdict = .allow
            reason = "no dangerous keywords"
        }
        let ts = ISO8601DateFormatter().string(from: Date())
        return SentinelDecision(
            decision: verdict,
            reason: reason,
            confidence: nil,
            model: nil,
            requestID: UUID().uuidString,
            latencyMS: 1,
            source: .fallback_rules,
            timestamp: ts
        )
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
