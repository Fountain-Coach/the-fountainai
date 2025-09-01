import XCTest
import Foundation
import FountainRuntime
@testable import SecuritySentinelGatewayPluginModule

final class RouterSourceIntegrationTests: XCTestCase {
    override func tearDown() {
        unsetenv("SEC_SENTINEL_URL")
        unsetenv("SEC_SENTINEL_API_KEY")
        unsetenv("SEC_SENTINEL_FAIL_MODE")
        unsetenv("SEC_SENTINEL_TIMEOUT_MS")
        unsetenv("SEC_SENTINEL_RETRIES")
        super.tearDown()
    }

    func testRouterUsesRuleBasedSourceWhenDisabled() async throws {
        let router = Router()
        let body = ConsultRequest(summary: "ok", context: "ctx")
        let data = try JSONEncoder().encode(body)
        let request = HTTPRequest(method: "POST", path: "/sentinel/consult", body: data)
        let resp = try await router.route(request)
        let decision = try JSONDecoder().decode(SentinelDecision.self, from: resp!.body)
        XCTAssertEqual(decision.source, .fallback_rules)
    }

    func testRouterUsesLLMSourceWhenAllowedFailMode() async throws {
        setenv("SEC_SENTINEL_URL", "http://127.0.0.1:9", 1)
        setenv("SEC_SENTINEL_API_KEY", "k", 1)
        setenv("SEC_SENTINEL_FAIL_MODE", "allow", 1)
        setenv("SEC_SENTINEL_TIMEOUT_MS", "10", 1)
        setenv("SEC_SENTINEL_RETRIES", "0", 1)
        let router = Router()
        let body = ConsultRequest(summary: "anything", context: "ctx")
        let data = try JSONEncoder().encode(body)
        let request = HTTPRequest(method: "POST", path: "/sentinel/consult", body: data)
        let resp = try await router.route(request)
        let decision = try JSONDecoder().decode(SentinelDecision.self, from: resp!.body)
        XCTAssertEqual(decision.source, .llm)
        XCTAssertEqual(decision.decision, .allow)
    }

    func testRouterFallsBackWhenLLMUnavailable() async throws {
        setenv("SEC_SENTINEL_URL", "http://127.0.0.1:9", 1)
        setenv("SEC_SENTINEL_API_KEY", "k", 1)
        setenv("SEC_SENTINEL_FAIL_MODE", "fallback", 1)
        setenv("SEC_SENTINEL_TIMEOUT_MS", "10", 1)
        setenv("SEC_SENTINEL_RETRIES", "0", 1)
        let router = Router()
        let body = ConsultRequest(summary: "danger", context: "ctx")
        let data = try JSONEncoder().encode(body)
        let request = HTTPRequest(method: "POST", path: "/sentinel/consult", body: data)
        let resp = try await router.route(request)
        let decision = try JSONDecoder().decode(SentinelDecision.self, from: resp!.body)
        XCTAssertEqual(decision.source, .fallback_rules)
        XCTAssertEqual(decision.decision, .deny)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
