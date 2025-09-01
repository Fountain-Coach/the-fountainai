import XCTest
import Foundation
@testable import SecuritySentinelGatewayPlugin
import FountainRuntime
import gateway_server

final class SecuritySentinelGatewayPluginTests: XCTestCase {
    @MainActor
    func testDenyDecisionAndMetrics() async throws {
        let plugin = SecuritySentinelGatewayPlugin()
        let body = ConsultRequest(summary: "delete files", context: "u")
        let data = try JSONEncoder().encode(body)
        let request = HTTPRequest(method: "POST", path: "/sentinel/consult", body: data)
        let resp = try await plugin.router.route(request)
        let decision = try JSONDecoder().decode(SentinelDecision.self, from: resp!.body)
        XCTAssertEqual(decision.decision, .deny)
        XCTAssertEqual(decision.source, .fallback_rules)
        let before = await GatewayRequestMetrics.shared.snapshot()
        await GatewayRequestMetrics.shared.record(method: request.method, status: resp!.status)
        let after = await GatewayRequestMetrics.shared.snapshot()
        let key = "gateway_responses_status_200_total"
        XCTAssertEqual((after[key] ?? 0) - (before[key] ?? 0), 1)
    }

    @MainActor
    func testAllowDecisionAndMetrics() async throws {
        let plugin = SecuritySentinelGatewayPlugin()
        let body = ConsultRequest(summary: "safe", context: "u")
        let data = try JSONEncoder().encode(body)
        let request = HTTPRequest(method: "POST", path: "/sentinel/consult", body: data)
        let resp = try await plugin.router.route(request)
        let decision = try JSONDecoder().decode(SentinelDecision.self, from: resp!.body)
        XCTAssertEqual(decision.decision, .allow)
        XCTAssertEqual(decision.source, .fallback_rules)
        let before = await GatewayRequestMetrics.shared.snapshot()
        await GatewayRequestMetrics.shared.record(method: request.method, status: resp!.status)
        let after = await GatewayRequestMetrics.shared.snapshot()
        let key = "gateway_responses_status_200_total"
        XCTAssertEqual((after[key] ?? 0) - (before[key] ?? 0), 1)
    }

    @MainActor
    func testEscalateDecisionAndMetrics() async throws {
        let plugin = SecuritySentinelGatewayPlugin()
        let body = ConsultRequest(summary: "please escalate", context: "u")
        let data = try JSONEncoder().encode(body)
        let request = HTTPRequest(method: "POST", path: "/sentinel/consult", body: data)
        let resp = try await plugin.router.route(request)
        let decision = try JSONDecoder().decode(SentinelDecision.self, from: resp!.body)
        XCTAssertEqual(decision.decision, .escalate)
        XCTAssertEqual(decision.source, .fallback_rules)
        let before = await GatewayRequestMetrics.shared.snapshot()
        await GatewayRequestMetrics.shared.record(method: request.method, status: resp!.status)
        let after = await GatewayRequestMetrics.shared.snapshot()
        let key = "gateway_responses_status_200_total"
        XCTAssertEqual((after[key] ?? 0) - (before[key] ?? 0), 1)
    }

    @MainActor
    func testConsultMalformedBodyReturns400AndMetrics() async throws {
        let plugin = SecuritySentinelGatewayPlugin()
        let request = HTTPRequest(method: "POST", path: "/sentinel/consult", body: Data())
        let resp = try await plugin.router.route(request)
        XCTAssertEqual(resp?.status, 400)
        let before = await GatewayRequestMetrics.shared.snapshot()
        await GatewayRequestMetrics.shared.record(method: request.method, status: resp!.status)
        let after = await GatewayRequestMetrics.shared.snapshot()
        let key = "gateway_responses_status_400_total"
        XCTAssertEqual((after[key] ?? 0) - (before[key] ?? 0), 1)
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
