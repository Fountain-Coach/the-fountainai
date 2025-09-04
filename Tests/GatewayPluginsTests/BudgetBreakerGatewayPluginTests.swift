import XCTest
import Foundation
@testable import BudgetBreakerGatewayPlugin
import FountainRuntime

private func makeBudgetCheckRequest(_ body: BudgetCheckRequest?) throws -> HTTPRequest {
    let data: Data
    if let body = body {
        data = try JSONEncoder().encode(body)
    } else {
        data = Data()
    }
    return HTTPRequest(method: "POST", path: "/budget/check", body: data)
}

private func makeBudgetHealthRequest() -> HTTPRequest {
    HTTPRequest(method: "POST", path: "/budget/health")
}

final class BudgetBreakerGatewayPluginTests: XCTestCase {
    @MainActor
    func testBudgetCheckSucceeds() async throws {
        let router = Router()
        let body = BudgetCheckRequest(routeId: "r1", clientId: "c1", amount: 1)
        let request = try makeBudgetCheckRequest(body)
        let response = try await router.route(request)
        XCTAssertEqual(response?.status, 200)
        let decoded = try JSONDecoder().decode(BudgetCheckResponse.self, from: response!.body)
        XCTAssertTrue(decoded.allowed)
        XCTAssertEqual(decoded.remaining, 0)
    }

    @MainActor
    func testBudgetCheckMissingBodyReturns400() async throws {
        let router = Router()
        let request = try makeBudgetCheckRequest(nil)
        let response = try await router.route(request)
        XCTAssertEqual(response?.status, 400)
    }

    @MainActor
    func testBudgetHealth() async throws {
        let router = Router()
        let request = makeBudgetHealthRequest()
        let response = try await router.route(request)
        XCTAssertEqual(response?.status, 200)
        let decoded = try JSONDecoder().decode(BudgetHealthResponse.self, from: response!.body)
        XCTAssertEqual(decoded.status, "ok")
    }
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

