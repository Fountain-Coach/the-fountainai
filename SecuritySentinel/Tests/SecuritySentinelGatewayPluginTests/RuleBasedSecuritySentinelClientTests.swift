import XCTest
@testable import SecuritySentinelGatewayPluginModule

final class RuleBasedSecuritySentinelClientTests: XCTestCase {
    func testEscalateKeywordProducesEscalateDecision() async throws {
        let client = RuleBasedSecuritySentinelClient()
        let decision = try await client.consult(summary: "please escalate", context: nil)
        XCTAssertEqual(decision.decision, .escalate)
        XCTAssertEqual(decision.source, .fallback_rules)
    }

    func testDangerousKeywordProducesDenyDecision() async throws {
        let client = RuleBasedSecuritySentinelClient()
        let decision = try await client.consult(summary: "danger", context: nil)
        XCTAssertEqual(decision.decision, .deny)
        XCTAssertEqual(decision.source, .fallback_rules)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
