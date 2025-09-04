import XCTest
import FountainRuntime
@testable import RoleHealthCheckGatewayPlugin

final class RoleHealthCheckGatewayPluginTests: XCTestCase {
    func testReflectReturnsReflectedRoleInfo() async throws {
        let router = Router()
        let body = try JSONEncoder().encode(RoleHealthCheckRequest(corpusId: "c", roleName: "r"))
        let request = HTTPRequest(method: "POST", path: "/role-health-check/reflect", body: body)
        let response = try await router.route(request)
        let info = try JSONDecoder().decode(RoleInfo.self, from: response?.body ?? Data())
        XCTAssertEqual(info.prompt, "reflected")
    }

    func testPromoteReturnsPromotedRoleInfo() async throws {
        let router = Router()
        let body = try JSONEncoder().encode(RoleHealthCheckRequest(corpusId: "c", roleName: "r"))
        let request = HTTPRequest(method: "POST", path: "/role-health-check/promote", body: body)
        let response = try await router.route(request)
        let info = try JSONDecoder().decode(RoleInfo.self, from: response?.body ?? Data())
        XCTAssertEqual(info.prompt, "promoted")
    }

    func testMissingBodyReturns422() async throws {
        let router = Router()
        let request = HTTPRequest(method: "POST", path: "/role-health-check/reflect")
        let response = try await router.route(request)
        XCTAssertEqual(response?.status, 422)
    }

    func testUnknownPathReturnsNil() async throws {
        let router = Router()
        let request = HTTPRequest(method: "POST", path: "/unknown")
        let response = try await router.route(request)
        XCTAssertNil(response)
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
