import XCTest
import FountainRuntime
@testable import CuratorGatewayPlugin

final class CuratorGatewayPluginTests: XCTestCase {
    func testAllowedOperationPasses() async throws {
        let table = ["op.allowed": CuratorGatewayPlugin.Truth(visibility: "public", allowAsTool: true, reason: "ok")]
        let plugin = CuratorGatewayPlugin(fetcher: { table })
        let req = HTTPRequest(method: "GET", path: "/", headers: ["X-Operation-ID": "op.allowed"])
        let prepared = try await plugin.prepare(req)
        let resp = HTTPResponse(status: 200)
        let out = try await plugin.respond(resp, for: prepared)
        XCTAssertEqual(out.status, 200)
        XCTAssertEqual(out.headers["X-Curator-Evidence"], "ok")
    }

    func testBannedOperationBlocked() async throws {
        let table = ["op.allowed": CuratorGatewayPlugin.Truth(visibility: "public", allowAsTool: true, reason: "ok")]
        let plugin = CuratorGatewayPlugin(fetcher: { table })
        let req = HTTPRequest(method: "GET", path: "/", headers: ["X-Operation-ID": "op.blocked"])
        let prepared = try await plugin.prepare(req)
        let resp = HTTPResponse(status: 200)
        let out = try await plugin.respond(resp, for: prepared)
        XCTAssertEqual(out.status, 403)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
