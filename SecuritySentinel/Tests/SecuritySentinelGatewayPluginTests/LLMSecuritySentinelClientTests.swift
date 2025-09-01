import XCTest
import AsyncHTTPClient
@testable import SecuritySentinelGatewayPluginModule

final class LLMSecuritySentinelClientTests: XCTestCase {
    override func tearDown() {
        unsetenv("SEC_SENTINEL_URL")
        unsetenv("SEC_SENTINEL_API_KEY")
        unsetenv("SEC_SENTINEL_FAIL_MODE")
        unsetenv("SEC_SENTINEL_TIMEOUT_MS")
        unsetenv("SEC_SENTINEL_RETRIES")
        super.tearDown()
    }

    private func makeClient(failMode: String) -> (LLMSecuritySentinelClient, HTTPClient) {
        setenv("SEC_SENTINEL_URL", "http://127.0.0.1:9", 1)
        setenv("SEC_SENTINEL_API_KEY", "test", 1)
        setenv("SEC_SENTINEL_FAIL_MODE", failMode, 1)
        setenv("SEC_SENTINEL_TIMEOUT_MS", "10", 1)
        setenv("SEC_SENTINEL_RETRIES", "0", 1)
        let http = HTTPClient(eventLoopGroupProvider: .singleton)
        let client = LLMSecuritySentinelClient(http: http)
        return (client, http)
    }

    func testFailModeFallbackUsesRuleBasedDecision() async throws {
        let (client, http) = makeClient(failMode: "fallback")
        let decision = try await client.consult(summary: "danger", context: nil)
        XCTAssertEqual(decision.source, .fallback_rules)
        XCTAssertEqual(decision.decision, .deny)
        try await http.shutdown()
    }

    func testFailModeAllowReturnsLLMSourcedAllow() async throws {
        let (client, http) = makeClient(failMode: "allow")
        let decision = try await client.consult(summary: "danger", context: nil)
        XCTAssertEqual(decision.source, .llm)
        XCTAssertEqual(decision.decision, .allow)
        try await http.shutdown()
    }

    func testFailModeDenyReturnsLLMSourcedDeny() async throws {
        let (client, http) = makeClient(failMode: "deny")
        let decision = try await client.consult(summary: "safe", context: nil)
        XCTAssertEqual(decision.source, .llm)
        XCTAssertEqual(decision.decision, .deny)
        try await http.shutdown()
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
