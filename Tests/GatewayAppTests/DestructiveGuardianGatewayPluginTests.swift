import XCTest
import Foundation
@testable import DestructiveGuardianGatewayPlugin
import FountainRuntime
import gateway_server

final class DestructiveGuardianGatewayPluginTests: XCTestCase {
    private func makePlugin(logURL: URL, tokens: [String] = []) -> DestructiveGuardianGatewayPlugin {
        DestructiveGuardianGatewayPlugin(sensitivePaths: ["/secret"], privilegedTokens: tokens, auditURL: logURL)
    }

    @MainActor
    func testDeniesWithoutApproval() async throws {
        let logURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let plugin = makePlugin(logURL: logURL, tokens: ["t1"])
        let eval = GuardianEvaluateRequest(method: "DELETE", path: "/secret", manualApproval: false, serviceToken: nil)
        let body = try JSONEncoder().encode(eval)
        let request = HTTPRequest(method: "POST", path: "/guardian/evaluate", body: body)
        guard let resp = try await plugin.router.route(request) else {
            return XCTFail("no response")
        }
        let decision = try JSONDecoder().decode(GuardianEvaluateResponse.self, from: resp.body)
        XCTAssertEqual(decision.decision, "deny")
        let log = try String(contentsOf: logURL, encoding: .utf8)
        XCTAssertTrue(log.contains("deny [missing]"))
        let before = await GatewayRequestMetrics.shared.snapshot()
        await GatewayRequestMetrics.shared.record(method: request.method, status: resp.status)
        let after = await GatewayRequestMetrics.shared.snapshot()
        let key = "gateway_responses_status_200_total"
        XCTAssertEqual((after[key] ?? 0) - (before[key] ?? 0), 1)
    }

    @MainActor
    func testAllowsWithManualApproval() async throws {
        let logURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let plugin = makePlugin(logURL: logURL)
        let eval = GuardianEvaluateRequest(method: "PUT", path: "/secret", manualApproval: true, serviceToken: nil)
        let body = try JSONEncoder().encode(eval)
        let request = HTTPRequest(method: "POST", path: "/guardian/evaluate", body: body)
        guard let resp = try await plugin.router.route(request) else {
            return XCTFail("no response")
        }
        let decision = try JSONDecoder().decode(GuardianEvaluateResponse.self, from: resp.body)
        XCTAssertEqual(decision.decision, "allow")
        let log = try String(contentsOf: logURL, encoding: .utf8)
        XCTAssertTrue(log.contains("allow [manual]"))
        let before = await GatewayRequestMetrics.shared.snapshot()
        await GatewayRequestMetrics.shared.record(method: request.method, status: resp.status)
        let after = await GatewayRequestMetrics.shared.snapshot()
        let key = "gateway_responses_status_200_total"
        XCTAssertEqual((after[key] ?? 0) - (before[key] ?? 0), 1)
    }

    @MainActor
    func testAllowsWithServiceToken() async throws {
        let logURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let plugin = makePlugin(logURL: logURL, tokens: ["abc"])
        let eval = GuardianEvaluateRequest(method: "PATCH", path: "/secret", manualApproval: false, serviceToken: "abc")
        let body = try JSONEncoder().encode(eval)
        let request = HTTPRequest(method: "POST", path: "/guardian/evaluate", body: body)
        guard let resp = try await plugin.router.route(request) else {
            return XCTFail("no response")
        }
        let decision = try JSONDecoder().decode(GuardianEvaluateResponse.self, from: resp.body)
        XCTAssertEqual(decision.decision, "allow")
        let log = try String(contentsOf: logURL, encoding: .utf8)
        XCTAssertTrue(log.contains("allow [token]"))
        let before = await GatewayRequestMetrics.shared.snapshot()
        await GatewayRequestMetrics.shared.record(method: request.method, status: resp.status)
        let after = await GatewayRequestMetrics.shared.snapshot()
        let key = "gateway_responses_status_200_total"
        XCTAssertEqual((after[key] ?? 0) - (before[key] ?? 0), 1)
    }

    @MainActor
    func testAllowsUnprotectedPath() async throws {
        let logURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let plugin = makePlugin(logURL: logURL)
        let eval = GuardianEvaluateRequest(method: "DELETE", path: "/public", manualApproval: false, serviceToken: nil)
        let body = try JSONEncoder().encode(eval)
        let request = HTTPRequest(method: "POST", path: "/guardian/evaluate", body: body)
        guard let resp = try await plugin.router.route(request) else {
            return XCTFail("no response")
        }
        let decision = try JSONDecoder().decode(GuardianEvaluateResponse.self, from: resp.body)
        XCTAssertEqual(decision.decision, "allow")
        let log = try String(contentsOf: logURL, encoding: .utf8)
        XCTAssertTrue(log.contains("allow [unprotected]"))
        let before = await GatewayRequestMetrics.shared.snapshot()
        await GatewayRequestMetrics.shared.record(method: request.method, status: resp.status)
        let after = await GatewayRequestMetrics.shared.snapshot()
        let key = "gateway_responses_status_200_total"
        XCTAssertEqual((after[key] ?? 0) - (before[key] ?? 0), 1)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
