import XCTest
import Foundation
@testable import SecuritySentinelGatewayPluginModule
import FountainRuntime

final class SecuritySentinelGatewayPluginTests: XCTestCase {
    @MainActor
    func testDenyDecision() async throws {
        let plugin = SecuritySentinelGatewayPlugin()
        let body = ConsultRequest(summary: "delete files", context: "u")
        let data = try JSONEncoder().encode(body)
        let request = HTTPRequest(method: "POST", path: "/sentinel/consult", body: data)
        let resp = try await plugin.router.route(request)
        let decision = try JSONDecoder().decode(SentinelDecision.self, from: resp!.body)
        XCTAssertEqual(decision.decision, .deny)
        XCTAssertEqual(decision.source, .fallback_rules)
    }

    @MainActor
    func testAllowDecision() async throws {
        let plugin = SecuritySentinelGatewayPlugin()
        let body = ConsultRequest(summary: "safe", context: "u")
        let data = try JSONEncoder().encode(body)
        let request = HTTPRequest(method: "POST", path: "/sentinel/consult", body: data)
        let resp = try await plugin.router.route(request)
        let decision = try JSONDecoder().decode(SentinelDecision.self, from: resp!.body)
        XCTAssertEqual(decision.decision, .allow)
        XCTAssertEqual(decision.source, .fallback_rules)
    }

    @MainActor
    func testEscalateDecision() async throws {
        let plugin = SecuritySentinelGatewayPlugin()
        let body = ConsultRequest(summary: "please escalate", context: "u")
        let data = try JSONEncoder().encode(body)
        let request = HTTPRequest(method: "POST", path: "/sentinel/consult", body: data)
        let resp = try await plugin.router.route(request)
        let decision = try JSONDecoder().decode(SentinelDecision.self, from: resp!.body)
        XCTAssertEqual(decision.decision, .escalate)
        XCTAssertEqual(decision.source, .fallback_rules)
    }

    @MainActor
    func testConsultMalformedBodyReturns400() async throws {
        let plugin = SecuritySentinelGatewayPlugin()
        let request = HTTPRequest(method: "POST", path: "/sentinel/consult", body: Data())
        let resp = try await plugin.router.route(request)
        XCTAssertEqual(resp?.status, 400)
    }

    @MainActor
    func testConsultInvalidSummaryReturns400() async throws {
        let plugin = SecuritySentinelGatewayPlugin()
        let body = ConsultRequest(summary: "", context: "ctx")
        let data = try JSONEncoder().encode(body)
        let request = HTTPRequest(method: "POST", path: "/sentinel/consult", body: data)
        let resp = try await plugin.router.route(request)
        XCTAssertEqual(resp?.status, 400)
    }

    @MainActor
    func testUnknownRouteReturnsNil() async throws {
        let plugin = SecuritySentinelGatewayPlugin()
        let request = HTTPRequest(method: "GET", path: "/unknown", body: Data())
        let resp = try await plugin.router.route(request)
        XCTAssertNil(resp)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
