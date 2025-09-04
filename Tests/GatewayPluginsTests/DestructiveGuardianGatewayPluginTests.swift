import XCTest
import Foundation
@testable import DestructiveGuardianGatewayPlugin
import FountainRuntime

final class DestructiveGuardianGatewayPluginTests: XCTestCase {
    private func makeHandlers(logURL: URL, tokens: [String] = []) -> Handlers {
        Handlers(sensitivePaths: ["/secret"], privilegedTokens: Set(tokens), auditURL: logURL)
    }

    func testProtectedPathDeniedWithoutApprovalOrToken() async throws {
        let logURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let handlers = makeHandlers(logURL: logURL)
        let payload = GuardianEvaluateRequest(method: "DELETE", path: "/secret", manualApproval: false, serviceToken: nil)
        let request = HTTPRequest(method: "POST", path: "/guardian/evaluate", body: try JSONEncoder().encode(payload))
        let response = try await handlers.guardianEvaluate(request, body: payload)
        let decision = try JSONDecoder().decode(GuardianEvaluateResponse.self, from: response.body)
        XCTAssertEqual(decision.decision, "deny")
        let log = try String(contentsOf: logURL, encoding: .utf8)
        XCTAssertTrue(log.contains("deny [missing]"))
    }

    func testProtectedPathAllowedWithManualApproval() async throws {
        let logURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let handlers = makeHandlers(logURL: logURL)
        let payload = GuardianEvaluateRequest(method: "PUT", path: "/secret", manualApproval: true, serviceToken: nil)
        let request = HTTPRequest(method: "POST", path: "/guardian/evaluate", body: try JSONEncoder().encode(payload))
        let response = try await handlers.guardianEvaluate(request, body: payload)
        let decision = try JSONDecoder().decode(GuardianEvaluateResponse.self, from: response.body)
        XCTAssertEqual(decision.decision, "allow")
        let log = try String(contentsOf: logURL, encoding: .utf8)
        XCTAssertTrue(log.contains("allow [manual]"))
    }

    func testProtectedPathAllowedWithServiceToken() async throws {
        let logURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let handlers = makeHandlers(logURL: logURL, tokens: ["abc"])
        let payload = GuardianEvaluateRequest(method: "PATCH", path: "/secret", manualApproval: false, serviceToken: "abc")
        let request = HTTPRequest(method: "POST", path: "/guardian/evaluate", body: try JSONEncoder().encode(payload))
        let response = try await handlers.guardianEvaluate(request, body: payload)
        let decision = try JSONDecoder().decode(GuardianEvaluateResponse.self, from: response.body)
        XCTAssertEqual(decision.decision, "allow")
        let log = try String(contentsOf: logURL, encoding: .utf8)
        XCTAssertTrue(log.contains("allow [token]"))
    }

    func testUnprotectedPathAllowedWithoutLoggingErrors() async throws {
        let logURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let handlers = makeHandlers(logURL: logURL)
        let payload = GuardianEvaluateRequest(method: "GET", path: "/public", manualApproval: false, serviceToken: nil)
        let request = HTTPRequest(method: "POST", path: "/guardian/evaluate", body: try JSONEncoder().encode(payload))
        let response = try await handlers.guardianEvaluate(request, body: payload)
        let decision = try JSONDecoder().decode(GuardianEvaluateResponse.self, from: response.body)
        XCTAssertEqual(decision.decision, "allow")
        let log = try String(contentsOf: logURL, encoding: .utf8)
        XCTAssertTrue(log.contains("allow [unprotected]"))
    }

    func testRouterRoutesEvaluateAndUnknownPaths() async throws {
        let logURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let handlers = makeHandlers(logURL: logURL)
        let router = Router(handlers: handlers)

        let payload = GuardianEvaluateRequest(method: "DELETE", path: "/secret", manualApproval: false, serviceToken: nil)
        let request = HTTPRequest(method: "POST", path: "/guardian/evaluate", body: try JSONEncoder().encode(payload))
        let response = try await router.route(request)
        XCTAssertNotNil(response)

        let unknown = HTTPRequest(method: "GET", path: "/unknown")
        let missing = try await router.route(unknown)
        XCTAssertNil(missing)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
